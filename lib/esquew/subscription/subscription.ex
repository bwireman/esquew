defmodule Esquew.Subscription do
  use GenServer

  @registry Esquew.Hub.Registry

  ## api
  def start_link({topic, subscription}) do
    GenServer.start_link(__MODULE__, {topic, subscription},
      name: String.to_atom(build_name(topic, subscription))
    )
  end

  def read(topic, name, num \\ 1) do
    [{pid, _}] = Registry.match(@registry, topic, name)
    GenServer.call(pid, {:read, num})
  end

  def ack(topic, name, ref) do
    [{pid, _}] = Registry.match(@registry, topic, name)
    GenServer.cast(pid, {:ack, ref})
  end

  def nack(topic, name, ref) do
    [{pid, _}] = Registry.match(@registry, topic, name)
    GenServer.cast(pid, {:nack, ref})
  end

  ## private
  defp build_name(topic, subscription),
    do: "sub-" <> topic <> "@" <> subscription

  defp build_name_atom(topic, subscription),
    do: String.to_atom(build_name(topic, subscription))

  defp remove_from_pool(topic, subscription, ref, delay \\ false, send_again \\ false) do
    if delay do
      Process.sleep(20000)
    end

    case :ets.lookup(build_name_atom(topic, subscription), ref) do

      [{ref, msg}] ->
        if :ets.delete(build_name_atom(topic, subscription), ref) do
          if send_again do
            [{pid, _}] = Registry.match(@registry, topic, subscription)
            GenServer.cast(pid, {:publish, msg})
          end
        end

      [] ->
        nil
    end
  end

  ## callbacks
  @impl true
  def init({topic, subscription}) do
    name = String.to_atom(build_name(topic, subscription))
    :ets.new(name, [:named_table, :public, read_concurrency: true])
    Registry.register(@registry, topic, subscription)
    {:ok, {topic, subscription, []}}
  end

  @impl true
  def handle_cast({:publish, msg}, {topic, subscription, messages}),
    do: {:noreply, {topic, subscription, messages ++ [msg]}}

  @impl true
  def handle_call({:read, count}, _from, {topic, subscription, messages}) do
    reply =
      Enum.take(messages, count)
      |> Enum.map(fn msg ->
        ref = make_ref()
        out = {ref, msg}
        :ets.insert(build_name_atom(topic, subscription), out)
        Task.start(fn -> remove_from_pool(topic, subscription, ref, true, true) end)
        out
      end)

    {:reply, reply, {topic, subscription, Enum.drop(messages, count)}}
  end

  @impl true
  def handle_cast({:ack, ref}, {topic, subscription, messages}) do
    remove_from_pool(topic, subscription, ref)
    {:noreply, {topic, subscription, messages}}
  end

  @impl true
  def handle_cast({:nack, ref}, {topic, subscription, messages}) do
    remove_from_pool(topic, subscription, ref, false, true)
    {:noreply, {topic, subscription, messages}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
