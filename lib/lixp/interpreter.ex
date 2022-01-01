defmodule Lixp.Interpreter do
  @moduledoc false
  alias Lixp.Exceptions
  alias Lixp.Interpreter.{Builtins, SpecialForms}

  def to_ast(input) when is_binary(input) do
    input = String.to_charlist(input)
    {:ok, tokens, _} = :lexer.string(input)
    :parser.parse(tokens)
  end

  def run(input) when is_binary(input) do
    {:ok, ast} = to_ast(input)

    # TODO: handle multiple root nodes
    [first | _] = ast
    compute_expr(first)
  end

  # IDK if allowing lists that don't start with an ident if fine, but shrug
  def compute_expr([ident | args]) when is_atom(ident) do
    if SpecialForms.special_form?(ident, length(args)) do
      SpecialForms.run(ident, args)
    else
      args = Enum.map(args, &compute_expr/1)

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
  end

  def compute_expr(node), do: node
end
