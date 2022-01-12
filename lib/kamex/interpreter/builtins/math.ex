defmodule Kamex.Interpreter.Builtins.Math do
  @moduledoc false
  alias Kamex.Exceptions
  alias Kamex.Util.Math, as: Kamath

  @tru 1
  @fals 0
  # @falsey [[], @fals]

  # Go home diaz ur drunk
  @dialyzer {:nowarn_function, nth_root: 2}

  defmacro supported do
    quote do
      %{
        +: :add,
        -: :subtract,
        *: :multiply,
        /: :divide,
        "//": :divide_int,
        %: :modulo,
        sqrt: :sqrt,
        "nth-root": :nth_root,
        **: :power,
        =: :equals,
        "/=": :not_equals,
        <: :less_than,
        >: :greater_than,
        <=: :less_than_or_equal,
        >=: :greater_than_or_equal,
        ceil: :ceiling,
        floor: :floor,
        gcd: :gcd,
        lcm: :lcm,
        bernoulli: :bernoulli,
        digamma: :digamma,
        "lambert-w0": :lambert_w0,
        "jacobi-sym": :jacobi_sym,
        exp: :exp,
        "even-f": :even_f,
        "odd-f": :odd_f,
        odd?: :odd,
        even?: :even,
        min: :min,
        max: :max,
        "hamming-weight": :hamming_weight,
        re: :re,
        im: :im,
        phasor: :phasor,
        "as-complex": :as_complex,
        "as-real": :as_real
      }
    end
  end

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
  def modulo([%Complex{} = x], _), do: Complex.sqrt(Kamath.norm_complex(x))
  def modulo([a, b], _) when is_integer(a) and is_integer(b), do: rem(a, b)

  def sqrt([x], _) when is_number(x), do: Math.sqrt(x)

  def sqrt([%Complex{im: 0, re: re}], _) when re < 0,
    do: raise(Exceptions.MathError, message: "sqrt: im=0 re<0 doesn't exist")

  # TODO: pala's impl is different, compare
  def sqrt([%Complex{} = x], _), do: Complex.sqrt(x)

  # ---

  def nth_root([_, exp], _) when not is_number(exp),
    do: raise(Exceptions.IllegalTypeError, message: "nth_root: exponent must be a real number")

  # TODO: need to convert to int, which way does kami round?
  def nth_root([x, exp], _) when is_integer(x), do: trunc(x ** (1 / exp))
  def nth_root([x, exp], _) when is_float(x), do: x ** (1 / exp)

  def nth_root([%Complex{} = x, exp], _),
    do: Complex.pow(x, Complex.new(1 / exp))

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

  def gcd([%Complex{} = n1, n2], _) when is_integer(n2),
    do: Kamath.gcd_complex(n1, Complex.new(n2))

  def gcd([n1, %Complex{} = n2], _) when is_integer(n1),
    do: Kamath.gcd_complex(Complex.new(n1), n2)

  def gcd([%Complex{} = n1, %Complex{} = n2], _), do: Kamath.gcd_complex(n1, n2)

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
  def lcm([%Complex{} = n1, n2], _) when is_integer(n2),
    do: Kamath.lcm_complex(n1, Complex.new(n2))

  def lcm([n1, %Complex{} = n2], _) when is_integer(n1),
    do: Kamath.lcm_complex(Complex.new(n1), n2)

  def lcm([%Complex{} = n1, %Complex{} = n2], _), do: Kamath.lcm_complex(n1, n2)

  # ---

  def bernoulli([x], _) when is_integer(x), do: Kamath.bernoulli(x)

  def digamma([x], _) when is_number(x), do: digamma([Complex.new(x)], nil)

  def digamma([%Complex{} = x], nil) do
    # phi(z) = ln(z) - 1/2z
    z = Complex.sub(Complex.ln(x), Complex.div(Complex.new(1), Complex.mult(2, x)))
    if z.im != 0, do: z, else: z.re
  end

  def lambert_w0([x], _) when is_number(x), do: Kamath.lambert_w(x)
  def lambert_w0([%Complex{re: x}], _), do: Kamath.lambert_w(x)

  def jacobi_sym([n, k], _) when is_integer(n) and is_integer(k), do: Kamath.jacobi(n, k)

  # ---

  def exp([x], _) when is_number(x), do: Math.exp(x)
  def exp([%Complex{} = x], _), do: Complex.exp(x)

  def even_f([x], _) when is_number(x), do: x * 2
  def odd_f([x], _) when is_number(x), do: x * 2 + 1

  def odd([x], _) when is_integer(x), do: if(rem(x, 2) == 1, do: @tru, else: @fals)
  def even([x], _) when is_integer(x), do: if(rem(x, 2) == 0, do: @tru, else: @fals)

  # min/max
  def min_([a, b], _) when is_number(a) and is_number(b), do: min(a, b)
  def min_([%Complex{} = a, %Complex{} = b], _), do: Kamath.min_complex(a, b)
  def min_([%Complex{} = a, b], _) when is_number(b), do: Kamath.min_complex(a, Complex.new(b))
  def min_([a, %Complex{} = b], _) when is_number(a), do: Kamath.min_complex(Complex.new(a), b)

  def max_([a, b], _) when is_number(a) and is_number(b), do: max(a, b)
  def max_([%Complex{} = a, %Complex{} = b], _), do: Kamath.max_complex(a, b)
  def max_([%Complex{} = a, b], _) when is_number(b), do: Kamath.max_complex(a, Complex.new(b))
  def max_([a, %Complex{} = b], _) when is_number(a), do: Kamath.max_complex(Complex.new(a), b)

  def hamming_weight([x]) when is_integer(x) and x >= 0, do: Kamath.hamming_weight(x)

  def re([x], _) when is_number(x), do: x
  def re([%Complex{re: re}], _), do: re

  def im([x], _) when is_number(x), do: 0
  def im([%Complex{im: im}], _), do: im

  def phasor([x], _) when is_number(x), do: 0
  def phasor([%Complex{re: re, im: im}], _), do: Math.atan2(im, re)

  def as_complex([x], _) when is_number(x), do: Complex.new(x)
  def as_complex([%Complex{} = x], _), do: x

  def as_real([x], _) when is_number(x), do: x
  def as_real([%Complex{re: re}], _), do: re
end
