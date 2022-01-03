defmodule Kamex.Interpreter.SpecialForms do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2, compute_expr: 3]
  alias Kamex.Exceptions

  @mapping [
    quote: :quote,
    lambda: :lambda,
    def: :def_,
    defun: :defun,
    let: :let,
    if: :if_,
    not: :not_,
    or: :or_,
    and: :and_,
    atop: :atop
  ]

  def special_form?(name), do: Keyword.get(@mapping, name)

  def run(name, args, locals) do
    real_fn = Keyword.get(@mapping, name)

    apply(__MODULE__, real_fn, [args, locals])
  end

  def quote([arg], locals), do: {arg, locals}

  def def_([name, value], locals) do
    value = compute_expr(value, locals)
    {value, Map.put(locals, name, value)}
  end

  # (let ((x (+ 2 2)) (y (- 5 2))) (+ x y))
  def let([vars, expr], locals) do
    # vars are (name value) pairs
    vars =
      Enum.map(vars, fn [name, value] ->
        {name, compute_expr(value, locals)}
      end)
      |> Enum.into(locals)

    {compute_expr(expr, vars), locals}
  end

  def defun([name, input_args, body], locals) do
    {fun, _} = lambda([input_args, body], locals)
    {fun, Map.put(locals, name, fun)}
  end

  def lambda([input_args, body], locals) do
    input_len = length(input_args)

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

      compute_expr(body, lamb_locals)
    end

    {fun, locals}
  end

  def if_([condition, block | opt], locals) do
    else_block = List.first(opt)

    result =
      if compute_expr(condition, locals) != [],
        do: compute_expr(block, locals),
        else: compute_expr(else_block, locals)

    {result, locals}
  end

  def not_([value], locals) do
    # TODO: move to true/false
    {if(value == [], do: true, else: []), locals}
  end

  # TODO: first-value/first-nil?

  def or_(args, locals) do
    # {last, args} = List.pop_at(args, -1)

    args
    |> Stream.map(fn node -> compute_expr(node, locals, true) end)
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
    |> Stream.map(fn node -> compute_expr(node, locals, true) end)
    |> Enum.find(fn
      [] -> true
      _ -> false
    end) || compute_expr(last, locals)

    # {result, locals}
  end

  def atop(funs, locals) do
    nodes = atop_compose(funs)

    lambda([[:"$1"], nodes], locals)
  end

  defp atop_compose([final]), do: [final, :"$1"]
  defp atop_compose([head | tail]), do: [head, atop_compose(tail)]
end
