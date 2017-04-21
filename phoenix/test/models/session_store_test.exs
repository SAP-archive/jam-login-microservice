defmodule LoginProxy.SessionStore.Test do
  use ExUnit.Case

  alias LoginProxy.SessionStore

  setup do
    case LoginProxy.Redis.command(~w(KEYS TEST::*)) do
      {:ok, []} -> IO.puts "Nothing to clean in Redis" 
      {:ok, val} -> LoginProxy.Redis.command(["EVAL", "return redis.call('del', unpack(redis.call('keys', KEYS[1])))", "1", "TEST::*"])
      {:error, reason} -> IO.puts inspect(reason)
    end
    :ok
  end

  test "store session" do
    assert :ok == SessionStore.save("alpha",
      %{"email" => "alpha@bmail.com", "firstname" => "alpha", "lastname" => "tset"})
    assert %{"email" => "alpha@bmail.com", "firstname" => "alpha", "lastname" => "tset"} =
      SessionStore.load("alpha")
  end
end
