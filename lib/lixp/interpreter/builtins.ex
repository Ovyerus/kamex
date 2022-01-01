defmodule Lixp.Interpreter.Builtins do
  @moduledoc false

  # def quote([arg]) do
  #   arg
  # end

  def add(args) when is_list(args) do
    Enum.sum(args)
  end

  def sub(args) when is_list(args) do
    Enum.reduce(args, fn x, acc -> acc - x end)
  end

  def div(args) when is_list(args) do
    Enum.reduce(args, fn x, acc -> acc / x end)
  end

  def mul(args) when is_list(args) do
    Enum.reduce(args, fn x, acc -> acc * x end)
  end

  def incf([num]) when is_integer(num) or is_float(num) do
    num + 1
  end

  # TODO: better error for non-list tail
  def cons([head | [tail]]) when is_list(tail) do
    [head | tail]
  end

  # TODO: better error for when first arg is non list/check to make sure all items is a list (how without iterating through all items?)
  def append(lists) do
    Enum.reduce(lists, [], fn x, acc -> acc ++ x end)
  end

  # def list(args) when is_list(args) do
  #   args
  # end
end
