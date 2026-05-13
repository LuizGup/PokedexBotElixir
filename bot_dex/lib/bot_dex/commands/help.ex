defmodule BotDex.Commands.Help do
  @moduledoc """
  Comando `!help` — lista todos os comandos disponíveis com exemplo de uso.
  Comando bônus: não consome API externa, apenas responde com texto estático.
  """
  alias Nostrum.Api.Message

  @mensagem """
  📖 **BotDex — Comandos disponíveis**

  ⚡ `!pika`
  Retorna um GIF aleatório do Pikachu.
  _Ex:_ `!pika`

  🔍 `!dex <nome>`
  Mostra a ficha de um Pokémon (tipos, peso, altura).
  _Ex:_ `!dex charizard`

  🃏 `!carta <nome>`
  Busca a imagem oficial de uma carta de TCG.
  _Ex:_ `!carta pikachu`

  📺 `!ep <temporada> <episodio>`
  Mostra informações de um episódio do anime Pokémon.
  _Ex:_ `!ep 1 25`

  ⚔️ `!comparar <p1> <p2>`
  Compara a popularidade de dois Pokémon no MyAnimeList.
  _Ex:_ `!comparar pikachu mewtwo`

  🎯 `!capturar <nome>`
  Captura um Pokémon e salva na sua bag (treinador.json).
  _Ex:_ `!capturar bulbasaur`

  🎒 `!bag`
  Lista todos os Pokémon na sua bag com ID e tipo.
  _Ex:_ `!bag`

  👋 `!soltar <nome>`
  Solta um Pokémon da sua bag.
  _Ex:_ `!soltar pikachu`

  🌍 `!habitat <cidade>`
  Sugere um Pokémon baseado no clima atual da cidade.
  _Ex:_ `!habitat fortaleza`

  📖 `!help`
  Mostra esta mensagem.
  """

  def run(msg) do
    Message.create(msg.channel_id, @mensagem)
  end
end
