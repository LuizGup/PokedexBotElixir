defmodule BotDex.Commands.Capturar do
  @moduledoc """
  Comando `!capturar <nome>` — valida a forma do Pokémon na PokéAPI e salva na bag local (treinador.json).
  Usa o endpoint `pokemon-form` da PokéAPI (distinto do `pokemon` usado no !dex).
  Categoria: comando com PERSISTÊNCIA JSON (requisito obrigatório do edital).
  """
  alias Nostrum.Api.Message
  alias BotDex.Store

  @base_url "https://pokeapi.co/api/v2/pokemon-form/"

  def run(msg, nome) do
    nome
    |> String.trim()
    |> String.downcase()
    |> validar_e_capturar()
    |> enviar_mensagem(msg.channel_id)
  end

  defp validar_e_capturar(""), do: "⚠️ Use `!capturar <nome>`. Ex: `!capturar pikachu`"

  defp validar_e_capturar(nome) do
    case HTTPoison.get(@base_url <> nome) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        novo_estado = Store.adicionar(nome)
        total = length(novo_estado["capturados"])
        "🎯 Você capturou **#{String.capitalize(nome)}**! Total na bag: **#{total}** Pokémon."

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        "❌ **#{nome}** não existe — não dá pra capturar fantasma."

      {:ok, %HTTPoison.Response{status_code: code}} ->
        "⚠️ PokéAPI retornou status #{code}."

      {:error, %HTTPoison.Error{reason: reason}} ->
        "⚠️ Erro de conexão: #{inspect(reason)}"
    end
  end

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
