defmodule Kamex.Interpreter.Builtins.Lists do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2]
  alias Kamex.{Exceptions, Interpreter.Builtins, Util.Comb}

  defmacro supported do
    quote do
      [
        iota: :iota,
        tie: :tie,
        flatten: :flatten,
        reverse: :reverse,
        rotate: :rotate,
        zip: :zip,
        first: :first,
        "first-idx": :first_idx,
        cons: :cons,
        append: :append,
        car: :car,
        cdr: :cdr,
        size: :size,
        any: :any,
        "grade-up": :grade_up,
        "grade-down": :grade_down,
        index: :index,
        at: :at,
        unique: :unique,
        shuffle: :shuffle
      ]
    end
  end

  # TODO: fix stuff involving lists so that we can lazy this and make big iotas nicer to work with?
  def iota([x], _) when is_integer(x), do: 0..(x - 1) |> Enum.into([])

  def iota([x], _) when is_list(x) do
    iotas =
      Enum.map(x, fn
        n when is_integer(n) -> iota([n], nil)
        _ -> raise Exceptions.IllegalTypeError, message: "iota: expected a list of integers"
      end)

    # TODO: move the post processing to cart_prod
    iotas
    |> Enum.reduce(&Comb.cart_product([&1, &2]))
    |> Enum.map(fn x -> x |> List.flatten() |> Enum.reverse() end)
  end

  def tie(args, _), do: args

  def flatten([list], _) when is_list(list), do: List.flatten(list)

  def reverse([str], _) when is_binary(str), do: String.reverse(str)
  def reverse([list], _) when is_list(list), do: Enum.reverse(list)

  # Cycle items through the list n times, kinda like bitshift but wrapping around
  # (rotate 3 '(1 2 3 4 5 6 7 8 9))
  # -> '(4 5 6 7 8 9 1 2 3)
  def rotate([0, list], _) when is_list(list), do: list

  def rotate([n, list], _) when abs(n) > length(list),
    do: rotate([rem(n, length(list)), list], nil)

  def rotate([n, list], _) when is_list(list) do
    {back, front} = Enum.split(list, n)
    front ++ back
  end

  def zip([x, y], _) when is_list(x) and is_list(y), do: Enum.zip(x, y)

  def first([fun, list], locals) when is_list(list),
    do:
      Enum.find(list, fn item -> Builtins.not_([compute_expr([fun, item], locals)], nil) == 0 end)

  def first_idx([fun, list], locals) when is_list(list),
    do:
      list
      |> Enum.with_index()
      |> Enum.find({nil, nil}, fn {item, _} ->
        Builtins.not_([compute_expr([fun, item], locals)], nil) == 0
      end)
      |> elem(1)

  def cons([head, tail], _) when is_list(tail), do: [head | tail]

  def cons([_head, _tail], _),
    do: raise(Exceptions.IllegalTypeError, message: "cons: second argument must be a list")

  # TOO: better error for when first arg is non list/check to make sure all items is a list (how without iterating through all items?)
  def append(lists, _), do: Enum.reduce(lists, [], fn x, acc -> acc ++ x end)

  def car([[head | _]], _), do: head
  def cdr([[_ | tail]], _), do: tail

  def str_spilt([str, delim], _) when is_binary(str) and is_binary(delim),
    do: String.split(str, delim)

  def size([str], _) when is_binary(str), do: String.length(str)
  def size([list], _) when is_list(list), do: length(list)

  def any([fun, list], locals) when is_list(list),
    do:
      Enum.any?(list, fn item -> Builtins.not_([compute_expr([fun, item], locals)], nil) == 0 end)

  # TODO: sort

  # Return a list of indicies which when followed, result in a sorted list.
  def grade_up([list], _) when is_list(list),
    do:
      list
      |> Enum.with_index()
      |> Enum.sort(fn {x, _}, {y, _} -> x < y end)
      |> Enum.map(&elem(&1, 1))

  def grade_up([fun, list], locals) when is_list(list),
    do:
      list
      |> Enum.with_index()
      |> Enum.sort(fn {x, _}, {y, _} ->
        Builtins.not_([compute_expr([fun, x, y], locals)], nil) == 0
      end)
      |> Enum.map(&elem(&1, 1))

  def grade_down([list], _) when is_list(list), do: grade_up([list], nil) |> Enum.reverse()

  def grade_down([fun, list], locals) when is_list(list),
    do: grade_up([fun, list], locals) |> Enum.reverse()

  def index([indices, list], _) when is_list(indices) and is_list(list),
    # TODO: handle out of bound indices?
    do: Enum.map(indices, fn i -> Enum.at(list, i) end)

  # '*'@(2∘|) 1 2 3 4 5
  # * 2 * 4 *
  def at([transform, indices, list], locals) when is_list(indices) and is_list(list),
    # TODO: check list is all numbers
    do:
      list
      |> Enum.with_index()
      |> Enum.map(fn {item, i} ->
        if i in indices,
          do: compute_expr([transform, item], locals),
          else: item
      end)

  def at([transform, pred, list], locals) when is_list(list),
    do:
      Enum.map(list, fn item ->
        pick_it = Builtins.not_([compute_expr([pred, item], locals)], nil) == 0

        if pick_it,
          do: compute_expr([transform, item], locals),
          else: item
      end)

  def unique([str], _) when is_binary(str),
    do: str |> String.graphemes() |> Enum.uniq() |> Enum.join()

  def unique([list], _) when is_list(list), do: Enum.uniq(list)

  # where: indicies of true items in a bool vector, > 1 returns indice n times
  # replicate: apply a bool vector mask to an list

  def shuffle([list], _) when is_list(list), do: Enum.shuffle(list)
end
