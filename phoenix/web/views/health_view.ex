defmodule LoginProxy.HealthView do
  use LoginProxy.Web, :view

  def render("index.json", %{info: info}) do
    info
  end
end
