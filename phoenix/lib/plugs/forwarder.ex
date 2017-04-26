# Each forwarder differs only in the init options provided at compile time.
# See ApiForwarder and BrowserForwarder for examples of use.
defmodule LoginProxy.Forwarder do
  require Logger
  import Plug.Conn
  alias LoginProxy.Jwt

  def call(conn, opts) do
    # Get remote host and port
    config = Application.get_env(:login_proxy, :remote_app) |> Keyword.get(opts[:remote_app])

    method = 
    case conn.method do
      "GET" -> :get
      "POST" -> :post
      "PUT" -> :put
      "PATCH" -> :patch
      "DELETE" -> :delete
      method -> method
    end

    url =
    case conn.query_string do
      "" -> config[:url] <> conn.request_path
      query -> config[:url] <> conn.request_path <> "?" <> query
    end

    {:ok, body, conn} = read_body(conn)

    # Generate auth header with JWT containing logged in user
    auth_header = "Bearer " <> Jwt.create_token(conn.assigns.user)

    headers = for {key, value} <- conn.req_headers, into: [authentication: auth_header] do
      {String.to_atom(key), value}
    end

    Logger.debug "Forwarding request. method, url, headers, body: \n" <>
    inspect(method) <> "\n" <> inspect(url) <> "\n" <> inspect(headers) <> "\n" <>
    inspect(body) <> "\n\n"

    response =
    Application.get_env(:login_proxy, :http_request_module).request(method, url, [
      headers: headers,
      body: body
    ])

    {resp_body, resp_headers, resp_status} =
    case Map.get(response, :message) do
      nil -> {response.body, response.headers, response.status_code}
      msg -> Logger.error("LoginProxy Forwarder error sending to #{url}: " <> msg)
      {nil, %{hdrs: []}, 400}
    end

    conn = Enum.reduce(resp_headers.hdrs || [], conn, fn h, acc -> put_resp_header(acc, elem(h, 0), elem(h, 1)) end)
    conn
    |> send_resp(resp_status, resp_body || "")
    |> halt
  end
end
