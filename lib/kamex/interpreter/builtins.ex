defmodule Kamex.Interpreter.Builtins do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2]
  # alias Kamex.Exceptions
  require __MODULE__.Lists
  alias __MODULE__.Lists

  @tru 1
  @fals 0
  @falsey [[], @fals]

  @supported [
    println: :println,
    tack: :tack,
    nth: :nth,
    not: :not_,
    =: :eq,
    "\\=": :neq,
    +: :add,
    -: :sub,
    *: :mul,
    /: :div,
    %: :mod,
    fac: :fac,
    map: :map,
    filter: :filter,
    count: :count,
    every: :every,
    "flat-map": :flat_map,
    id: :id
  ]

  defmacro mapping do
    map_supported_to_mod = fn mod, {call_name, fn_name} -> {call_name, {fn_name, mod}} end

    items =
      Enum.map(@supported, &map_supported_to_mod.(__MODULE__, &1)) ++
        Enum.map(Lists.supported(), &map_supported_to_mod.(Lists, &1))

    quote do
      unquote(items)
    end
  end

  def builtin?(name), do: Keyword.get(mapping(), name)
  def test(), do: mapping()

  def run(name, args, locals) do
    args = Enum.map(args, &compute_expr(&1, locals))
    {real_fn, mod} = Keyword.get(mapping(), name)

    {apply(mod, real_fn, [args, locals]), locals}
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

  # def not_([value], _), do: if(value in @falsey, do: @tru, else: @fals)
  def not_([x], _) when x in @falsey, do: @tru
  def not_([_], _), do: @fals

  def eq([a, b], _), do: if(a == b, do: @tru, else: @fals)
  def neq([a, b], _), do: if(a == b, do: @fals, else: @tru)

  def add([a, b], _) when is_binary(a) and is_binary(b), do: a <> b
  def add([a, b], _), do: a + b

  def sub([x], _), do: x * -1
  def sub([a, b], _), do: a - b

  def div([a, b], _), do: a / b
  def mul([a, b], _), do: a * b
  def mod([a, b], _), do: rem(a, b)

  def fac([0], _), do: 1
  def fac([num], _) when is_integer(num), do: num * fac([num - 1], nil)

  def map([fun, arg], locals) when is_list(arg), do: map([fun | arg], locals)
  def map([fun, str], locals) when is_binary(str), do: map([fun | String.codepoints(str)], locals)
  def map([fun | args], locals), do: Enum.map(args, &compute_expr([fun, &1], locals))

  def filter([fun, list], locals),
    # Compare against 0 so that we don't have to do a second `not` check for `1`.
    do: Enum.filter(list, fn item -> not_([compute_expr([fun, item], locals)], nil) == 0 end)

  def count([fun, list], locals), do: Enum.count(filter([fun, list], locals))

  def every([fun, list], locals),
    do:
      if(Enum.all?(list, fn item -> not_([compute_expr([fun, item], locals)], nil) == 0 end),
        do: @tru,
        else: @fals
      )

  def flat_map([fun, args], locals), do: Enum.flat_map(args, &compute_expr([fun, &1], locals))

  def id([x], _), do: x
end
