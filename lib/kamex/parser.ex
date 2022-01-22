defmodule Kamex.Parser do
  @moduledoc false
  alias Kamex.Exceptions

  defp cursed_list_helper(tail, do_parse \\ true) do
    # Last item exists to determine if we halted naturally reduce_while ended as
    # a result. Not sure if that's needed or could get caught by this first
    # clause here, will need to do some testing
    result =
      Enum.reduce_while(tail, {[], tail, true}, fn
        _, {_, [], _} ->
          raise Exceptions.ParserError, message: "unexpected end of input"

        _, {list, [{:"(", _} = a | tail], _} ->
          {new_list, tail} = cursed_list_helper(tail, false)

          # TODO: find last item and use that line number for closing (actually its probably the first one, do research dummy)
          {:cont, {[{:")", 999} | new_list] ++ [a | list], tail, true}}

        _, {list, [{:")", _} | tail], _} ->
          {:halt, {list, tail}}

        _, {list, [head | tail], _} ->
          {:cont, {[head | list], tail, true}}
      end)

    case result do
      {list, tail} ->
        list = if(do_parse, do: list |> Enum.reverse() |> parse(), else: list)
        {list, tail}

      _ ->
        raise(Exceptions.ParserError, message: "unexpected end of input")
    end
  end

  defp cursed_atop_helper(init, tail) do
    # Start chunk reverse so we can prepend to it easily
    {chunk, _, tail} =
      Enum.reduce_while(tail, {[init, :atop], :atop, tail}, fn
        #  if last was atop and this atop, err, last atop and ident or bind, cont, otherwise end if not atop
        _, {_chunk, :atop, [{:atop, _} | _]} ->
          raise Exceptions.ParserError,
            message:
              "unexpected duplicate `@`. Multiple `@` must be separated by an identifier or bind"

        _, {chunk, :atop, [{:ident, _, _} = token | tail]} ->
          ident = parse(token)
          {:cont, {[ident | chunk], :ident, tail}}

        _, {chunk, :atop, [{:bind, _}, {:"(", _} | tail]} ->
          {list, tail} = cursed_list_helper(tail)
          {:cont, {[[:bind | list] | chunk], :bind, tail}}

        _, {_chunk, :atop, [{:bind, _} | _]} ->
          raise Exceptions.ParserError,
            message: "expected ( after $"

        _, {_chunk, :atop, [_ | _]} ->
          raise Exceptions.ParserError,
            message: "expected identifier or bind after `@` (atop)"

        # just push atop to prev
        _, {chunk, _prev, [{:atop, _} | tail]} ->
          {:cont, {chunk, :atop, tail}}

        _, {_chunk, prev, _tail} = acc when prev == :ident or prev == :bind ->
          {:halt, acc}
      end)

    chunk = Enum.reverse(chunk)
    {chunk, tail}
  end

  def parse(tokens)
  # def parse([]), do: raise(Exceptions.ParserError, message: "unexpected end of input")
  def parse([]), do: []
  def parse({nil, _}), do: []

  def parse({:tack, _, x}), do: [:tack, x]
  def parse({:atop, _}), do: raise(Exceptions.ParserError, message: "unexpected `@` (atop)")
  def parse({:int, _, int}), do: int
  def parse({:float, _, float}), do: float
  def parse({:complex, _, {real, im}}), do: Complex.new(real, im)
  def parse({:string, _, string}), do: string
  def parse({:ident, _, atom}), do: atom

  def parse([{:quot, _}, {:"(", _} | tail]) do
    # TODO: add a `Quoted` class to differentiate between syntax lists?
    # TODO: need to not parse inside here?
    {list, tail} = cursed_list_helper(tail)
    [[:quote, list] | parse(tail)]
  end

  def parse([{:quot, _}, {:ident, _, atom} | tail]),
    do: [[:quote, atom] | parse(tail)]

  # TODO: is there actually restrictions on what can be quoted
  def parse([{:quot, _} | _]),
    do: raise(Exceptions.ParserError, message: "expected identifier or list after quote")

  def parse([{:comment, _} | tail]), do: parse(tail)

  def parse([{:fork, _}, {:"(", _} | tail]) do
    {list, tail} = cursed_list_helper(tail)
    [[:fork | list] | parse(tail)]
  end

  def parse([{:bind, _}, {:"(", _} | tail]) do
    {list, tail} = cursed_list_helper(tail)

    case tail do
      [{:atop, _} | tail] ->
        {atop_chunk, tail} = cursed_atop_helper([:bind | list], tail)
        [atop_chunk | parse(tail)]

      _ ->
        [[:bind | list] | parse(tail)]
    end
  end

  def parse([{:fork, _} | _]),
    do: raise(Exceptions.ParserError, message: "expected ( after #")

  def parse([{:bind, _} | _]),
    do: raise(Exceptions.ParserError, message: "expected ( after $")

  def parse([{:map, _} | list]), do: [:bind, :map | [parse(list)]]

  def parse([{:partition, line} | tail]) do
    # TODO: this currently doesnt work if its at the root level of the syntax. What do we do?
    {list, tail} = cursed_list_helper(tail)
    # Re-add the parenthesis we consumed, to emulate adding one that didn't exist.
    [list | parse([{:")", line} | tail])]
  end

  def parse([{:")", _} | _]),
    do: raise(Exceptions.ParserError, message: "unexpected closing parenthesis")

  def parse([{:"(", _} | tail]) do
    {list, tail} = cursed_list_helper(tail)
    [list | parse(tail)]
  end

  def parse([{:ident, _, atom}, {:atop, _} | tail]) do
    {atop_chunk, tail} = cursed_atop_helper(atom, tail)
    [atop_chunk | parse(tail)]
  end

  def parse([head | tail]), do: [parse(head) | parse(tail)]
end
