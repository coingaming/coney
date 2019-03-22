defmodule Coney.Mixfile do
  use Mix.Project

  def project do
    [
      app: :coney,
      version: "2.2.0",
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
      extra_applications: [],
      mod: {Coney.Application, []}
    ]
  end

  defp deps do
    [
      {:amqp, "~> 1.1"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
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
