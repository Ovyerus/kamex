defmodule Kamex.Interpreter.Builtins do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2]

  @mapping [
    +: :add,
    -: :sub,
    *: :mul,
    /: :div,
    ++: :incf,
    incf: :incf,
    --: :decf,
    decf: :decf,
    !: :fac,
    fac: :fac,
    cons: :cons,
    append: :append,
    list: :list,
    head: :head,
    tail: :tail,
    car: :head,
    cdr: :tail,
    println: :println,
    zerop: :zerop
  ]

  def builtin?(name), do: Keyword.get(@mapping, name)

  def run(name, args, locals) do
    args = Enum.map(args, &compute_expr(&1, locals))
    real_fn = Keyword.get(@mapping, name)

    {apply(__MODULE__, real_fn, [args]), locals}
  end

  def add(args) when is_list(args) do
    Enum.sum(args)
  end

  def sub([x]), do: x * -1

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

  def decf([num]) when is_integer(num) or is_float(num) do
    num - 1
  end

  # TODO: better error for non-list tail
  def cons([head, tail]) when is_list(tail) do
    [head | tail]
  end

  # TODO: better error for when first arg is non list/check to make sure all items is a list (how without iterating through all items?)
  def append(lists) do
    Enum.reduce(lists, [], fn x, acc -> acc ++ x end)
  end

  def list(args), do: args

  def head([[hd | _]]), do: hd

  def tail([[_ | tl]]), do: tl

  def println([term]) do
    IO.puts(term)
    term
  end

  def zerop([term]) when term == 0, do: true
  def zerop(_term), do: []

  def fac([0]), do: 1

  def fac([num]) when is_integer(num) do
    num * fac([num - 1])
  end
end
