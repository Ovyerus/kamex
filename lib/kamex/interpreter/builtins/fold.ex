defmodule Kamex.Interpreter.Builtins.Fold do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2]
  alias Kamex.Exceptions

  defmacro supported do
    quote do
      %{
        foldl: :foldl,
        foldr: :foldr,
        foldl1: :foldl1,
        foldr1: :foldr1,
        scanl: :scanl,
        scanr: :scanr,
        scanl1: :scanl1,
        scanr1: :scanr1
      }
    end
  end

  def foldl([_f, acc, []], _), do: acc

  def foldl([f, acc, data], locals) when is_list(data),
    do: List.foldl(data, acc, &compute_expr([f, &2, &1], locals))

  # TODO: supports 2-ary to become -1 varient?

  def foldr([_f, acc, []], _), do: acc

  # For some reason the -r functions pass acc as second.
  def foldr([f, acc, data], locals) when is_list(data),
    do: List.foldr(data, acc, &compute_expr([f, &1, &2], locals))

  def foldl1([_f, []], _),
    do: raise(Exceptions.IllegalTypeError, message: "foldl1: cannot fold empty list")

  def foldl1([_f, [x]], _), do: x

  def foldl1([f, [head | tail]], locals),
    do: List.foldl(tail, head, &compute_expr([f, &2, &1], locals))

  def foldr1([_f, []], _),
    do: raise(Exceptions.IllegalTypeError, message: "foldr1: cannot fold empty list")

  def foldr1([_f, [x]], _), do: x

  def foldr1([f, [head | tail]], locals),
    do: List.foldr(tail, head, &compute_expr([f, &1, &2], locals))

  # ---
  # scanl, scanr

  def scanl([_f, acc, []], _), do: [acc]

  def scanl([f, acc, data], locals) when is_list(data),
    do: Enum.scan(data, acc, &compute_expr([f, &2, &1], locals))

  def scanr([_f, acc, []], _), do: [acc]

  def scanr([f, acc, data], locals) when is_list(data),
    do: Enum.scan(Enum.reverse(data), acc, &compute_expr([f, &1, &2], locals)) |> Enum.reverse()

  def scanl1([_f, []], _),
    do: raise(Exceptions.IllegalTypeError, message: "scanl1: cannot scan empty list")

  def scanl1([_f, [x]], _), do: [x]

  def scanl1([f, list], locals),
    do: Enum.scan(list, &compute_expr([f, &2, &1], locals))

  def scanr1([_f, []], _),
    do: raise(Exceptions.IllegalTypeError, message: "scanr1: cannot scan empty list")

  def scanr1([_f, [x]], _), do: [x]

  def scanr1([f, list], locals),
    do: Enum.scan(Enum.reverse(list), &compute_expr([f, &1, &2], locals)) |> Enum.reverse()
end
