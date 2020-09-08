defmodule Esquew.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args),
      do: Supervisor.start_link(children(), strategy: :one_for_one)

  defp children do
    [
      {DynamicSupervisor, name: Esquew.Subscription.Supervisor, strategy: :one_for_one},
      Esquew.Hub.Supervisor
    ]
  end

end