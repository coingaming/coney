defmodule Coney.Mixfile do
  use Mix.Project

  def project do
    [
      app: :coney,
      version: "2.0.0",
      elixir: ">= 1.5.0",
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
      applications: [],
      mod: {Coney.Application, []}
    ]
  end

  defp deps do
    [
      {:amqp, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Consumer server for RabbitMQ.
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: :coney,
      files: ["lib", "mix.exs", "README.md", "LICENSE.txt"],
      maintainers: ["Aleksandr Fomin"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/llxff/coney"}
    ]
  end
end
