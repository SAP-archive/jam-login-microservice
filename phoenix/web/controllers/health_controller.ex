defmodule LoginProxy.HealthController do
  use LoginProxy.Web, :controller
  require Logger

  def health(conn, _params) do
    info = try do
      case LoginProxy.Redis.command(["KEYS", "*"]) do
        {:ok, _} -> %{web: true, redis: true}
        {:error, reason} -> Logger.error "Redis error " <> inspect(reason)
      end
    rescue
      _ -> %{web: true, redis: false}
    end
    render(conn, "index.json", info: info)
  end

end
