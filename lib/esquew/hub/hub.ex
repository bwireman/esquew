defmodule Esquew.Hub do
  use GenServer

  @moduledoc """
  Esquew Hub where topics and subscriptions can be created
  """

  ## boiler

  @name __MODULE__

  def start_link(%{}) do
    GenServer.start_link(@name, %{}, name: @name)
  end

  ## api

  def list do
    Enum.map(:ets.match_object(@name, :_), fn {topic, subs} ->
      %{name: topic, subscriptions: subs}
    end)
  end

  def add_topic(topic),
    do: GenServer.call(@name, {:add_topic, topic})

  def add_subscription(topic, subscription),
    do: GenServer.call(@name, {:add_subscription, topic, subscription})

  ## Private

  defp lookup(topic) do
    case :ets.lookup(@name, topic) do
      [{^topic, val}] -> {:ok, val}
      [] -> :error
    end
  end

  ## Callbacks

  @impl true
  def init(%{}) do
    :ets.new(@name, [:named_table, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:add_topic, topic}, _from, state) do
    val =
      case lookup(topic) do
        {:ok, subs} ->
          {topic, subs}

        :error ->
          :ets.insert(@name, {topic, []})
          {topic, []}
      end

    {:reply, {:ok, val}, state}
  end

  @impl true
  def handle_call({:add_subscription, topic, subscription}, _from, state) do
    case lookup(topic) do
      {:ok, subs} ->
        all_subs =
          case Enum.find(subs, nil, &(&1 === subscription)) do
            nil ->
              {:ok, _} =
                DynamicSupervisor.start_child(
                  Esquew.Subscription.Supervisor,
                  %{
                    id: subscription,
                    start: {Esquew.Subscription, :start_link, [{topic, subscription}]}
                  }
                )

              [subscription] ++ subs

            _ ->
              subs
          end

        new_val = {topic, all_subs}
        :ets.insert(@name, new_val)

        {:reply, {:ok, new_val}, state}

      :error ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
