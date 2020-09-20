defmodule Esquew.Subscription do
  use GenServer

  @registry Esquew.Registry

  defmodule SubscriptionState do
    @enforce_keys [:topic, :subscription]
    defstruct topic: "", subscription: "", messages: []
  end

  ## api
  @spec start_link({String.t(), String.t()}) :: :ok
  def start_link({topic, subscription}) do
    GenServer.start_link(__MODULE__, {topic, subscription},
      name: String.to_atom(build_name(topic, subscription))
    )
  end

  @spec read(String.t(), String.t(), Integer) :: list({String.t(), String.t()})
  def read(topic, name, num \\ 1) do
    case lookup_subscription(topic, name) do
      {:ok, pid} ->
        {:ok, GenServer.call(pid, {:read, num})}

      resp ->
        resp
    end
  end

  @spec ack(String.t(), String.t(), reference()) :: :ok
  def ack(topic, name, ref) do
    case lookup_subscription(topic, name) do
      {:ok, pid} ->
        GenServer.cast(pid, {:ack, ref})

      resp ->
        resp
    end
  end

  @spec nack(String.t(), String.t(), reference()) :: :ok
  def nack(topic, name, ref) do
    case lookup_subscription(topic, name) do
      {:ok, pid} ->
        GenServer.cast(pid, {:nack, ref})

      resp ->
        resp
    end
  end

  ## private
  @spec lookup_subscription(String.t(), String.t()) :: {atom(), pid()}
  defp lookup_subscription(topic, subscription) do
    case Registry.match(@registry, topic, subscription) do
      [{pid, _}] ->
        {:ok, pid}

      _ ->
        {:error, "Subscription \"#{build_name(topic, subscription)}\" could not be found"}
    end
  end

  @spec build_name(String.t(), String.t()) :: String.t()
  defp build_name(topic, subscription),
    do: "sub-" <> topic <> "@" <> subscription

  @spec build_name_atom(String.t(), String.t()) :: atom()
  defp build_name_atom(topic, subscription),
    do: String.to_atom(build_name(topic, subscription))

  @spec remove_from_pool(String.t(), String.t(), String.t(), boolean(), boolean()) :: [:ok | nil]
  defp remove_from_pool(topic, subscription, ref, delay \\ false, send_again \\ false) do
    if delay do
      Process.sleep(20000)
    end

    subscription_full_name = build_name_atom(topic, subscription)

    case :ets.lookup(subscription_full_name, ref) do
      [{^ref, msg}] ->
        if :ets.delete(subscription_full_name, ref) do
          if send_again do
            {:ok, pid} = lookup_subscription(topic, subscription)
            GenServer.cast(pid, {:publish, msg})
          end
        end

      [] ->
        nil
    end
  end

  ## callbacks
  @impl true
  @spec init({String.t(), String.t()}) :: {:ok, SubscriptionState}
  def init({topic, subscription}) do
    :ets.new(build_name_atom(topic, subscription), [:named_table, :public, read_concurrency: true])

    Registry.register(@registry, topic, subscription)
    {:ok, %SubscriptionState{topic: topic, subscription: subscription}}
  end

  @impl true
  def handle_call({:read, count}, _from, state) do
    reply =
      Enum.take(state.messages, count)
      |> Enum.map(fn msg ->
        ref = :crypto.strong_rand_bytes(8) |> Base.encode64()
        out = {ref, msg}
        :ets.insert(build_name_atom(state.topic, state.subscription), out)
        Task.start(fn -> remove_from_pool(state.topic, state.subscription, ref, true, true) end)
        out
      end)

    {:reply, reply, Map.put(state, :messages, Enum.drop(state.messages, count))}
  end

  @impl true
  def handle_cast({:publish, msg}, state),
    do: {:noreply, Map.put(state, :messages, state.messages ++ [msg])}

  @impl true
  def handle_cast({:ack, ref}, state) do
    remove_from_pool(state.topic, state.subscription, ref)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:nack, ref}, state) do
    remove_from_pool(state.topic, state.subscription, ref, false, true)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
