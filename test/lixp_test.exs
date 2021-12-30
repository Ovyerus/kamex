defmodule LixpTest do
  use ExUnit.Case
  doctest Lixp

  test "greets the world" do
    assert Lixp.hello() == :world
  end
end
