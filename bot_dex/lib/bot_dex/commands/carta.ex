defmodule BotDex.Commands.Carta do
  @moduledoc """
  Comando `!carta <nome>` — busca a imagem oficial de uma carta na Pokémon TCG API.
  Categoria: comando com UM parâmetro.
  """
  alias Nostrum.Api.Message

  @base_url "https://api.pokemontcg.io/v2/cards"
  @http_options [recv_timeout: 15_000, timeout: 15_000]

  def run(msg, nome) do
    nome
    |> String.trim()
    |> buscar_carta()
    |> enviar_mensagem(msg.channel_id)
  end

  defp buscar_carta(""), do: "⚠️ Informe o nome de um Pokémon. Ex: `!carta charizard`"

  defp buscar_carta(nome) do
    url = "#{@base_url}?q=name:#{URI.encode(nome)}"

    case HTTPoison.get(url, [], @http_options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> extrair_carta(nome)

      {:ok, %HTTPoison.Response{status_code: code}} ->
        "⚠️ Pokémon TCG API retornou status #{code}."

      {:error, %HTTPoison.Error{reason: reason}} ->
        "⚠️ Erro de conexão: #{inspect(reason)}"
    end
  end

  defp extrair_carta(%{"data" => []}, nome) do
    "❌ Nenhuma carta encontrada para **#{nome}**."
  end

  defp extrair_carta(%{"data" => [primeira | _resto]}, _nome) do
    formatar_carta(primeira)
  end

  defp formatar_carta(%{"name" => nome, "images" => %{"large" => url}, "set" => %{"name" => set}}) do
    """
    🃏 **#{nome}** — _#{set}_
    #{url}
    """
  end

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
