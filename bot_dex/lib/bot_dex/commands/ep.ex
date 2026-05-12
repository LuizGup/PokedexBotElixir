defmodule BotDex.Commands.Ep do
  @moduledoc """
  Comando `!ep <temporada> <episodio>` — busca um episódio do anime Pokémon via TVMaze API.
  Usa o endpoint /shows/590/episodebynumber (show ID 590 = Pokémon na TVMaze).
  Categoria: comando com DOIS parâmetros.
  """
  alias Nostrum.Api.Message

  @base_url "https://api.tvmaze.com/shows/590/episodebynumber"

  def run(msg, args) do
    args
    |> String.trim()
    |> String.split(" ", parts: 2)
    |> processar_args()
    |> enviar_mensagem(msg.channel_id)
  end

  defp processar_args([temp_str, ep_str]) do
    with {temp, ""} when temp > 0 <- Integer.parse(String.trim(temp_str)),
         {ep, ""} when ep > 0 <- Integer.parse(String.trim(ep_str)) do
      buscar_episodio(temp, ep)
    else
      _ -> "⚠️ Números inválidos. Use inteiros positivos. Ex: `!ep 1 25`"
    end
  end

  defp processar_args(_), do: "⚠️ Uso correto: `!ep <temporada> <episodio>`. Ex: `!ep 1 25`"

  defp buscar_episodio(temporada, episodio) do
    url = "#{@base_url}?season=#{temporada}&number=#{episodio}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body |> Jason.decode!() |> formatar_resposta()

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        "❌ Episódio S#{temporada}E#{String.pad_leading("#{episodio}", 2, "0")} não encontrado."

      {:ok, %HTTPoison.Response{status_code: code}} ->
        "⚠️ TVMaze retornou status #{code}."

      {:error, %HTTPoison.Error{reason: reason}} ->
        "⚠️ Erro de conexão: #{inspect(reason)}"
    end
  end

  defp formatar_resposta(ep) do
    s = ep["season"]
    n = ep["number"]
    nome = ep["name"]
    nota = get_in(ep, ["rating", "average"])
    nota_str = if nota, do: "⭐ #{nota}/10", else: "⭐ Sem nota"

    resumo =
      (ep["summary"] || "Sem resumo disponível.")
      |> String.replace(~r/<[^>]+>/, "")
      |> String.slice(0, 280)

    img = get_in(ep, ["image", "medium"])

    texto = """
    📺 **S#{s}E#{String.pad_leading("#{n}", 2, "0")} — #{nome}**
    #{nota_str}
    📖 _#{resumo}_
    """

    if img, do: texto <> img, else: texto
  end

  defp enviar_mensagem(texto, channel_id) do
    Message.create(channel_id, texto)
  end
end
