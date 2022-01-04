defmodule Kamex.Interpreter.Builtins do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2]
  alias Kamex.Exceptions

  @tru 1
  @fals 0

  @mapping [
    println: :println,
    tack: :tack,
    nth: :nth,
    =: :eq,
    +: :add,
    -: :sub,
    *: :mul,
    /: :div,
    %: :mod,
    fac: :fac,
    map: :map
    # ++: :incf,
    # incf: :incf,
    # --: :decf,
    # decf: :decf,
    # !: :fac,
    # cons: :cons,
    # append: :append,
    # list: :list,
    # head: :head,
    # tail: :tail,
    # car: :head,
    # cdr: :tail,
    # reverse: :reverse
  ]

  def builtin?(name), do: Keyword.get(@mapping, name)

  def run(name, args, locals) do
    args = Enum.map(args, &compute_expr(&1, locals))
    real_fn = Keyword.get(@mapping, name)

    {apply(__MODULE__, real_fn, [args, locals]), locals}
  end

  # ---------------------------------------------------------------------------

  def println([term], _) do
    IO.puts(term)
    term
  end

  def tack([nth], _) do
    fn args_to_pick, _locals -> Enum.at(args_to_pick, nth) end
  end

  def nth([n, args], _), do: Enum.at(args, n)

  def eq([a, b], _), do: if(a == b, do: @tru, else: @fals)

  def add([a, b], _), do: a + b

  def sub([x], _), do: x * -1
  def sub([a, b], _), do: a - b

  def div([a, b], _), do: a / b
  def mul([a, b], _), do: a * b
  def mod([a, b], _), do: rem(a, b)

  def fac([0], _), do: 1
  def fac([num], _) when is_integer(num), do: num * fac([num - 1], nil)

  def map([fun, arg], locals) when is_list(arg), do: map([fun | arg], locals)
  def map([fun, str], locals) when is_binary(str), do: map([fun | String.graphemes(str)], locals)

  def map([fun | args], locals) do
    Enum.map(args, &compute_expr([fun, &1], locals))
  end

  # def incf([num]) when is_integer(num) or is_float(num), do: num + 1
  # def decf([num]) when is_integer(num) or is_float(num), do: num - 1

  # def cons([head, tail]) when is_list(tail), do: [head | tail]

  # def cons([_head, _tail]),
  #   do: raise(Exceptions.IllegalTypeError, message: "cannot `cons` non-list tail")

  # # TOO: better error for when first arg is non list/check to make sure all items is a list (how without iterating through all items?)
  # def append(lists), do: Enum.reduce(lists, [], fn x, acc -> acc ++ x end)

  # def list(args), do: args

  # def head([[hd | _]]), do: hd

  # def tail([[_ | tl]]), do: tl

  # def reverse([str]) when is_binary(str), do: String.reverse(str)
  # def reverse([list]) when is_list(list), do: Enum.reverse(list)
end
