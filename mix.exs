defmodule Esquew.MixProject do
  use Mix.Project

  def project do
    [
      app: :esquew,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Esquew.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 4.0"},
      {:plug, "~> 1.10"},
      {:cowboy, "~> 2.8"},
      {:plug_cowboy, "~> 2.3"},
    ]
  end
end
