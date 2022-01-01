defmodule Lixp.Interpreter.SpecialForms do
  @moduledoc false

  import Lixp.Interpreter, only: [compute_expr: 2, compute_expr: 3]
  alias Lixp.Exceptions

  @supported [
    quote: 1,
    lambda: 2,
    def: 2,
    defun: 3,
    let: 2,
    if: 2,
    if: 3,
    or: :infinity,
    and: :infinity
  ]

  @mapping [
    quote: :quote,
    lambda: :lambda,
    def: :def_,
    defun: :defun,
    let: :let,
    if: :if_,
    or: :or_,
    and: :and_
  ]

  def special_form?(name, arity),
    do: {name, arity} in @supported || Keyword.get(@supported, name) == :infinity

  def run(name, args, locals) do
    is_variable = Keyword.get(@supported, name) == :infinity
    real_fn = Keyword.get(@mapping, name)

    apply(__MODULE__, real_fn, if(is_variable, do: [args, locals], else: args ++ [locals]))
  end

  def quote(arg, locals), do: {arg, locals}

  def def_(name, value, locals) do
    value = compute_expr(value, locals, false)
    {value, Map.put(locals, name, value)}
  end

  # (let ((x (+ 2 2)) (y (- 5 2))) (+ x y))
  def let(vars, expr, locals) do
    # vars are (name value) pairs
    vars =
      Enum.map(vars, fn [name, value] ->
        {name, compute_expr(value, locals, false)}
      end)
      |> Enum.into(locals)

    {compute_expr(expr, vars, false), locals}
  end

  def defun(name, input_args, body, locals) do
    {fun, _} = lambda(input_args, body, locals)
    {fun, Map.put(locals, name, fun)}
  end

  def lambda(input_args, body, locals) do
    input_len = length(input_args)

    # TODO: should this get called with locals existing at the moment it gets called? or defined
    fun = fn called_args, called_local ->
      called_args_len = length(called_args)

      if called_args_len != input_len do
        raise Exceptions.ArityError,
          message:
            "wrong number of arguments for lambda: #{called_args_len} given when expected #{input_len}"
      end

      lamb_locals =
        input_args
        |> Enum.zip(called_args)
        |> Enum.into(called_local)

      compute_expr(body, lamb_locals, false)
    end

    {fun, locals}
  end

  def if_(condition, block, else_block \\ nil, locals) do
    result =
      if compute_expr(condition, locals, false) != [],
        do: compute_expr(block, locals),
        else: compute_expr(else_block, locals)

    {result, locals}
  end

  # TODO: first-value/first-nil?

  def or_(args, locals) do
    # {last, args} = List.pop_at(args, -1)

    args
    |> Stream.map(fn node -> compute_expr(node, locals) end)
    |> Enum.find(fn
      [] -> false
      _ -> true
    end) || {[], locals}

    # {result, locals}

    # end) || compute_expr(last)
  end

  def and_(args, locals) do
    {last, args} = List.pop_at(args, -1)

    # {result, locals} =
    args
    |> Stream.map(fn node -> compute_expr(node, locals) end)
    |> Enum.find(fn
      [] -> true
      _ -> false
    end) || compute_expr(last, locals)

    # {result, locals}
  end
end
