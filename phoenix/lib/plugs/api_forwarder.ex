defmodule LoginProxy.ApiForwarder do
  alias LoginProxy.Forwarder

  def init(opts), do: opts

  def call(conn, _) do
    remote_url = Application.get_env(:login_proxy, :api_server_url)
    Forwarder.call(conn, remote_url: remote_url)
  end
end
