# Kamex

> A basic Lisp interpreter implemented in Elixir.

Currently implements a very simple Lisp with a tiny amount of builtin functions,
but eventually plans to expand to be a Elixir implementation of the brilliant
[KamilaLisp](https://github.com/kspalaiologos/kamilalisp)

## Known Issues

- Probably a whole ton of stuff, it's very early days for this. Please open an
  issue if you notice weird behaviour.

## Builtins

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
iex> run(~S[
...>   (defun factorial (n)
...>     (if (zerop n) 1
...>         (* n (factorial (-- n)))))
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
