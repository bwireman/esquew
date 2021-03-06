defmodule Esquew.Hub.Supervisor do
  use Supervisor

  @moduledoc """
  Supervisor for the Hub and Registry
  """

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      %{
        id: Esquew.Hub,
        start: {Esquew.Hub, :start_link, [%{}]}
      },
      {Registry, keys: :duplicate, name: Esquew.Registry},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
