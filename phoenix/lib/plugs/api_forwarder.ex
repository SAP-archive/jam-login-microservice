defmodule LoginProxy.ApiForwarder do
  alias LoginProxy.Forwarder

  def init(opts), do: opts

  def call(conn, opts) do
    Forwarder.call(conn, opts)
  end
end
