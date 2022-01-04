defmodule Kamex.Util.Comb do
  @moduledoc """
  Utilities for combinatorics.
  """

  @spec cart_product([list()]) :: [list()]
  def cart_product([]), do: []

  def cart_product([h]) do
    for x <- h, do: [x]
  end

  def cart_product([h | t]) do
    for a <- h, b <- cart_product(t) do
      [a | b]
    end
  end
end
