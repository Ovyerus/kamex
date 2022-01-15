defmodule Kamex.Util.Comb do
  @moduledoc """
  Utilities for combinatorics.
  """

  def cartesian_product(lists) when is_list(lists) do
    lists
    |> Enum.reduce(&cart_prod([&1, &2]))
    |> Enum.map(fn x -> x |> List.flatten() |> Enum.reverse() end)
  end

  defp cart_prod([]), do: []

  defp cart_prod([h]) do
    for x <- h, do: [x]
  end

  defp cart_prod([h | t]) do
    for a <- h, b <- cart_prod(t) do
      [a | b]
    end
  end
end
