defmodule Kamex.Parser do
  @moduledoc false
  alias Kamex.Exceptions

  defp cursed_list_helper(tail) do
    # A stupid helper function to match parentheses nodes. This took me too long
    # to figure out and I really want to find a cleaner solution in the future.
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

  def parse(tokens, in_list \\ false)
  def parse([], true), do: raise(Exceptions.ParserError, message: "unexpected end of input")
  def parse([], false), do: []
  def parse({nil, _}, _), do: []

  def parse({:tack, _, x}, _), do: [:tack, x]
  def parse({:atop, _, funs}, _), do: [:atop | funs]
  def parse({:int, _, int}, _), do: int
  def parse({:float, _, float}, _), do: float
  def parse({:complex, _, {real, im}}, _), do: Complex.new(real, im)
  def parse({:string, _, string}, _), do: string
  def parse({:ident, _, atom}, _), do: atom

  def parse([{:quot, _}, {:"(", _} | tail], in_list) do
    # TODO: add a `Quoted` class to differentiate between syntax lists?
    {list, tail} = cursed_list_helper(tail)
    [[:quote, list] | parse(tail, in_list)]
  end

  def parse([{:quot, _}, {:ident, _, atom} | _], _), do: [:quote, atom]

  # TODO: is there actually restrictions on what can be quoted
  def parse([{:quot, _} | _], _),
    do: raise(Exceptions.ParserError, message: "expected identifier or list after quote")

  def parse([{:")", _} | _], false),
    do: raise(Exceptions.ParserError, message: "unexpected closing parenthesis")

  def parse([{:")", _} | tail], true) do
    [{:eol, tail}]
  end

  def parse([{:"(", _} | tail], in_list) do
    {list, tail} = cursed_list_helper(tail)
    [list | parse(tail, in_list)]
  end

  def parse([{:comment, _} | tail], in_list), do: parse(tail, in_list)

  def parse([{:fork, _}, {:"(", _} | tail], in_list) do
    {list, tail} = cursed_list_helper(tail)
    [[:fork | list] | parse(tail, in_list)]
  end

  def parse([{:bind, _}, {:"(", _} | tail], in_list) do
    {list, tail} = cursed_list_helper(tail)
    [[:bind | list] | parse(tail, in_list)]
  end

  def parse([{:fork, _} | _], _),
    do: raise(Exceptions.ParserError, message: "expected ( after #")

  def parse([{:bind, _} | _], _),
    do: raise(Exceptions.ParserError, message: "expected ( after $")

  def parse([head | tail], in_list) do
    # IO.inspect({in_list, tail})
    [parse(head, in_list) | parse(tail, in_list)]
  end
end
