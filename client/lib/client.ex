defmodule MiniDiscord.Client do
  @max_size 500
  @cle "12345678901234567890123456789012"

  def start(host, port) do
    connect_with_retry(host, port, 1)
  end

  defp connect_with_retry(host, port, attempt) do
    options = [:binary, packet: :line, active: false]

    case :gen_tcp.connect(String.to_charlist(host), port, options) do
      {:ok, socket} ->
        IO.puts("Connecte au serveur.")
        rencontre(socket)

        receiver = Task.async(fn -> receive_loop(socket, host, port) end)
        sender = Task.async(fn -> send_loop(socket) end)

        Task.await(receiver, :infinity)
        Task.await(sender, :infinity)

      {:error, reason} ->
        IO.puts("Tentative #{attempt} echouee : #{inspect(reason)}")
        :timer.sleep(2000)
        connect_with_retry(host, port, attempt + 1)
    end
  end

  defp rencontre(socket) do
    recv_print(socket)
    recv_print(socket)

    pseudo = IO.gets("Pseudo : ") |> String.trim()
    :gen_tcp.send(socket, pseudo <> "\r\n")

    recv_print(socket)
    recv_print(socket)

    salon = IO.gets("Salon : ") |> String.trim()
    :gen_tcp.send(socket, salon <> "\r\n")

    recv_print(socket)
  end

  defp receive_loop(socket, host, port) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, msg} ->
        case dechiffrer_message(msg) do
          {:ok, msg_dechiffre} ->
            case valider_message(msg_dechiffre) do
              {:ok, msg_valide} -> IO.write(msg_valide)
              {:error, erreur} -> IO.puts("Message refuse : #{erreur}")
            end

          {:error, _} ->
            IO.puts("Erreur de dechiffrement")
        end

        receive_loop(socket, host, port)

      {:error, reason} ->
        IO.puts("\nConnexion perdue (#{inspect(reason)}). Reconnexion...")
        :gen_tcp.close(socket)
        connect_with_retry(host, port, 1)
    end
  end

  defp send_loop(socket) do
    msg = IO.gets("")

    case valider_message(msg) do
      {:ok, msg_valide} ->
        msg_chiffre = chiffrer_message(msg_valide)
        :gen_tcp.send(socket, msg_chiffre)

      {:error, erreur} ->
        IO.puts("Message non envoye : #{erreur}")
    end

    send_loop(socket)
  end

  defp recv_print(socket) do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, msg} -> IO.write(msg)
      {:error, _} -> IO.puts("Deconnecte")
    end
  end

  defp valider_message(msg) do
    msg_trim = String.trim(msg)

    cond do
      msg_trim == "" ->
        {:error, "Message vide"}

      String.length(msg_trim) > @max_size ->
        {:error, "Message trop long (max 500 chars)"}

      String.contains?(msg_trim, ["\\", "?", "<", ">"]) ->
        {:error, "Message contient un caractere interdit"}

      true ->
        {:ok, msg}
    end
  end

  defp chiffrer_message(msg) do
    iv = :crypto.strong_rand_bytes(16)
    msg_c = :crypto.crypto_one_time(:aes_256_ctr, @cle, iv, msg, true)
    Base.encode64(iv <> msg_c) <> "\n"
  end

  defp dechiffrer_message(msg_recu) do
    msg_recu = String.trim(msg_recu)

    case Base.decode64(msg_recu) do
      {:ok, <<iv::binary-size(16), msg_chiffre::binary>>} ->
        msg = :crypto.crypto_one_time(:aes_256_ctr, @cle, iv, msg_chiffre, false)
        {:ok, msg}

      _ ->
        {:error, "message chiffre invalide"}
    end
  end
end
