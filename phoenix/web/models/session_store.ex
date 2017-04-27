defmodule LoginProxy.SessionStore do
  defstruct [
    :username, :email, :firstname, :lastname
  ]

  require Logger
  alias LoginProxy.Redis
  @redis_timeout "1800" # 30 minutes

  def save(bare_key, params) do
    key = prefix() <> bare_key
    value = Poison.encode!(%__MODULE__{
      username: params["username"],
      email: params["email"],
      firstname: params["firstname"],
      lastname: params["lastname"]
    }) <> "\n"
    Logger.debug "SessionStore: writing key,value: " <> inspect(key) <> ", " <> inspect(value)
    {:ok, "OK"} = Redis.command(["SET", key, value])
    refresh(key)
  end

  def load(bare_key) do
    key = prefix() <> bare_key
    case Redis.command(["GET", key]) do
      {:ok, value} ->
        refresh(key)
        try do
          Poison.decode!(value)
        rescue
          error -> Logger.error("SessionStore: Poison.decode! error: "
            <> inspect(error) <> " for key,value " <> inspect(key) <> ", " <> inspect(value))
          nil
        end
      {:error, reason} ->
        Logger.error("Session load failed: " <> reason)
        nil
    end
  end

  def refresh(key) do
    {result, _} = Redis.command(["EXPIRE", key, @redis_timeout])
    result
  end

  def delete(key) do
    {:ok, _} = Redis.command(["DEL", key])
    :ok
  end

  defp prefix() do
    Application.get_env(:login_proxy, :redis)[:key_prefix]
  end
end
