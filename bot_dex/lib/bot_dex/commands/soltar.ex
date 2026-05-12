defmodule BotDex.Commands.Soltar do
  @moduledoc """
  Comando `!soltar <nome>` — remove todas as ocorrências de um Pokémon da bag.
  Comando bônus (não conta para os 7 do edital).
  """
  alias Nostrum.Api.Message
  alias BotDex.Store

  def run(msg, nome) do
    nome
    |> String.trim()
    |> String.downcase()
    |> processar()
    |> enviar_mensagem(msg.channel_id)
  end

  defp processar(""), do: "⚠️ Use `!soltar <nome>`. Ex: `!soltar pikachu`"

  defp processar(nome) do
    case Store.remover(nome) do
      0 -> "❌ **#{nome}** não está na sua bag."
      1 -> "👋 Você soltou **#{String.capitalize(nome)}**. Boa sorte na natureza!"
      n -> "👋 Você soltou **#{n}x #{String.capitalize(nome)}**. Eles estão livres agora!"
    end
  end

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
