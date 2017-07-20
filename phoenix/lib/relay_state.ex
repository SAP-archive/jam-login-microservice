defmodule LoginProxy.RelayState do
  @redis_timeout "300" # 5 minutes

  def relay_state_key(relay_state) do
    LoginProxy.Redis.prefix() <> "::RELAY::" <> relay_state
  end

  def save(relay_state, value) do
    key = relay_state_key(relay_state)
    with {:ok, "OK"} <- LoginProxy.Redis.command(["SET", key, value]),
          {:ok, _} <- LoginProxy.Redis.command(["EXPIRE", key, @redis_timeout])
    do
      :ok
    else
      _ -> :error
    end
  end

  def load(relay_state) do
    key = relay_state_key(relay_state)
    with {:ok, value} <- LoginProxy.Redis.command(["GET", key])
    do
      {:ok, value}
    else
      _ -> :not_found
    end
  end

  def delete(key) do
    LoginProxy.Redis.command(["DEL", key])
  end

end
