defmodule BotDexTest do
  use ExUnit.Case
  doctest BotDex

  test "greets the world" do
    assert BotDex.hello() == :world
  end
end
