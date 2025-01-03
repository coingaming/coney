defmodule Coney.Mixfile do
  use Mix.Project

  def project do
    [
      app: :coney,
      version: "3.1.3",
      elixir: ">= 1.12.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Coney.Application, []}
    ]
  end

  defp deps do
    [
      {:amqp, "~> 3.3"},
      # Dev deps
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Consumer server for RabbitMQ.
    """
  end

  defp elixirc_paths(env) when env in [:test, :dev], do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: :coney,
      files: ["lib", "mix.exs", "README.md", "LICENSE.txt"],
      maintainers: ["Yolo Group"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/coingaming/coney"}
    ]
  end
end
