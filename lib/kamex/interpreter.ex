defmodule Kamex.Interpreter do
  @moduledoc false
  alias Kamex.{Exceptions, Parser}
  alias Kamex.Interpreter.{Builtins, SpecialForms}

  # TODO: redo stuff to revolve around true/false instead of empty lists lol

  def to_ast(input) when is_binary(input) do
    with input <- String.to_charlist(input),
         {:ok, tokens, _} <- :lexer.string(input),
         :ok <- check_tokens(tokens) do
      Parser.parse(tokens)
    end
  end

  def run(input, locals \\ %{}) when is_binary(input) do
    ast = to_ast(input)

    # TODO: store env/locals in an Agent?
    Enum.reduce(
      ast,
      {nil, locals},
      fn node, {_, locals} ->
        compute_expr(node, locals, true)
      end
    )
  end

  def compute_expr(node, locals \\ %{}, ret_locals \\ false)

  def compute_expr([ident | args], locals, ret_locals) when is_atom(ident) do
    # TODO: completely redo locals returning, and add globals alongside I think

    {result, locals} =
      cond do
        SpecialForms.special_form?(ident) ->
          SpecialForms.run(ident, args, locals)

        Builtins.builtin?(ident) ->
          Builtins.run(ident, args, locals)

        is_function(locals[ident]) ->
          args = Enum.map(args, &compute_expr(&1, locals))
          {locals[ident].(args, locals), locals}

        true ->
          raise Exceptions.UnknownFunctionError,
            message: "undefined function `#{ident}`"
      end

    if ret_locals,
      do: {result, locals},
      else: result
  end

  def compute_expr([head | tail], locals, _ret_locals) do
    {head_result, locals} = compute_expr(head, locals, true)

    cond do
      is_function(head_result) -> head_result.(Enum.map(tail, &compute_expr(&1, locals)), locals)
      is_atom(head_result) -> compute_expr([head_result | tail], locals, true)
      true -> [head_result | compute_expr(tail, locals, true)]
    end
  end

  def compute_expr(ident, locals, _ret_locals) when is_atom(ident) do
    found = Map.get(locals, ident)

    if !found do
      raise Exceptions.UnknownLocalError, message: "unknown local `#{ident}`"
    end

    found
  end

  def compute_expr(node, locals, true), do: {node, locals}
  def compute_expr(node, _locals, _ret_locals), do: node

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
