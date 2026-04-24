defmodule MiniDiscord.Salon do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{name: name, clients: [], historique: []},
      name: via(name))
  end

  def rejoindre(salon, pid), do: GenServer.call(via(salon), {:rejoindre, pid})
  def quitter(salon, pid),   do: GenServer.call(via(salon), {:quitter, pid})
  def broadcast(salon, msg), do: GenServer.cast(via(salon), {:broadcast, msg})
  def lister do
    Registry.select(MiniDiscord.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def init(state), do: {:ok, %{state | clients: %{}}}

  def handle_call({:rejoindre, pid}, _from, state) do
    ref = Process.monitor(pid)
    new_clients = Map.put(state.clients, pid, ref)
    Enum.each(state.historique, fn msg ->
  send(pid, {:message, msg})
end)
    {:reply, :ok, %{state | clients: new_clients}}
  end

  def handle_call({:quitter, pid}, _from, state) do
    case Map.fetch(state.clients, pid) do
      {:ok, ref} ->
        Process.demonitor(ref)
        new_clients = Map.delete(state.clients, pid)
        {:reply, :ok, %{state | clients: new_clients}}
      :error ->
        {:reply, :ok, state}
    end
  end

  def handle_cast({:broadcast, msg}, state) do
    for pid <- Map.keys(state.clients) do
      send(pid, {:message, msg})
    end
    new_historique = [msg | state.historique] |> Enum.take(10)

    {:noreply, %{state | historique: new_historique}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_clients = Map.delete(state.clients, pid)
    {:noreply, %{state | clients: new_clients}}
  end
  def lister do
  Registry.select(MiniDiscord.Registry, [
    {{:"$1", :_, :_}, [], [:"$1"]}
  ])
end
  defp via(name), do: {:via, Registry, {MiniDiscord.Registry, name}}
end
