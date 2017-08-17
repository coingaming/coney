defmodule Coney.Mixfile do
  use Mix.Project

  def project do
    [app: :coney,
     version: "0.3.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:amqp, "~> 0.2"},
      {:poison, "~> 2.0 or ~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Consumer server for RabbitMQ.
    """
  end

  defp package do
    [
     name: :coney,
     files: ["lib", "mix.exs", "README.md", "LICENSE.txt"],
     maintainers: ["Aleksandr Fomin"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/llxff/coney"}]
  end
end
