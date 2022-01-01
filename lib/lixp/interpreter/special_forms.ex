defmodule Lixp.Interpreter.SpecialForms do
  @moduledoc false

  import Lixp.Interpreter, only: [compute_expr: 1]

  @supported [
    quote: 1,
    lambda: 2,
    if: 2,
    if: 3,
    or: :infinity,
    and: :infinity
  ]

  @mapping [
    quote: :quote,
    lambda: :lambda,
    if: :if_,
    or: :or_,
    and: :and_
  ]

  def special_form?(name, arity),
    do: {name, arity} in @supported || Keyword.get(@supported, name) == :infinity

  def run(name, args) do
    is_variable = Keyword.get(@supported, name) == :infinity
    real_fn = Keyword.get(@mapping, name)

    apply(__MODULE__, real_fn, if(is_variable, do: [args], else: args))
  end

  def quote(arg), do: arg

  # def lambda(input_arg, body) do
  # end

  def if_(condition, block, else_block \\ nil) do
    if compute_expr(condition) != [],
      do: compute_expr(block),
      else: compute_expr(else_block)
  end

  # def or_(args)
end
