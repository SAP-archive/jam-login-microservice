defmodule LoginProxy.HttpMock do
  use GenServer

  @moduledoc """
  A mock for HTTPotion.request() method.

  To use, start the GenServer using HttpMock.start() and
  set up the response for your test by calling HttpMock.set_response().
  
  Now, do the action that would internally invoke HttpMock.request().

  HttpMock will respond with whatever you set earlier.
  You can also verify what parameters HttpMock.request() was called with
  using HttpMock.get_request().

  Your internal code needs to switch from HTTPotion to HttpMock using
  configuration.
  """

  # Client
  def start() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def set_response(params) do
    GenServer.cast(__MODULE__, {:set_response, params})
  end

  def get_response() do
    GenServer.call(__MODULE__, :get_response)
  end

  def set_request(params) do
    GenServer.cast(__MODULE__, {:set_request, params})
  end

  def get_request() do
    GenServer.call(__MODULE__, :get_request)
  end

  # Server
  
  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_cast({:set_response, params}, state) do
    {:noreply, Keyword.put(state, :response, params)}
  end

  def handle_cast({:set_request, params}, state) do
    {:noreply, Keyword.put(state, :request, params)}
  end

  def handle_call(:get_response, _from, state) do
    {:reply, Keyword.get(state, :response), state}
  end

  def handle_call(:get_request, _from, state) do
    {:reply, Keyword.get(state, :request), state}
  end

  @doc """
  Mock HTTPotion.request()

  Returns whatever was set as the response.
  Also sets requested params so they can be read after the call.
  """
  def request(method, url, opts) do
    __MODULE__.set_request(%{
      method: method,
      url: url,
      headers: Keyword.get(opts, :headers),
      body: Keyword.get(opts, :body)
      }
    )
    __MODULE__.get_response()
  end
end
