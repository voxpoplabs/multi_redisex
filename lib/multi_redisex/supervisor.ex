defmodule MultiRedisex.Supervisor do
  require Logger

  @moduledoc """
  Redis connection pool supervisor to handle connections via pool and
  reduce the number of opened connections via GenServer.
  """
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children =
      Application.get_env(:multi_redisex, :configurations)
      |> Enum.flat_map(fn(configuration) ->
        write_pool_options = [
          name: {:local, "#{configuration[:pool_name]}_write" |> String.to_atom()},
          worker_module: MultiRedisex.Worker,
          size: configuration[:pool_size] || 10,
          max_overflow: configuration[:pool_max_overflow] || 1
        ]

        read_pool_options = [
          name: {:local, "#{configuration[:pool_name]}_read" |> String.to_atom()},
          worker_module: MultiRedisex.Worker,
          size: configuration[:pool_size] || 10,
          max_overflow: configuration[:pool_max_overflow] || 1
        ]

        [
          :poolboy.child_spec(
            "#{configuration[:pool_name]}_write" |> String.to_atom(), 
            write_pool_options, 
            Map.merge(configuration[:connection_options], %{ hosts: get_in(configuration, [:connection_hosts, :write])})
          ),
          :poolboy.child_spec(
            "#{configuration[:pool_name]}_read" |> String.to_atom(), 
            read_pool_options, 
            Map.merge(configuration[:connection_options], %{ hosts: get_in(configuration, [:connection_hosts, :read])})
          )
        ]
      end)

    supervise(children, strategy: :one_for_one)
  end

  @doc """
  Making query via connection pool using `%{command: command, params: params}` pattern.
  """
  def q(pool_name, args) do
    :poolboy.transaction(pool_name, fn(worker) ->
      GenServer.call(worker, %{command: :query, params: args})
    end, 5000)
  end

  def p(pool_name, args) do
    :poolboy.transaction(pool_name, fn(worker) ->
      GenServer.call(worker, %{command: :query_pipe, params: args})
    end, 5000)
  end

  def ev(pool_name, args) do
    :poolboy.transaction(pool_name, fn(worker) ->
      GenServer.call(worker, %{command: :eval, params: args})
    end, 5000)
  end
end