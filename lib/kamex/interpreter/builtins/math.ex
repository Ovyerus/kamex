defmodule Kamex.Interpreter.Builtins.Math do
  @moduledoc false
  alias Kamex.Exceptions

  @tru 1
  @fals 0
  # @falsey [[], @fals]

  def add([a, b], _) when is_binary(a) and is_binary(b), do: a <> b
  def add([a, b], _) when is_number(a) and is_number(b), do: a + b
  # Can't do my own `is_complex` helper so multiple clauses will have to do :/
  def add([%Complex{} = a, %Complex{} = b], _), do: Complex.add(a, b)
  def add([%Complex{} = a, b], _) when is_number(b), do: Complex.add(a, b)
  def add([a, %Complex{} = b], _) when is_number(a), do: Complex.add(a, b)

  def add([a, b], _) when is_number(a) and is_binary(b), do: to_string(a) <> b
  def add([a, b], _) when is_binary(a) and is_number(b), do: a <> to_string(b)
  def add([%Complex{} = a, b]) when is_binary(b), do: to_string(a) <> b
  def add([a, %Complex{} = b]) when is_binary(a), do: a <> to_string(b)
  # TODO: better errors for mismatching types

  # ---

  def subtract([x], _) when is_number(x), do: -x
  def subtract([%Complex{} = x], _), do: Complex.neg(x)

  def subtract([a, b], _) when is_number(a) and is_number(b), do: a - b
  def subtract([%Complex{} = a, %Complex{} = b], _), do: Complex.sub(a, b)
  def subtract([%Complex{} = a, b], _) when is_number(b), do: Complex.sub(a, b)
  def subtract([a, %Complex{} = b], _) when is_number(a), do: Complex.sub(a, b)

  # ---
  # TODO: ask how unary multiply works

  def multiply([a, b], _) when is_number(a) and is_number(b), do: a * b
  def multiply([%Complex{} = a, %Complex{} = b], _), do: Complex.mult(a, b)
  def multiply([%Complex{} = a, b], _) when is_number(b), do: Complex.mult(a, b)
  def multiply([a, %Complex{} = b], _) when is_number(a), do: Complex.mult(a, b)

  # ---
  # TODO: ask how unary division works

  def divide([a, b], _) when is_number(a) and is_number(b), do: a / b
  def divide([%Complex{} = a, %Complex{} = b], _), do: Complex.div(a, b)
  def divide([%Complex{} = a, b], _) when is_number(b), do: Complex.div(a, Complex.new(b))
  def divide([a, %Complex{} = b], _) when is_number(a), do: Complex.div(Complex.new(a), b)

  # ---
  # TODO: integer division

  # ---

  def modulo([x], _) when is_number(x), do: abs(x)
  # TODO: need to sqrt norm
  def modulo([%Complex{} = x], _), do: x
  def modulo([a, b], _) when is_integer(a) and is_integer(b), do: rem(a, b)

  def sqrt([x], _) when is_number(x), do: :math.sqrt(x)

  def sqrt([%Complex{im: 0, re: re}], _) when re < 0,
    do: raise(Exceptions.MathError, message: "sqrt: im=0 re<0 doesn't exist")

  # TODO: sqrt of complex
  # ---

  def nth_root([_, exp], _) when not is_number(exp),
    do: raise(Exceptions.IllegalTypeError, message: "nth_root: exponent must be a real number")

  # TODO: need to convert to int, which way does kami round?
  def nth_root([x, exp], _) when is_integer(x), do: :math.pow(x, 1 / exp)
  def nth_root([x, exp], _) when is_float(x), do: :math.pow(x, 1 / exp)
  def nth_root([%Complex{} = x, exp], _), do: Complex.pow(x, Complex.new(1 / exp))

  # ---

  def power([x, exp], _) when is_number(x) and is_number(exp), do: :math.pow(x, exp)
  def power([%Complex{} = x, exp], _) when is_number(exp), do: Complex.pow(x, Complex.new(exp))

  # TODO: move iota here, and support 3-arg for it
  # TODO: see if putting comparisons in guards is faster than if/else

  def equals([a, b], _) when a == b, do: @tru
  def equals([_, _], _), do: @fals

  def not_equals([a, b], _) when a == b, do: @fals
  def not_equals([_, _], _), do: @tru

  def less_than([a, b], _) when a < b, do: @tru
  def less_than([_, _], _), do: @fals
  def less_than([x], _) when is_number(x), do: x - 1
  def less_than([%Complex{} = x], _), do: Complex.sub(x, 1)
  # TODO: unary < string works like ruby pred, same for > and succ.

  def greater_than([a, b], _) when a > b, do: @tru
  def greater_than([_, _], _), do: @fals
  def greater_than([x], _) when is_number(x), do: x + 1
  def greater_than([%Complex{} = x], _), do: Complex.add(x, 1)

  def less_equal([a, b], _) when a <= b, do: @tru
  def less_equal([_, _], _), do: @fals

  def greater_equal([a, b], _) when a >= b, do: @tru
  def greater_equal([_, _], _), do: @fals

  # ---

  def ceiling([x], _) when is_number(x), do: :math.ceil(x)
  def ceiling([%Complex{im: im, re: re}], _), do: Complex.new(:math.ceil(re), :math.ceil(im))
  def ceiling([x, 0], _), do: ceiling([x], nil)

  def ceiling([x, places], _) when is_number(x) and is_integer(places) and places > 0,
    do: :math.ceil(x * 10 ** places) / 10 ** places

  # TODO: explain what the fuck, can probably just call with abs
  def ceiling([x, places], _) when is_number(x) and is_integer(places) and places < 0,
    do: :math.ceil(x / 10 ** places) * 10 ** places

  def ceiling([%Complex{im: im, re: re}, places], _),
    do: Complex.new(ceiling([re, places], nil), ceiling([im, places], nil))

  def floor([x], _) when is_number(x), do: :math.floor(x)
  def floor([%Complex{im: im, re: re}], _), do: Complex.new(:math.floor(re), :math.floor(im))
  def floor([x, 0], _), do: floor([x], nil)

  def floor([x, places], _) when is_number(x) and is_integer(places) and places > 0,
    do: :math.floor(x * 10 ** places) / 10 ** places

  def floor([x, places], _) when is_number(x) and is_integer(places) and places < 0,
    do: :math.floor(x / 10 ** places) * 10 ** places

  def floor([%Complex{im: im, re: re}, places], _),
    do: Complex.new(floor([re, places], nil), floor([im, places], nil))

  # ---
  # TODO: binary or, and, xor

  def gcd([a, b], _) when is_integer(a) and is_integer(b), do: Math.gcd(a, b)

  def gcd([n1, n2], _)
      when (is_integer(n1) and is_float(n2)) or (is_float(n1) and is_integer(n2)) or
             (is_float(n1) and is_float(n2)) do
    # gcd(a/b, c/d) = gcd(a, c) / lcm(b, d)
    %{numerator: a, denominator: b} = Ratio.FloatConversion.float_to_rational(n1)
    %{numerator: c, denominator: d} = Ratio.FloatConversion.float_to_rational(n2)
    top = Math.gcd(a, c)
    bottom = Math.lcm(b, d)

    # Would normally return a fraction but its not a core type so lol nah
    top / bottom
  end

  # TODO: this

  def gcd([%Complex{} = n1, n2], _) when is_integer(n2), do: gcd_complex(n1, Complex.new(n2))
  def gcd([n1, %Complex{} = n2], _) when is_integer(n1), do: gcd_complex(Complex.new(n1), n2)
  def gcd([%Complex{} = n1, %Complex{} = n2], _), do: gcd_complex(n1, n2)

  defp gcd_complex(_, _), do: nil

  # ---
  def lcm([a, b], _) when is_integer(a) and is_integer(b), do: Math.lcm(a, b)

  # Basically just the inverse of the float GCM
  def lcm([n1, n2], _)
      when (is_integer(n1) and is_float(n2)) or (is_float(n1) and is_integer(n2)) or
             (is_float(n1) and is_float(n2)) do
    # lcm/b, c/d) = lcm(a, c) / gcd(b, d)
    %{numerator: a, denominator: b} = Ratio.FloatConversion.float_to_rational(n1)
    %{numerator: c, denominator: d} = Ratio.FloatConversion.float_to_rational(n2)
    top = Math.lcm(a, c)
    bottom = Math.gcd(b, d)

    # Would normally return a fraction but its not a core type so lol nah
    top / bottom
  end

  # Alternatively `(c1 * c2) / gcd_complex(c1, c2)`
  def lcm([%Complex{} = n1, n2], _) when is_integer(n2), do: lcm_complex(n1, Complex.new(n2))
  def lcm([n1, %Complex{} = n2], _) when is_integer(n1), do: lcm_complex(Complex.new(n1), n2)
  def lcm([%Complex{} = n1, %Complex{} = n2], _), do: lcm_complex(n1, n2)

  defp lcm_complex(_, _), do: nil

  # ---

  # TODO: bernoulli
end
