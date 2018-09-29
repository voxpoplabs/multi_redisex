defmodule MultiRedisex do
  @moduledoc ~S"""
  Application for running connection pool and redis connection inside.
  ## Example:
    ```elixir
    alias MultiRedisex, as: Redis
    Redis.query("pool_name", ["SET", "key1", "value1"]) => "OK"
    Redis.query("pool_name", ["GET", "key1"]) => "value1"
    Redis.query("pool_name", ["GET", "key2"]) => :undefined
    ```
  """

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(MultiRedisex.Supervisor, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MultiRedisex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def read(pool_name, args) do
    pool_name <> "_read"
    |> String.to_atom()
    |> MultiRedisex.Supervisor.q(args)
  end

  def read_pipe(pool_name, args) do
    pool_name <> "_read"
    |> String.to_atom()
    |> MultiRedisex.Supervisor.p(args)
  end

  def write(pool_name, args) do
    pool_name <> "_write"
    |> String.to_atom()
    |> MultiRedisex.Supervisor.q(args)
  end

   @doc ~S"""
  `eval` send eval command directly to Redis
  """
  def eval(pool_name, args) do
    pool_name <> "_write"
    |> String.to_atom()
    |> MultiRedisex.Supervisor.ev(args)
  end

  @doc ~S"""
  `query` sends commands directly to Redis
  """
  def query(pool_name,args) do
    pool_name <> "_read"
    |> String.to_atom()
    |> MultiRedisex.Supervisor.q(args)
  end

  @doc ~S"""
  `query_pipe` sends multiple commands as batch directly to Redis.
  """
  def query_pipe(pool_name, args) do
    pool_name <> "_write"
    |> String.to_atom()
    |> MultiRedisex.Supervisor.p(args)
  end
end