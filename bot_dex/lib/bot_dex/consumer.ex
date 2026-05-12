defmodule BotDex.Consumer do
  use Nostrum.Consumer
  require Logger

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    Logger.debug("MESSAGE_CREATE recebida: #{inspect(msg.content)}")

    case msg.content do
      "!pika" ->
        BotDex.Commands.Pika.run(msg)

      "!dex " <> nome ->
        BotDex.Commands.Dex.run(msg, nome)

      "!carta " <> nome ->
        BotDex.Commands.Carta.run(msg, nome)

      "!ep " <> args ->
        BotDex.Commands.Ep.run(msg, args)

      "!comparar " <> args ->
        BotDex.Commands.Comparar.run(msg, args)

      "!capturar " <> nome ->
        BotDex.Commands.Capturar.run(msg, nome)

      "!habitat " <> cidade ->
        BotDex.Commands.Habitat.run(msg, cidade)

      "!bag" ->
        BotDex.Commands.Bag.run(msg)

      "!soltar " <> nome ->
        BotDex.Commands.Soltar.run(msg, nome)

      "!help" ->
        BotDex.Commands.Help.run(msg)

      _ ->
        :ignore
    end
  end

  def handle_event(_event), do: :ignore
end
