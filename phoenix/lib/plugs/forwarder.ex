# Each forwarder differs only in the init options provided at compile time.
# See ApiForwarder and BrowserForwarder for examples of use.
defmodule LoginProxy.Forwarder do
  require Logger
  import Plug.Conn

  def call(conn, opts) do
    remote_url = opts[:remote_url]

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
      "" -> remote_url <> conn.request_path
      query -> remote_url <> conn.request_path <> "?" <> query
    end

    {body, conn} = read_full_body(conn)

    headers = for {key, value} <- conn.req_headers do
      {String.to_atom(key), value}
    end

    Logger.debug "Forwarding request. method, url, headers, body size: \n" <>
    inspect(method) <> "\n" <> inspect(url) <> "\n" <> inspect(headers) <> "\n" <>
    inspect(byte_size(body)) <> "\n\n"

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

  defp read_full_body(conn) do
    case read_body(conn) do
      {:ok, body, conn} ->
        {body, conn}
      {:more, partial_body, conn} ->
        {body, conn} = read_full_body(conn)
        {partial_body <> body, conn}
      {:error, reason} ->
        raise inspect(reason)
    end
  end

end
