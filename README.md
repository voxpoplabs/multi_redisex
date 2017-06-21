# MultiRedisex

Copied from https://github.com/oivoodoo/redis_poolex

## Installation

```elixir
def deps do
  [{:multi_redisex, git: "https://github.com/voxpoplabs/multi_redisex.git"}]
end
```

## Configuration

config :multi_redisex,
  configurations: [
    %{
      pool_name: :customer_redis_pool,
      connection_options: %{
        host: "127.0.0.1",
        port: 6379,
        password: "",
        db: 0,
        reconnect: :no_reconnect,
        max_queue: :infinity
      }
    }
  ]


## Usage

```
MultiRedisex.query(unquote(pool_name), ["GET", key])
```