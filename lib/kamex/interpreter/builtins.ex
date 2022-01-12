defmodule Kamex.Interpreter.Builtins do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2]
  # alias Kamex.Exceptions
  require __MODULE__.{Lists, Math}
  alias __MODULE__.{Lists, Math}

  @tru 1
  @fals 0
  @falsey [[], @fals]

  @supported %{
    println: :println,
    tack: :tack,
    nth: :nth,
    not: :not_,
    fac: :fac,
    map: :map,
    filter: :filter,
    count: :count,
    every: :every,
    "flat-map": :flat_map,
    id: :id
  }

  defmacro mapping do
    map_supported_to_mod = fn mod, {call_name, fn_name} -> {call_name, {fn_name, mod}} end

    items =
      [
        Enum.map(@supported, &map_supported_to_mod.(__MODULE__, &1)),
        Enum.map(Lists.supported(), &map_supported_to_mod.(Lists, &1)),
        Enum.map(Math.supported(), &map_supported_to_mod.(Math, &1))
      ]
      |> Enum.map(&Enum.into(&1, %{}))
      |> Enum.reduce(%{}, &Map.merge/2)

    Macro.escape(items)
  end

  def builtin?(name), do: Map.get(mapping(), name)

  def run(name, args, locals) do
    args = Enum.map(args, &compute_expr(&1, locals))
    {real_fn, mod} = Map.get(mapping(), name)

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
