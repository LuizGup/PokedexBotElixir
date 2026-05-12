defmodule BotDex.Commands.Pika do
  @moduledoc """
  Comando `!pika` — retorna um GIF aleatório do Pikachu via Giphy API.
  Categoria: comando SEM parâmetro.
  """
  alias Nostrum.Api.Message

  @endpoint "https://api.giphy.com/v1/gifs/random"
  @tag "pikachu"

  def run(msg) do
    case System.get_env("GIPHY_API_KEY") do
      nil ->
        Message.create(msg.channel_id, "⚠️ `GIPHY_API_KEY` não configurada no ambiente.")

      api_key ->
        @endpoint
        |> montar_url(api_key)
        |> HTTPoison.get()
        |> tratar_resposta()
        |> enviar_mensagem(msg.channel_id)
    end
  end

  defp montar_url(base, key) do
    "#{base}?api_key=#{key}&tag=#{@tag}&rating=g"
  end

  defp tratar_resposta({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body
    |> Jason.decode!()
    |> extrair_url_gif()
  end

  defp tratar_resposta({:ok, %HTTPoison.Response{status_code: code}}) do
    "⚠️ Giphy retornou status #{code}. Tente novamente."
  end

  defp tratar_resposta({:error, %HTTPoison.Error{reason: reason}}) do
    "⚠️ Erro de conexão com Giphy: #{inspect(reason)}"
  end

  defp extrair_url_gif(%{"data" => %{"images" => %{"original" => %{"url" => url}}}}) do
    "⚡ Pika pika! #{url}"
  end

  defp extrair_url_gif(_), do: "❌ Não consegui achar um Pikachu agora 😢"

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
