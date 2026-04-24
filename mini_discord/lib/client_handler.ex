defmodule MiniDiscord.ClientHandler do
  require Logger

  def start(socket) do
    :gen_tcp.send(socket, "Bienvenue sur MiniDiscord!\r\n")
    pseudo= choisir_pseudo(socket)
    :gen_tcp.send(socket, "Entre ton pseudo : ")
    {:ok, pseudo} = :gen_tcp.recv(socket, 0)
    pseudo = String.trim(pseudo)

    :gen_tcp.send(socket, "Salons disponibles : #{salons_dispo()}\r\n")
    :gen_tcp.send(socket, "Rejoins un salon (ex: general) : ")
    {:ok, salon} = :gen_tcp.recv(socket, 0)
    salon = String.trim(salon)

    rejoindre_salon(socket, pseudo, salon)
  end

  defp rejoindre_salon(socket, pseudo, salon) do
    case Registry.lookup(MiniDiscord.Registry, salon) do
      [] ->
        DynamicSupervisor.start_child(
          MiniDiscord.SalonSupervisor,
          {MiniDiscord.Salon, salon})
      _ -> :ok
    end

    MiniDiscord.Salon.rejoindre(salon, self())
    MiniDiscord.Salon.broadcast(salon, "📢 #{pseudo} a rejoint ##{salon}\r\n")
    :gen_tcp.send(socket, "Tu es dans ##{salon} — écris tes messages !\r\n")

    loop(socket, pseudo, salon)
  end

  defp loop(socket, pseudo, salon) do
    receive do
      {:message, msg} ->
        :gen_tcp.send(socket, msg)
    after 0 -> :ok
    end

    case :gen_tcp.recv(socket, 0, 100) do
      {:ok, msg} ->
        msg = String.trim(msg)
        MiniDiscord.Salon.broadcast(salon, "[#{pseudo}] #{msg}\r\n")
        loop(socket, pseudo, salon)

      {:error, :timeout} ->
        loop(socket, pseudo, salon)

      {:error, reason} ->
        Logger.info("Client déconnecté : #{inspect(reason)}")
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
    end
  end

  defp salons_dispo do
    case MiniDiscord.Salon.lister() do
      [] -> "aucun (tu seras le premier !)"
      salons -> Enum.join(salons, ", ")
    end
  end
  defp pseudo_disponible?(pseudo) do
  case :ets.lookup(:pseudos, pseudo) do
    [] -> true
    _ -> false
  end
end

defp reserver_pseudo(pseudo) do
  :ets.insert(:pseudos, {pseudo, self()})
end

defp liberer_pseudo(pseudo) do
  :ets.delete(:pseudos, pseudo)
end
defp choisir_pseudo(socket) do
  :gen_tcp.send(socket, "Entre ton pseudo : ")
  {:ok, pseudo} = :gen_tcp.recv(socket, 0)
  pseudo = String.trim(pseudo)

  if pseudo_disponible?(pseudo) do
    reserver_pseudo(pseudo)
    pseudo
  else
    :gen_tcp.send(socket, "Pseudo déjà pris, choisis-en un autre.\r\n")
    choisir_pseudo(socket)
  end
end
end
