defmodule LoginProxy.PageController do
  use LoginProxy.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
