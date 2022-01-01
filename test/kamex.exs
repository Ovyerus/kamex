defmodule KamexTest do
  use ExUnit.Case
  doctest Kamex

  test "greets the world" do
    assert Kamex.hello() == :world
  end
end
