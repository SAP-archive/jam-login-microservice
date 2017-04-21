defmodule LoginProxy do
  use Application
  import Supervisor.Spec

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(LoginProxy.Endpoint, []),
      # Start your own worker by calling: LoginProxy.Worker.start_link(arg1, arg2, arg3)
      # worker(LoginProxy.Worker, [arg1, arg2, arg3]),
      redix_workers(),
    ] |> List.flatten()

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LoginProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LoginProxy.Endpoint.config_change(changed, removed)
    :ok
  end

  defp redix_workers do
    config = Application.get_env(:login_proxy, :redis)
    for i <- 0..(config[:pool_size] -1) do
      worker(Redix, [config[:redix], [name: :"redix_#{i}"]], id: {Redix, i})
    end
  end
end
