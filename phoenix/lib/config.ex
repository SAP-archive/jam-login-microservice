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

  defmodule DownstreamDocker do
    require Logger
    @behaviour DynamicConfig

    @doc """
    DownstreamDocker.get_config(:api_service_url) -> "http://172.69.100.242:4000"
    """
    def get_config(env_var) do
      downstream_port = System.get_env(env_var)
      downstream_port =
      cond do
        !downstream_port && env_var == "KORA_APP_API_PORT" -> "tcp://localhost:4030"
        !downstream_port && env_var == "KORA_UI_PORT" -> "tcp://localhost:4050"
        true -> downstream_port
      end
      Regex.replace(~r/^tcp/, downstream_port, "http")
    end
  end    
end
