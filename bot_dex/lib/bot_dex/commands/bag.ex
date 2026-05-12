defmodule BotDex.Commands.Bag do
  @moduledoc """
  Comando `!bag` — lista todos os Pokémon capturados com ID e tipo principal.
  Comando bônus (não conta para os 7 do edital).
  """
  alias Nostrum.Api.Message

  @base_url "https://pokeapi.co/api/v2/pokemon/"

  def run(msg) do
    case BotDex.Store.carregar()["capturados"] do
      [] ->
        Message.create(msg.channel_id, "🎒 Sua bag está vazia. Use `!capturar <nome>` para começar.")

      nomes ->
        nomes
        |> Enum.map(&buscar_resumo/1)
        |> formatar_bag()
        |> enviar_mensagem(msg.channel_id)
    end
  end

  defp buscar_resumo(nome) do
    case HTTPoison.get(@base_url <> nome) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        data = Jason.decode!(body)
        tipo = data["types"] |> List.first() |> Map.get("type") |> Map.get("name")
        "##{data["id"]} **#{String.capitalize(data["name"])}** (_#{tipo}_)"

      _ ->
        "❓ #{nome} (falha na busca)"
    end
  end

  defp formatar_bag(linhas) do
    """
    🎒 **Sua bag** (#{length(linhas)} Pokémon)
    #{Enum.join(linhas, "\n")}
    """
  end

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
