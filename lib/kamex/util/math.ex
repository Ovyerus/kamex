defmodule Kamex.Util.Math do
  @moduledoc false

  use Bitwise
  alias Kamex.Exceptions

  @inverse_e -0.36787944118
  @e1 Math.exp(1)

  # Compute the nth bernoulli number
  def bernoulli(n) when is_integer(n) do
    # TODO: cache and optimise
    if n > 2 && rem(n, 2) == 1 do
      # Shortcut as only B_1 and N_2n are of interest
      Ratio.new(0)
    else
      # TODO: lists instead of tuples
      Stream.transform(0..n, {}, fn m, acc ->
        acc = Tuple.append(acc, Ratio.new(1, m + 1))

        # credo:disable-for-next-line
        cond do
          # TODO: figure out a shortcut when computing
          # m > 2 && rem(m, 2) == 1 ->
          #   acc = Tuple.insert_at(acc, 0, Ratio.new(0))
          #   {[Ratio.new(0)], acc}

          m > 0 ->
            new =
              Enum.reduce(m..1, acc, fn j, acc ->
                put_elem(
                  acc,
                  j - 1,
                  Ratio.mult(Ratio.new(j), Ratio.sub(elem(acc, j - 1), elem(acc, j)))
                )
              end)

            {[elem(new, 0)], new}

          true ->
            {[elem(acc, 0)], acc}
        end
      end)
      |> Enum.to_list()
      |> List.last()
    end
  end

  # ---

  # TODO: flip arg names around to match wiki?
  def jacobi(_, k) when k <= 0 or (k &&& 1) == 0,
    do:
      raise(Exceptions.MathError,
        message: "cannot compute jacobi for k <= 0 or k is even"
      )

  def jacobi(n, k) when n < 0 do
    j = ja(-n, k)

    case k &&& 3 do
      1 -> j
      3 -> -j
    end
  end

  def jacobi(n, k) when is_integer(n) and is_integer(k), do: ja(rem(n, k), k)

  defp ja(0, _), do: 0
  defp ja(1, _), do: 1
  defp ja(n, k) when n >= k, do: ja(rem(n, k), k)

  defp ja(n, k) when (n &&& k) == 0 do
    j = ja(n >>> 1, k)

    case k &&& 7 do
      1 -> j
      3 -> -j
      5 -> -j
      7 -> j
    end
  end

  defp ja(n, k) do
    j = ja(k, n)

    if (n &&& 3) == 3 and (k &&& 3) == 3,
      do: -j,
      else: j
  end

  # ---

  def lambert_w(x) when x < @inverse_e,
    do: raise(Exceptions.MathError, message: "cannot compute lambert w for x < -1/e")

  # Can't log 0, so shortcut to return 0
  def lambert_w(0), do: 0

  # TODO: replace floats everywhere with decimals
  def lambert_w(x) do
    w =
      cond do
        x < 0.06 && x * 2 * @e1 + 2 <= 0 ->
          -1

        x < 0.06 ->
          ti = x * 2 * @e1 + 2
          t = Ratio.new(Math.sqrt(ti))
          tsq = Ratio.mult(t, t)

          Ratio.new(-1)
          |> Ratio.add(Ratio.mult(t, Ratio.new(1, 6)))
          |> Ratio.add(Ratio.mult(tsq, Ratio.new(257, 720)))
          |> Ratio.add(tsq |> Ratio.mult(t) |> Ratio.mult(Ratio.new(13, 720)))
          |> Ratio.div(
            Ratio.new(1)
            |> Ratio.add(Ratio.mult(t, Ratio.new(5, 6)))
            |> Ratio.add(Ratio.mult(tsq, Ratio.new(103, 720)))
          )
          |> Ratio.to_float()

        x < 1.363 ->
          l1 = Math.log(x + 1)
          l1 * ((1 - Math.log(l1 + 1)) / (l1 + 2))

        x < 3.7 ->
          l1 = Math.log(x)
          l2 = Math.log(l1)

          l1 - l2 - Math.log((l2 / l1 - 1) / 2)

        true ->
          l1 = Math.log(x)
          l2 = Math.log(l1)

          d1 = 2 * l1 * l1
          d2 = 3 * l1 * d1
          d3 = 2 * l1 * d2
          d4 = 5 * l1 * d3

          (l1 - l2)
          |> then(&(&1 + l2 / l1))
          |> then(&(&1 + l2 * (l2 - 2) / d1))
          |> then(&(&1 + l2 * (6 + l2 * (-9 + 2 * l2)) / d2))
          |> then(&(&1 + l2 * (-12 + l2 * (36 + l2 * (-22 + 3 * l2))) / d3))
          |> then(&(&1 + l2 * (60 + l2 * (-360 + l2 * (350 + l2 * (-125 + 12 * l2)))) / d4))
      end

    if w == -1 do
      w
    else
      tol = 1.0e-16

      Enum.reduce_while(1..200, w, fn _, v ->
        if v == 0 do
          {:halt, v}
        else
          w1 = v + 1
          zn = Math.log(x / v) - v
          qn = w1 * 2 * (w1 + 2 * (zn / 3))
          en = zn / w1 * (qn - zn) / (qn - zn * 2)
          wen = v * en
          v = v + wen

          if abs(wen) < tol, do: {:halt, v}, else: {:cont, v}
        end
      end)
    end
  end

  def norm_complex(%Complex{} = x) do
    y = Math.sqrt(x.re ** 2 + x.im ** 2)
    Complex.div(x, Complex.new(y))
  end

  # TODO: make sure that this comparison actually works properly
  def min_complex(%Complex{} = a, %Complex{} = b) do
    if a < b, do: a, else: b
  end

  def max_complex(%Complex{} = a, %Complex{} = b) do
    if a > b, do: a, else: b
  end
end
