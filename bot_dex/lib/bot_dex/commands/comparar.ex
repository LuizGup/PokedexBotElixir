defmodule BotDex.Commands.Comparar do
  @moduledoc """
  Comando `!comparar <p1> <p2>` — compara a popularidade de dois Pokémon no MyAnimeList via Jikan API.
  Usa o endpoint /characters?q={nome} da Jikan (API não-oficial do MyAnimeList, domínio distinto).
  Faz duas chamadas em paralelo via Task.async para reduzir o tempo total.
  Categoria: comando com DOIS parâmetros.
  """
  alias Nostrum.Api.Message

  @base_url "https://api.jikan.moe/v4/characters"
  # pikachu, mewtwo, mew, gyarados, ditto, abra

  def run(msg, args) do
    args
    |> String.trim()
    |> String.split(" ", parts: 2)
    |> processar_args()
    |> enviar_mensagem(msg.channel_id)
  end

  defp processar_args([p1, p2]) do
    tarefa1 = Task.async(fn -> buscar(p1) end)
    tarefa2 = Task.async(fn -> buscar(p2) end)

    [Task.await(tarefa1), Task.await(tarefa2)]
    |> formatar_comparacao()
  end

  defp processar_args(_), do: "⚠️ Uso correto: `!comparar <p1> <p2>`. Ex: `!comparar pikachu charizard`"

  defp buscar(nome) do
    url = "#{@base_url}?q=#{URI.encode(nome |> String.trim() |> String.downcase())}&limit=5"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"data" => []} ->
            {:erro, "❌ **#{nome}** não encontrado no MyAnimeList."}

          %{"data" => resultados} ->
            nome_lower = String.downcase(nome)
            melhor = Enum.find(resultados, fn r ->
              String.contains?(String.downcase(r["name"]), nome_lower)
            end)
            case melhor do
              nil -> {:erro, "❌ **#{nome}** não encontrado no MyAnimeList."}
              _   -> {:ok, melhor}
            end
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:erro, "❌ **#{nome}** não encontrado."}

      _ ->
        {:erro, "⚠️ Falha ao buscar **#{nome}**."}
    end
  end

  defp formatar_comparacao([{:erro, msg}, _]), do: msg
  defp formatar_comparacao([_, {:erro, msg}]), do: msg

  defp formatar_comparacao([{:ok, p1}, {:ok, p2}]) do
    n1 = String.slice(p1["name"], 0, 15)
    n2 = String.slice(p2["name"], 0, 15)
    f1 = p1["favorites"]
    f2 = p2["favorites"]

    vencedor =
      cond do
        f1 > f2 -> "#{n1} (#{f1} fãs)"
        f2 > f1 -> "#{n2} (#{f2} fãs)"
        true -> "Empate! (#{f1} fãs cada)"
      end

    """
    🏆 **Popularidade no MyAnimeList**
    ```
    #{String.pad_trailing(n1, 15)} #{String.pad_leading("#{f1}", 6)} fãs
    #{String.pad_trailing(n2, 15)} #{String.pad_leading("#{f2}", 6)} fãs
    ```
    🥇 **Mais popular:** #{vencedor}
    """
  end

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
