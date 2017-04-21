defmodule LoginProxy.Redis do

  def command(c) do
    Redix.command(:"redix_#{random_index()}", c)
  end

  defp random_index do
    rem(System.unique_integer([:positive]), Application.get_env(:login_proxy, :redis)[:pool_size])
  end
end
