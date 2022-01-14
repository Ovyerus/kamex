defmodule Kamex.Parser do
  @moduledoc false
  alias Kamex.Exceptions

  defp cursed_list_helper(tail) do
    # A stupid helper function to match parentheses nodes. This took me too long
    # to figure out and I really want to find a cleaner solution in the future.
    # TODO: given we now have the second var, we can probably move this to a normal parse function
    case Enum.split_while(parse(tail, true), fn
           {:eol, _} -> false
           _ -> true
         end) do
      {list, [{:eol, tail}]} ->
        {list, tail}

      x ->
        IO.inspect(x)
        raise Exceptions.ParserError, message: "if this error occurs, god help you"
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

  def parse(tokens, in_list \\ false)
  def parse([], true), do: raise(Exceptions.ParserError, message: "unexpected end of input")
  def parse([], false), do: []
  def parse({nil, _}, _), do: []

  def parse({:tack, _, x}, _), do: [:tack, x]
  def parse({:atop, _}, _), do: raise(Exceptions.ParserError, message: "unexpected `@` (atop)")
  def parse({:int, _, int}, _), do: int
  def parse({:float, _, float}, _), do: float
  def parse({:complex, _, {real, im}}, _), do: Complex.new(real, im)
  def parse({:string, _, string}, _), do: string
  def parse({:ident, _, atom}, _), do: atom

  def parse([{:quot, _}, {:"(", _} | tail], in_list) do
    # TODO: add a `Quoted` class to differentiate between syntax lists?
    # TODO: need to not parse inside here?
    {list, tail} = cursed_list_helper(tail)
    [[:quote, list] | parse(tail, in_list)]
  end

  def parse([{:quot, _}, {:ident, _, atom} | _], _), do: [:quote, atom]

  # TODO: is there actually restrictions on what can be quoted
  def parse([{:quot, _} | _], _),
    do: raise(Exceptions.ParserError, message: "expected identifier or list after quote")

  def parse([{:comment, _} | tail], in_list), do: parse(tail, in_list)

  def parse([{:fork, _}, {:"(", _} | tail], in_list) do
    {list, tail} = cursed_list_helper(tail)
    [[:fork | list] | parse(tail, in_list)]
  end

  def parse([{:bind, _}, {:"(", _} | tail], in_list) do
    {list, tail} = cursed_list_helper(tail)

    case tail do
      [{:atop, _} | tail] ->
        {atop_chunk, tail} = cursed_atop_helper([:bind | list], tail)
        [atop_chunk | parse(tail, in_list)]

      _ ->
        [[:bind | list] | parse(tail, in_list)]
    end
  end

  def parse([{:fork, _} | _], _),
    do: raise(Exceptions.ParserError, message: "expected ( after #")

  def parse([{:bind, _} | _], _),
    do: raise(Exceptions.ParserError, message: "expected ( after $")

  def parse([{:map, _} | list], in_list), do: [:bind, :map | parse(list, in_list)]

  def parse([{:partition, line} | tail], in_list) do
    # TODO: this currently doesnt work if its at the root level of the syntax. What do we do?
    {list, tail} = cursed_list_helper(tail)
    # Re-add the parenthesis we consumed, to emulate adding one that didn't exist.
    [list | parse([{:")", line} | tail], in_list)]
  end

  def parse([{:")", _} | _], false),
    do: raise(Exceptions.ParserError, message: "unexpected closing parenthesis")

  def parse([{:")", _} | tail], true) do
    [{:eol, tail}]
  end

  def parse([{:"(", _} | tail], in_list) do
    {list, tail} = cursed_list_helper(tail)
    [list | parse(tail, in_list)]
  end

  def parse([{:ident, _, atom}, {:atop, _} | tail], in_list) do
    {atop_chunk, tail} = cursed_atop_helper(atom, tail)
    [atop_chunk | parse(tail, in_list)]
  end

  def parse([head | tail], in_list), do: [parse(head, in_list) | parse(tail, in_list)]
end
