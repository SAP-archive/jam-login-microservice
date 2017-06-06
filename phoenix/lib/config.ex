defmodule LoginProxy.Config do
  defmodule RedisDocker do
    require Logger
    @behaviour DynamicConfig

    @doc """
    RedisDocker.get_config(nil) -> [host: "172.69.100.242", port: 6379]
    """
    def get_config(_) do
      redis_port = System.get_env("REDIS_PORT") || "tcp://localhost:6379"
      [host: URI.parse(redis_port).host, port: URI.parse(redis_port).port]
    end
  end

end
