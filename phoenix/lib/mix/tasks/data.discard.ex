defmodule Mix.Tasks.Data.Discard do
  use Mix.Task

  @doc """
  Withdraw test tuples from api test runner

  Usage:
  mix data.discard
  """
  @shortdoc "Withdraw test tuples from api test runner"
  def run(args) do
    File.rm!("test/testcases/test_tuples.json")
  end

end
