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
        where: :where,
        replicate: :replicate,
        intersperse: :intersperse,
        prefixes: :prefixes,
        suffixes: :suffixes,
        window: :window,
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
  # ⍸1 0 1 0 3 1
  # 1 3 5 5 5 6
  def where([vector], _),
    do:
      vector
      |> Stream.with_index()
      |> Stream.map(fn {x, i} ->
        case x do
          0 -> 0
          1 -> i
          _ -> List.duplicate(i, x)
        end
      end)
      |> Enum.into([])
      |> List.flatten()

  # replicate: apply a bool vector mask to an list, repeat like `where` if > 1
  # 0 1 0 1/2 3 4 5
  # 3 5
  def replicate([times, list], _) when is_integer(times) and is_list(list),
    do: replicate([List.duplicate(times, length(list)), list], nil)

  def replicate([mask, list], _) when is_list(mask) and is_list(list),
    do:
      Enum.zip(mask, list)
      |> Enum.filter(fn {m, _} -> m != 0 end)
      |> Enum.map(fn {times, item} -> List.duplicate(item, times) end)
      |> Enum.into([])
      |> List.flatten()

  def intersperse([l, r], _), do: Enum.zip(l, r) |> Enum.flat_map(fn {x, y} -> [x, y] end)

  # (,¨,\)'example'
  # ┌─┬──┬───┬────┬─────┬──────┬───────┐
  # │e│ex│exa│exam│examp│exampl│example│
  # └─┴──┴───┴────┴─────┴──────┴───────┘

  def prefixes([str], _) when is_binary(str),
    do: str |> String.graphemes() |> Enum.scan(&(&2 <> &1))

  def prefixes([list], _) when is_list(list),
    do: 1..length(list) |> Enum.map(&Enum.slice(list, 0, &1))

  # inverse of `prefixes`, i.e. starts from the end and works backwards
  # ┌─┬──┬───┬────┬─────┬──────┬───────┐
  # │e│le│ple│mple│ample│xample│example│
  # └─┴──┴───┴────┴─────┴──────┴───────┘
  def suffixes([str], _) when is_binary(str),
    do: str |> String.graphemes() |> Enum.reverse() |> Enum.scan(&(&1 <> &2))

  def suffixes([list], _) when is_list(list) do
    len = length(list)
    1..len |> Enum.map(&Enum.slice(list, -&1, len))
  end

  # just a sliding window on a list
  # (window 2 "example")
  # ┌──┬──┬──┬──┬──┬──┐
  # │ex│xa│am│mp│pl│le│
  # └──┴──┴──┴──┴──┴──┘
  def window([size, str], _) when is_binary(str) and size > 0 do
    # TODO: see if there's a more concise way to put this
    size_decf = size - 1
    start = String.slice(str, 0, size_decf)
    rest = String.slice(str, size_decf, String.length(str))

    rest |> String.graphemes() |> Enum.scan(start, &(String.slice(&2, -size_decf, size) <> &1))
  end

  def window([size, list], _) when is_list(list) and size > 0 do
    size_decf = size - 1
    start = Enum.slice(list, 0, size_decf)
    rest = Enum.slice(list, size_decf, length(list))

    rest |> Enum.scan(start, &(Enum.slice(&2, -size_decf, size) ++ [&1]))
  end

  def shuffle([list], _) when is_list(list), do: Enum.shuffle(list)
end
