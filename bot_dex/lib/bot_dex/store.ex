defmodule BotDex.Store do
  @moduledoc """
  Persistência local em JSON para o BotDex.
  Gerencia o arquivo `treinador.json` que guarda os Pokémon capturados pelo treinador.
  """

  @arquivo "treinador.json"

  @doc "Lê o arquivo e devolve o estado atual. Se não existir, devolve estado vazio."
  def carregar do
    case File.read(@arquivo) do
      {:ok, conteudo} -> Jason.decode!(conteudo)
      {:error, :enoent} -> %{"capturados" => []}
    end
  end

  @doc "Adiciona um Pokémon à bag e devolve o novo estado."
  def adicionar(nome) do
    estado = carregar()

    novo_estado =
      Map.update(estado, "capturados", [nome], fn lista -> [nome | lista] end)

    salvar(novo_estado)
    novo_estado
  end

  @doc "Remove todas as ocorrências de `nome` e devolve quantas foram removidas."
  def remover(nome) do
    estado = carregar()
    lista_atual = Map.get(estado, "capturados", [])

    {removidos, nova_lista} =
      Enum.split_with(lista_atual, fn n -> n == nome end)

    case removidos do
      [] -> 0
      _ ->
        salvar(Map.put(estado, "capturados", nova_lista))
        length(removidos)
    end
  end

  @doc "Total de Pokémon capturados."
  def total do
    carregar()
    |> Map.get("capturados", [])
    |> length()
  end

  defp salvar(estado) do
    File.write!(@arquivo, Jason.encode!(estado, pretty: true))
  end
end
