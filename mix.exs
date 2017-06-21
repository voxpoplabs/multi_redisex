defmodule MultiRedisex.Mixfile do
  use Mix.Project

  def project do
    [app: :multi_redisex,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end
  def application do
    [extra_applications: [:logger],
     mod: {MultiRedisex, []}]
  end

  defp deps do
    [
      {:poolboy, ">= 1.5.1"},
      {:exredis, ">= 0.2.2"},
    ]
  end
end
