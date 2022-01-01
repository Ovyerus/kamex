defmodule Lixp.Interpreter.Builtins do
  @moduledoc false

  import Lixp.Interpreter, only: [compute_expr: 3]

  @supported [
    +: :infinity,
    -: :infinity,
    *: :infinity,
    /: :infinity,
    ++: 1,
    incf: 1,
    cons: 2,
    append: :infinity,
    list: :infinity,
    head: 1,
    tail: 1,
    car: 1,
    cdr: 1
  ]

  @mapping [
    +: :add,
    -: :sub,
    *: :mul,
    /: :div,
    ++: :incf,
    incf: :incf,
    cons: :cons,
    append: :append,
    list: :list,
    head: :head,
    tail: :tail,
    car: :head,
    cdr: :tail
  ]

  def builtin?(name, arity),
    do: {name, arity} in @supported || Keyword.get(@supported, name) == :infinity

  def run(name, args, locals) do
    args = Enum.map(args, &compute_expr(&1, locals, false))

    is_variable = Keyword.get(@supported, name) == :infinity
    real_fn = Keyword.get(@mapping, name)

    {apply(__MODULE__, real_fn, if(is_variable, do: [args], else: args)), locals}
  end

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

  def incf(num) when is_integer(num) or is_float(num) do
    num + 1
  end

  # TODO: better error for non-list tail
  def cons(head, tail) when is_list(tail) do
    [head | tail]
  end

  # TODO: better error for when first arg is non list/check to make sure all items is a list (how without iterating through all items?)
  def append(lists) do
    Enum.reduce(lists, [], fn x, acc -> acc ++ x end)
  end

  def list(args) do
    args
  end

  def head([hd | _]), do: hd

  def tail([_ | tl]), do: tl
end
