defmodule Kamex.Interpreter.Builtins.Lists do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2]
  alias Kamex.{Exceptions, Interpreter.Builtins, Util.Comb}

  @tru 1
  @fals 0

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
        cadr: :cadr,
        "str-split": :str_split,
        size: :size,
        any: :any,
        "grade-up": :grade_up,
        "grade-down": :grade_down,
        index: :index,
        at: :at,
        unique: :unique,
        where: :where,
        replicate: :replicate,
        drop: :drop,
        intersperse: :intersperse,
        "unique-mask": :unique_mask,
        prefixes: :prefixes,
        suffixes: :suffixes,
        partition: :partition,
        window: :window,
        range: :range,
        "starts-with": :starts_with,
        keys: :keys,
        "index-of": :index_of,
        in?: :in?,
        "find-seq": :find_seq,
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
  def cadr([[_, head2 | _]], _), do: head2

  def str_split([str, ""], _) when is_binary(str),
    do: str |> String.split("") |> Enum.slice(1..-1)

  def str_split([str, delim], _) when is_binary(str) and is_binary(delim),
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
    do: str |> String.codepoints() |> Enum.uniq() |> Enum.join()

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

  def drop([0, list], _) when is_list(list), do: list
  def drop([n, list], _) when is_list(list) and n < 0, do: list |> Enum.drop(-n)
  def drop([n, list], _) when is_list(list) and n > 0, do: list |> Enum.drop(n)

  def intersperse([l, r], _), do: Enum.zip(l, r) |> Enum.flat_map(fn {x, y} -> [x, y] end)

  # unique mask aka nub sieve.
  # get a boolean vector indicating which first instance of each element in al ist
  def unique_mask([str], _) when is_binary(str), do: unique_mask([String.codepoints(str)], nil)

  def unique_mask([list], _) when is_list(list),
    do:
      Enum.reduce(list, {[], []}, fn curr, {seen, vector} ->
        if curr in seen,
          do: {seen, [@fals | vector]},
          else: {[curr | seen], [@tru | vector]}
      end)
      |> elem(1)
      |> Enum.reverse()

  # (prefixes "example")
  # ["e", "ex", "exa", "exam", "examp", "exampl", "example"]
  def prefixes([str], _) when is_binary(str),
    do: str |> String.codepoints() |> Enum.scan(&(&2 <> &1))

  def prefixes([list], _) when is_list(list),
    do: 1..length(list) |> Enum.map(&Enum.slice(list, 0, &1))

  # inverse of `prefixes`, i.e. starts from the end and works backwards
  # (suffixes "example")
  # ["e", "le", "ple", "mple", "ample", "xample", "example"]
  def suffixes([str], _) when is_binary(str),
    do: str |> String.codepoints() |> Enum.reverse() |> Enum.scan(&(&1 <> &2))

  def suffixes([list], _) when is_list(list) do
    len = length(list)
    1..len |> Enum.map(&Enum.slice(list, -&1, len))
  end

  def partition([vector, str], _) when is_list(vector) and is_binary(str),
    do: partition([vector, String.codepoints(str)], nil) |> Enum.map(&Enum.join/1)

  def partition([vector, list], _)
      when is_list(vector) and is_list(list) and length(vector) == length(list) do
    # TODO: find a more efficient way of detecting boolean vectors
    bool_vector =
      !Enum.find(vector, fn
        1 -> false
        0 -> false
        _ -> true
      end)

    zipped = Enum.zip(vector, list)

    zipped
    |> then(
      &if bool_vector do
        Enum.reduce(&1, {0, [[]]}, fn
          # If current is 0, just return 0 and result
          {0, _}, {_, result} -> {0, result}
          # If current is 1 and previous is 0, start a new string
          {1, curr}, {0, result} -> {1, [[curr] | result]}
          # Otherwise appedn to the current string
          {1, curr}, {1, [curr_list | rest]} -> {1, [[curr | curr_list] | rest]}
        end)
      else
        Enum.reduce(&1, {0, [[]]}, fn
          # Discard any 0s
          {0, _}, acc ->
            acc

          # If the current vector value is smaller or bigger than the current biggest, append to current string.
          {val, curr}, {biggest, [curr_list | rest]} when val <= biggest ->
            {val, [[curr | curr_list] | rest]}

          # Else if it's the new biggest, start a new string.
          {val, curr}, {_, result} ->
            {val, [[curr] | result]}
        end)
      end
    )
    |> elem(1)
    |> Enum.reverse()
    |> Enum.map(&Enum.reverse/1)
    # Remove empty list at the start. Need to figure out why it happens
    |> Enum.slice(1..-1)
  end

  # just a sliding window on a list
  # (window 2 "example")
  # ["ex", "xa", "am", "mp", "pl", "le"]
  def window([size, str], _) when is_binary(str) and size > 0 do
    # TODO: see if there's a more concise way to put this
    size_decf = size - 1
    start = String.slice(str, 0, size_decf)
    rest = String.slice(str, size_decf..-1)

    rest |> String.codepoints() |> Enum.scan(start, &(String.slice(&2, -size_decf, size) <> &1))
  end

  def window([size, list], _) when is_list(list) and size > 0 do
    size_decf = size - 1
    start = Enum.slice(list, 0, size_decf)
    rest = Enum.slice(list, size_decf..-1)

    rest |> Enum.scan(start, &(Enum.slice(&2, -size_decf, size) ++ [&1]))
  end

  # TODO: inner/outer-prod, matrix product it seems
  # https://aplwiki.com/wiki/Inner_Product
  # https://aplwiki.com/wiki/Outer_Product

  # is this inclusive?
  def range([start, stop], _) when is_integer(start) and is_integer(stop), do: start..stop

  def starts_with([prefix, string], _) when is_binary(string) and is_binary(prefix),
    do: if(String.starts_with?(string, prefix), do: @tru, else: @fals)

  def starts_with([prefix, list], _) when is_list(list) and is_list(prefix),
    do: if(List.starts_with?(list, prefix), do: @tru, else: @fals)

  # --> (keys "Mississippi")
  # (("M" (0)) ("i" (1 4 7 10)) ("s" (2 3 5 6)) ("p" (8 9)))
  def keys([str], _) when is_binary(str),
    do: keys([String.codepoints(str)], nil)

  def keys([list], _) when is_list(list),
    do:
      list
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {v, i}, map -> Map.put(map, v, [i | Map.get(map, v, [])]) end)
      |> Enum.map(fn {k, v} -> [k, Enum.reverse(v)] end)

  def index_of([to_check, str], _) when is_binary(to_check) and is_binary(str),
    do: index_of([String.codepoints(to_check), String.codepoints(str)], nil)

  def index_of([to_check, list], _) when is_list(to_check) and is_list(list),
    do: Enum.map(to_check, fn x -> Enum.find_index(list, x) end)

  # ucs - turn unicode chars to ints and vice versa

  def in?([needle, haystack]) when is_binary(needle) and is_binary(haystack),
    do: if(String.contains?(haystack, needle), do: @tru, else: @fals)

  def in?([needle, haystack]) when is_list(haystack),
    do: if(needle in haystack, do: @tru, else: @fals)

  def find_seq([needle, haystack], _) when is_binary(needle) and is_binary(haystack),
    do: in?([needle, haystack])

  def find_seq([needle, haystack], _) when is_list(needle) and is_list(haystack),
    do: if(Kamex.Util.sublist?(haystack, needle), do: @tru, else: @fals)

  def shuffle([list], _) when is_list(list), do: Enum.shuffle(list)

  # str-explode, str-join
end
