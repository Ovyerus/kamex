defmodule Lixp.Interpreter do
  @moduledoc false
  alias Lixp.Exceptions
  alias Lixp.Interpreter.{Builtins, SpecialForms}

  def to_ast(input) when is_binary(input) do
    with input <- String.to_charlist(input),
         {:ok, tokens, _} <- :lexer.string(input),
         :ok <- check_tokens(tokens) do
      :parser.parse(tokens)
    end
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

  defp check_tokens(tokens) do
    {lcount, rcount} =
      Enum.reduce(tokens, {0, 0}, fn
        {:"(", _}, {lcount, rcount} -> {lcount + 1, rcount}
        {:")", _}, {lcount, rcount} -> {lcount, rcount + 1}
        _, acc -> acc
      end)

    parens_balance = lcount - rcount

    # TODO: modify lexer to give column count, and enrich info here
    cond do
      parens_balance > 0 ->
        raise Exceptions.UnbalancedParensError, message: "Missing one or more closing parentheses"

      parens_balance < 0 ->
        raise Exceptions.UnbalancedParensError, message: "Missing one or more opening parentheses"

      true ->
        :ok
    end
  end
end
