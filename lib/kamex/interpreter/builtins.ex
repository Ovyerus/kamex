defmodule Kamex.Interpreter.Builtins do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2]
  alias Kamex.Exceptions

  @tru 1
  @fals 0

  @mapping [
    =: :eq,
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
    tack: :tack,
    reverse: :reverse
  ]

  def builtin?(name), do: Keyword.get(@mapping, name)

  def run(name, args, locals) do
    args = Enum.map(args, &compute_expr(&1, locals))
    real_fn = Keyword.get(@mapping, name)

    {apply(__MODULE__, real_fn, [args]), locals}
  end

  def eq([a, b]) do
    if a == b, do: @tru, else: @fals
  end

  def add([a, b]), do: a + b

  def sub([x]), do: x * -1
  def sub([a, b]), do: a - b

  def div([a, b]), do: a / b
  def mul([a, b]), do: a * b

  def incf([num]) when is_integer(num) or is_float(num), do: num + 1
  def decf([num]) when is_integer(num) or is_float(num), do: num - 1

  def cons([head, tail]) when is_list(tail), do: [head | tail]

  def cons([_head, _tail]),
    do: raise(Exceptions.IllegalTypeError, message: "cannot `cons` non-list tail")

  # TODO: better error for when first arg is non list/check to make sure all items is a list (how without iterating through all items?)
  def append(lists), do: Enum.reduce(lists, [], fn x, acc -> acc ++ x end)

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

  def fac([num]) when is_integer(num), do: num * fac([num - 1])

  def tack([nth]) do
    fn args_to_pick, _locals -> Enum.at(args_to_pick, nth) end
  end

  def reverse([str]) when is_binary(str), do: String.reverse(str)
  def reverse([list]) when is_list(list), do: Enum.reverse(list)
end
