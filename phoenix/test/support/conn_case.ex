defmodule LoginProxy.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  require Logger

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      import LoginProxy.Router.Helpers

      # The default endpoint for testing
      @endpoint LoginProxy.Endpoint
    end
  end

  setup tags do

    unless tags[:async] do
      case LoginProxy.Redis.command(~w(KEYS TEST::*)) do
        {:ok, []} -> Logger.debug "Nothing to clean in Redis" 
        {:ok, _} -> LoginProxy.Redis.command(["EVAL", "return redis.call('del', unpack(redis.call('keys', KEYS[1])))", "1", "TEST::*"])
        {:error, reason} -> Logger.error inspect(reason)
      end
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
