defmodule Lixp.Interpreter do
  @moduledoc false
  alias Lixp.Exceptions
  alias Lixp.Interpreter.Builtins

  def run(input) when is_binary(input) do
    input = String.to_charlist(input)
    {:ok, tokens, _} = :lexer.string(input)
    {:ok, ast} = :parser.parse(tokens)

    # TODO: handle multiple root nodes
    [first | _] = ast
    compute_expr(first)
  end

  # TODO: expand to lazily handling special forms
  def compute_expr([:quote | [arg]]), do: arg

  def compute_expr([:quote | [_ | _]]),
    do: raise(Exceptions.ArityError, message: "quote takes exactly one argument")

  # IDK if allowing lists that don't start with an ident if fine, but shrug
  def compute_expr([ident | args]) when is_atom(ident) do
    args = Enum.map(args, &compute_expr/1)

    # TODO: exception for unknown nods
    case ident do
      :+ -> Builtins.add(args)
      :- -> Builtins.sub(args)
      :* -> Builtins.mul(args)
      :/ -> Builtins.div(args)
      :incf -> Builtins.incf(args)
      :list -> args
      :cons -> Builtins.cons(args)
      :append -> Builtins.append(args)
      _ -> raise Exceptions.UnknownFunctionError, message: "undefined function `#{ident}`"
    end
  end

  def compute_expr(node), do: node
end
