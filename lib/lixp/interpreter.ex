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
    arg_len = length(args)

    cond do
      SpecialForms.special_form?(ident, arg_len) -> SpecialForms.run(ident, args)
      Builtins.builtin?(ident, arg_len) -> Builtins.run(ident, args)
      true -> raise Exceptions.UnknownFunctionError, message: "undefined function `#{ident}`"
    end
  end

  def compute_expr(node), do: node
end
