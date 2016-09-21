defmodule Dufa.Mixfile do
  use Mix.Project

  def project do
    [app: :dufa,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [
      {:poison, "~> 2.0"},
      {:httpoison, "~> 0.9.0"},
      {:mock, "~> 0.1.1", only: :test},
    ]
  end
end
