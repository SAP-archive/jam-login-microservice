defmodule LoginProxy.ErrorViewTest do
  use LoginProxy.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(LoginProxy.ErrorView, "404.html", []) ==
           "Page not found"
  end

  test "render 500.html" do
    assert render_to_string(LoginProxy.ErrorView, "500.html", []) ==
           #"Internal server error"
           "Internal server error\n%{view_module: LoginProxy.ErrorView, view_template: &quot;500.html&quot;}"
  end

  test "render any other" do
    assert render_to_string(LoginProxy.ErrorView, "505.html", []) ==
           #"Internal server error"
           "Internal server error\n%{template_not_found: LoginProxy.ErrorView, view_module: LoginProxy.ErrorView, view_template: &quot;505.html&quot;}"
  end
end
