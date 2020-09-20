defmodule Esquew.Topic do

  @moduledoc """
  Module for managing topics
  """

  @registry Esquew.Registry

  def publish(topic, msg) do
    case Registry.lookup(@registry, topic) do
      [] ->
        :error

      _ ->
        Registry.dispatch(@registry, topic, fn entries ->
          for {pid, _} <- entries, do: GenServer.cast(pid, {:publish, msg})
        end)
    end
  end
end
