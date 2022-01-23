defmodule Kamex.Interpreter.SpecialForms do
  @moduledoc false

  import Kamex.Interpreter, only: [compute_expr: 2, compute_expr: 3]
  alias Kamex.Exceptions

  @tru 1
  @fals 0
  @falsey [[], @fals]

  @mapping [
    quote: :quote,
    lambda: :lambda,
    def: :def_,
    defun: :defun,
    let: :let,
    "let-seq": :let_seq,
    if: :if_,
    or: :or_,
    and: :and_,
    atop: :atop,
    fork: :fork,
    bind: :bind
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

  def let_seq(args, og_locals) do
    # Sequenced, scoped operations.
    # (let-seq
    #   (def x 3)
    #   (defun add3 (y) (+ x y))
    #   (add3 2))
    # Evaluates all `def` and `defun` calls and adds to locals, and computes and returns the first non-definer.
    # If only consists of `def` and `defun`, returns null

    {return, _} =
      Enum.reduce_while(args, {nil, og_locals}, fn node, {_, locals} ->
        case node do
          [name | _] = expr when name in [:def, :defun] ->
            {_, new_locals} = compute_expr(expr, locals, true)
            {:cont, {nil, new_locals}}

          expr ->
            {:halt, {compute_expr(expr, locals), locals}}
        end
      end)

    {return, og_locals}
  end

  def defun([name, input_args, body], locals) do
    {fun, _} = lambda([input_args, body], locals)
    {fun, Map.put(locals, name, fun)}
  end

  def lambda([input_args, body], locals) do
    # input_len = length(input_args)

    # `?arg` denotes optional arguments, which default to null/empty list
    # `...arg` denotes a rest arg (for variadics). default to [] if not given at runtime

    # Make sure that optionals only exist after all requireds, and that max one variadic exists, after all requireds and optionals
    # TODO: figure out adding this inside the parser
    # (lambda (x ?y ?z ...rest) body) OK
    # (lambda (x ?y ?z) body) OK
    # (lambda (x  ...rest ?y ?z) body) BAD
    # (lambda (?x y) body) BAD
    # (lambda (...rest1 ...rest2) body) BAD
    input_args
    # Fancy stuff to turn a normal boring window into smth like `[[:x, nil], [:y, :x], [:"...z", :y]]`
    |> Enum.reverse()
    |> Enum.chunk_every(2, 1, [nil])
    |> Enum.reverse()
    |> Enum.each(fn [curr, prev_] ->
      curr = to_string(curr)
      prev = to_string(prev_)

      # TODO: this could probably be a bit better
      cond do
        String.starts_with?(prev, "...") && !String.starts_with?(curr, "...") ->
          raise Exceptions.SyntaxError, "lambda: variadic arguments must come last"

        String.starts_with?(curr, "...") && String.starts_with?(prev, "...") ->
          raise Exceptions.SyntaxError, "lambda: can only contain one variadic argument"

        prev_ != nil && String.starts_with?(prev, "?") &&
            !(String.starts_with?(curr, "?") || String.starts_with?(curr, "...")) ->
          raise Exceptions.SyntaxError,
                "lambda: optional arguments must come after required arguments"

        String.starts_with?("?...", curr) ->
          raise Exceptions.SyntaxError,
                "lambda: cannot combine optional and variadic arguments"

        true ->
          nil
      end
    end)

    has_rest = Enum.any?(input_args, fn x -> x |> to_string() |> String.starts_with?("...") end)
    optional_count = Enum.count(input_args, &String.starts_with?(to_string(&1), "?"))
    total_count = length(input_args) - if has_rest, do: 1, else: 0
    required_count = total_count - optional_count

    cleaned_args =
      Enum.map(input_args, fn x ->
        case to_string(x) do
          "..." <> arg -> String.to_atom(arg)
          "?" <> arg -> String.to_atom(arg)
          _ -> x
        end
      end)

    fun = fn called_args, called_local ->
      called_len = length(called_args)

      if called_len > total_count and not has_rest,
        # TODO: total_count will be more than required when optionals, need to add a detection to show a range
        do:
          raise(
            Exceptions.ArityError,
            "lambda: too many arguments, expected #{total_count} but got #{called_len}"
          )

      optionals_fill =
        cond do
          called_len >= total_count ->
            []

          called_len < required_count ->
            raise(
              Exceptions.ArityError,
              "lambda: too few arguments, expected #{total_count} but got #{called_len}"
            )

          true ->
            # TODO: move this and anything using an empty list as null, to a proper `null`/`nil` atom, and make sure its handled appropriately.
            Stream.cycle([[]]) |> Enum.take(optional_count - (called_len - required_count))
        end

      called_args = called_args ++ optionals_fill

      lamb_locals =
        if has_rest do
          {args, rest} = Enum.split(called_args, total_count)
          Enum.zip(cleaned_args, args ++ [rest])
        else
          Enum.zip(cleaned_args, called_args)
        end
        |> Enum.into(called_local)

      compute_expr(body, lamb_locals)
    end

    {fun, locals}
  end

  def if_([condition, block | opt], locals) do
    else_block = List.first(opt)

    result =
      if compute_expr(condition, locals) in @falsey,
        do: compute_expr(else_block, locals),
        else: compute_expr(block, locals)

    {result, locals}
  end

  # TODO: first-value/first-nil?

  def or_(args, locals) do
    args
    |> Stream.map(fn node -> compute_expr(node, locals, true) end)
    |> Enum.find(fn
      {x, _} when x in @falsey -> false
      _ -> true
    end) || {@fals, locals}
  end

  def and_(args, locals) do
    args
    |> Stream.map(fn node -> compute_expr(node, locals, true) end)
    |> Enum.find(fn
      {x, _} when x in @falsey -> true
      _ -> false
    end) || {@tru, locals}
  end

  def atop(funs, locals) do
    nodes = atop_compose(funs)

    lambda([[:"...$1"], nodes], locals)
  end

  defp atop_compose([final]), do: [final, :"$1"]
  defp atop_compose([head | tail]), do: [head, atop_compose(tail)]

  def fork([to_call | args], locals) do
    nodes = [to_call | Enum.map(args, &atop_compose([&1]))]

    # TODO: does this work with multiple args?
    lambda([[:"$1"], nodes], locals)
  end

  def bind([fun | args], locals) do
    # Replace all occurances of :_ with a incrementally numbered argument :"$1",
    # :"$2", etc. Must not intrude into other `bind` calls, and if none
    # detected, just append new args to root function
    #
    # This functions a bit differently from og KamilaLisp, wheras they only
    # occurances of `:_` on the top level, we allow nested ones in other functions.
    {args, count} = bind_compose(args)
    lambda_args = Enum.map(1..(count - 1), fn i -> :"$#{i}" end)

    lambda([lambda_args, [fun | args]], locals)
  end

  defp bind_compose(item, count \\ 1)
  defp bind_compose(:_, count), do: {:"$#{count}", count + 1}
  defp bind_compose(x, count) when not is_list(x), do: {x, count}

  defp bind_compose([key | _] = item, count) when key in [:bind, :quote, :let, :lambda],
    do: {item, count}

  defp bind_compose(items, count) do
    {items, count} =
      Enum.reduce(items, {[], count}, fn item, {all, count} ->
        {item, count} = bind_compose(item, count)
        {all ++ [item], count}
      end)

    if count == 1,
      # Implicitly add placeholder to the end, if there aren't any placeholders.
      do: {items ++ [:"$1"], count + 1},
      else: {items, count}
  end

  # TODO: cond
end
