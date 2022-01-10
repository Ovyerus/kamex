defmodule Kamex.Util do
  @moduledoc false

  def sublist?([], _), do: false

  def sublist?([_ | t] = haystack, needle),
    do: List.starts_with?(haystack, needle) or sublist?(t, needle)
end

defimpl String.Chars, for: Complex do
  def to_string(%{re: re, im: im}), do: "#{re}J#{im}"
end
