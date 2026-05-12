defmodule BotDex.Commands.Habitat do
  @moduledoc """
  Comando `!habitat <cidade>` — busca o clima atual da cidade e sugere um Pokémon
  cujo tipo combina com a temperatura.

  Combina 2 APIs:
  - Open-Meteo (geocoding + clima)
  - PokéAPI (busca de Pokémon por tipo)

  Categoria: comando COMBINADO (2+ APIs).
  """
  alias Nostrum.Api.Message

  @geocoding_url "https://geocoding-api.open-meteo.com/v1/search"
  @forecast_url "https://api.open-meteo.com/v1/forecast"
  @pokeapi_type_url "https://pokeapi.co/api/v2/type/"

  def run(msg, cidade) do
    cidade
    |> String.trim()
    |> processar()
    |> enviar_mensagem(msg.channel_id)
  end

  defp processar(""), do: "⚠️ Use `!habitat <cidade>`. Ex: `!habitat fortaleza`"

  defp processar(cidade) do
    with {:ok, %{nome: nome, lat: lat, lon: lon}} <- geocodificar(cidade),
         {:ok, temp} <- buscar_temperatura(lat, lon),
         tipo <- tipo_por_temperatura(temp),
         {:ok, pokemon} <- sortear_pokemon_do_tipo(tipo) do
      formatar_sucesso(nome, temp, tipo, pokemon)
    else
      {:erro, msg} -> msg
    end
  end

  # ─── Etapa 1: Geocoding (cidade → lat/lon) ────────────────────────────

  defp geocodificar(cidade) do
    url = "#{@geocoding_url}?name=#{URI.encode(cidade)}&count=1"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"results" => [primeira | _]} ->
            {:ok,
             %{
               nome: primeira["name"],
               lat: primeira["latitude"],
               lon: primeira["longitude"]
             }}

          _ ->
            {:erro, "❌ Cidade **#{cidade}** não encontrada."}
        end

      _ ->
        {:erro, "⚠️ Falha ao buscar a cidade."}
    end
  end

  # ─── Etapa 2: Clima (lat/lon → temperatura) ───────────────────────────

  defp buscar_temperatura(lat, lon) do
    url = "#{@forecast_url}?latitude=#{lat}&longitude=#{lon}&current_weather=true"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"current_weather" => %{"temperature" => temp}} -> {:ok, temp}
          _ -> {:erro, "⚠️ Clima indisponível para essa coordenada."}
        end

      _ ->
        {:erro, "⚠️ Falha ao consultar o clima."}
    end
  end

  # ─── Etapa 3: Mapeamento (temperatura → tipo de Pokémon) ──────────────

  defp tipo_por_temperatura(t) when t < 10, do: "ice"
  defp tipo_por_temperatura(t) when t < 18, do: "water"
  defp tipo_por_temperatura(t) when t < 25, do: "grass"
  defp tipo_por_temperatura(t) when t < 32, do: "fire"
  defp tipo_por_temperatura(_), do: "dragon"

  # ─── Etapa 4: Pokémon aleatório do tipo ───────────────────────────────

  defp sortear_pokemon_do_tipo(tipo) do
    case HTTPoison.get(@pokeapi_type_url <> tipo) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> Map.get("pokemon", [])
        |> Enum.random()
        |> Map.get("pokemon")
        |> Map.get("name")
        |> then(&{:ok, &1})

      _ ->
        {:erro, "⚠️ Falha ao buscar Pokémon do tipo #{tipo}."}
    end
  end

  # ─── Formatação final ─────────────────────────────────────────────────

  defp formatar_sucesso(cidade, temp, tipo, pokemon) do
    """
    🌍 **#{cidade}** — #{temp}°C
    🧬 Tipo sugerido: **#{tipo}**
    🐾 Pokémon do habitat: **#{String.capitalize(pokemon)}**
    """
  end

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
