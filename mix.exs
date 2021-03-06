defmodule Kamex.MixProject do
  use Mix.Project

  def project do
    [
      app: :kamex,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [Extractable]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: :dev},
      {:complex, "~> 0.3.0"},
      {:math, "~> 0.7.0"},
      {:ratio, "~> 3.0"},
      {:tensor, "~> 2.1"},
      {:typed_struct, "~> 0.2.1"}
    ]
  end
end
