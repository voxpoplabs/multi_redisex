defmodule MultiRedisex.Worker do
  @moduledoc """
  Worker for getting connction to Redis and run queries via `Exredis`
  """
  require Logger

  import Exredis

  use GenServer

  @doc"""
  State is storing %{conn: conn} for reusing it because of wrapping it by redis pool
  `state` - default state is `%{conn: nil}`
  """
  def start_link(connection_options) do
    GenServer.start_link(__MODULE__, %{conn: nil, connection_options: connection_options}, [])
  end

  def init(state) do
    {:ok, state}
  end

  defmodule Connector do
    require Exredis
    require Logger

    @doc """
    Using config `redis_poolex` to connect to redis server via `Exredis`
    """
    def connect(connection_options) do
      host = connection_options[:host]
      port = connection_options[:port]
      password = connection_options[:password] || ""
      database = connection_options[:db] || 0
      reconnect = connection_options[:reconnect] || :no_reconnect

      {:ok, client} = Exredis.start_link(host, port, database, password, reconnect)

      Logger.debug "[Connector] connecting to redis server..."

      client
    end

    @doc """
    Checking process alive or not in case if we don't have connection we should
    connect to redis server.
    """
    def ensure_connection(conn, connection_options) do
      if Process.alive?(conn) do
        conn
      else
        Logger.debug "[Connector] redis connection is died, it will renew connection."
        connect(connection_options)
      end
    end
  end

  @doc false
  def handle_call(%{command: command, params: params}, _from, %{conn: nil, connection_options: connection_options}) do
    conn = Connector.connect(connection_options)
    case command do
      :query -> {:reply, q(conn, params), %{conn: conn, connection_options: connection_options}}
      :query_pipe -> {:reply, p(conn, params), %{conn: conn, connection_options: connection_options}}
      :eval -> {:reply, ev(conn, params), %{conn: conn, connection_options: connection_options}}
    end
  end

  @doc false
  def handle_call(%{command: command, params: params}, _from, %{conn: conn, connection_options: connection_options}) do
    conn = Connector.ensure_connection(conn, connection_options)
    case command do
      :query -> {:reply, q(conn, params), %{conn: conn, connection_options: connection_options}}
      :query_pipe -> {:reply, p(conn, params), %{conn: conn, connection_options: connection_options}}
      :eval -> {:reply, ev(conn, params), %{conn: conn, connection_options: connection_options}}
    end
  end

  @doc false
  def q(conn, params) do
    query(conn, params)
  end

  @doc false
  def p(conn, params) do
    query_pipe(
      conn,
      [["MULTI"]] ++ params ++ [["EXEC"]]
    )
  end

  def ev(conn, [script, arg_num, keys, args]) do
    Exredis.Api.eval(conn, script, arg_num, keys, args)
  end

end