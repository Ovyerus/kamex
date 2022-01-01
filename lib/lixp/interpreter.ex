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

  def compute_expr(node, locals \\ %{})

  def compute_expr([ident | args], locals) when is_atom(ident) do
    arg_len = length(args)

    # TODO: need to do unwrapping so that we don't end up with random {value, locals} tuples in the middle of the result

    cond do
      SpecialForms.special_form?(ident, arg_len) -> SpecialForms.run(ident, args, locals)
      Builtins.builtin?(ident, arg_len) -> Builtins.run(ident, args, locals)
      true -> raise Exceptions.UnknownFunctionError, message: "undefined function `#{ident}`"
    end
  end

  def compute_expr([head | tail], locals) do
    {head_result, locals} = compute_expr(head, locals)

    cond do
      is_function(head_result) -> head_result.(tail)
      is_atom(head_result) -> compute_expr([head_result | tail], locals)
      true -> [head_result | compute_expr(tail, locals)]
    end
  end

  def compute_expr(ident, locals) when is_atom(ident) do
    found = Map.get(locals, ident, :__not_found)

    if found === :__not_found do
      raise Exceptions.UnknownLocalError, message: "unknown local `#{ident}`"
    end

    found
  end

  def compute_expr(node, _locals), do: node

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
        raise Exceptions.UnbalancedParensError, message: "missing one or more closing parentheses"

      parens_balance < 0 ->
        raise Exceptions.UnbalancedParensError, message: "missing one or more opening parentheses"

      true ->
        :ok
    end
  end
end
