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
    configurations = Application.get_env(:multi_redisex, :configurations) || []

    children =
      configurations
      |> Enum.map(fn(configuration) ->
        pool_options = [
          name: {:local, configuration[:pool_name]},
          worker_module: MultiRedisex.Worker,
          size: configuration[:pool_size] || 10,
          max_overflow: configuration[:pool_max_overflow] || 1
        ]

        :poolboy.child_spec(configuration[:pool_name], pool_options, configuration[:connection_options])
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