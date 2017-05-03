defmodule Mix.Tasks.Data.Populate do
  use Mix.Task

  @doc """
  Provide test tuples to the api test runner

  Usage:
  mix data.populate
  """
  @shortdoc "Provide test tuples to the api test runner"
  def run(args) do
    File.cp!("test_tuples.json", "test/testcases/test_tuples.json")
  end

end
