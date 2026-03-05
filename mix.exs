defmodule Hookbook.MixProject do
  use Mix.Project

  def project do
    [
      app: :hookbook,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix, "~> 1.7.18"}
    ]
  end
end
