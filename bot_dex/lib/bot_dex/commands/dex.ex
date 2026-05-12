defmodule BotDex.Commands.Dex do
  @moduledoc """
  Comando `!dex <nome>` — busca dados de um Pokémon na PokéAPI.
  Categoria: comando com UM parâmetro.
  """
  alias Nostrum.Api.Message

  @base_url "https://pokeapi.co/api/v2/pokemon/"

  def run(msg, nome) do
    nome
    |> String.trim()
    |> String.downcase()
    |> buscar_pokemon()
    |> enviar_mensagem(msg.channel_id)
  end

  defp buscar_pokemon(""), do: "⚠️ Você precisa informar o nome de um Pokémon. Ex: `!dex pikachu`"

  defp buscar_pokemon(nome) do
    case HTTPoison.get(@base_url <> nome) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> formatar_resposta()

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        "❌ Pokémon **#{nome}** não encontrado. Verifique a grafia."

      {:ok, %HTTPoison.Response{status_code: code}} ->
        "⚠️ PokéAPI retornou status #{code}."

      {:error, %HTTPoison.Error{reason: reason}} ->
        "⚠️ Erro de conexão: #{inspect(reason)}"
    end
  end

  defp formatar_resposta(%{"name" => nome, "id" => id, "types" => tipos, "weight" => peso, "height" => altura}) do
    tipos_str =
      tipos
      |> Enum.map(fn t -> t["type"]["name"] end)
      |> Enum.join(", ")

    """
    ⭐ **#{String.capitalize(nome)}** (#ID: #{id})
    🧪 **Tipos:** #{tipos_str}
    ⚖️  **Peso:** #{peso / 10} kg
    📏 **Altura:** #{altura / 10} m
    """
  end

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
