# Kamex

> A basic Lisp interpreter implemented in Elixir.

Currently implements a very simple Lisp with a tiny amount of builtin functions,
but eventually plans to expand to be a Elixir implementation of the brilliant
[KamilaLisp](https://github.com/kspalaiologos/kamilalisp)

## Known Issues

- Probably a whole ton of stuff, it's very early days for this. Please open an
  issue if you notice weird behaviour.

## Builtins

**Note:** this list is out of date. I am currently working on bringing Kamex up
to feature-parity with KamilaLisp, so I will update this once I've caught up and
can properly list stuff categorically.

- +, -, \*, /, ++, --, !
- list, cons, append, head, tail
- print, zerop
- quote, lambda, def (global vars), defun (global func), let (locals in a
  block), if, or, and, not

## Examples

```elixir
iex> run(~S[
...>   (defun add (x y) (+ x y))
...>   (add 6 9)
...> ])
{15, %{add: #Function<2.88664320/2 in Kamex.Interpreter.SpecialForms.lambda/3>}}
```

```elixir
iex> run(~S[
...>   (let ((x (+ 2 5)) (y (- 45 12))) (* x y))
...> ])
{231, %{}}
```

```elixir
iex> run(~S[  (at $(-) $(= 0 (% _ 2)) (iota 100))  ])
{[0, 1, -2, 3, -4, 5, -6, 7, -8, 9, -10, 11, -12, 13, -14, 15, -16, 17, -18, 19,
  -20, 21, -22, 23, -24, 25, -26, 27, -28, 29, -30, 31, -32, 33, -34, 35, -36,
  37, -38, 39, -40, 41, -42, 43, -44, 45, -46, 47, -48, ...], %{}}
```

```elixir
iex> run(~S[
...>   (defun factorial (n)
...>     (if (= 0 n) 1
...>       ($(* n)@factorial@$(- _ 1) n)))
...>
...>   (factorial 10)
...> ])
{3628800,
 %{
   factorial: #Function<2.104658454/2 in Kamex.Interpreter.SpecialForms.lambda/3>
 }}
```

## Using

- Install [Elixir](https://elixir-lang.org/)
- `iex -S mix` to launch into the Elixir REPL (Native Kamex REPL soon™️)
- `import Kamex.Interpreter` to import the interpreter function
- `run(~S[(code here)])` for running code.

## License

[MIT License](./LICENSE)
