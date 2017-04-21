defmodule LoginProxy.PageController do
  use LoginProxy.Web, :controller
  require LoginProxy.Records
  alias LoginProxy.Records
  require Logger

  def index(conn, _params) do
    render conn, "index.html"
  end
end
