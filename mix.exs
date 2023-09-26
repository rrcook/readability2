defmodule Readability.Mixfile do
  @moduledoc """
  """

  @version "0.7.1"
  @description """
  A fork of the Readability library for extracting and curating articles.
  """

  use Mix.Project

  def project do
    [
      app: :readability2,
      version: @version,
      elixir: "~> 1.10",
      description: @description,
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :floki, :codepagex]]
  end

  defp deps do
    [
      {:codepagex, "~> 0.1.6"},
      {:credo, "~> 1.7.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.3.0", only: [:dev]},
      {:ex_doc, "~> 0.29.4", only: :dev},
      {:floki, "~> 0.34.2"},
      {:mock, "~> 0.3.7", only: :test}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "doc"],
      maintainers: ["Mark Harper"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/markharper/readability",
        "Docs" => "https://hexdocs.pm/readability2/Readability.html"
      }
    ]
  end
end
