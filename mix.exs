defmodule Client.Mixfile do
  use Mix.Project

  def project do
    [app: :bitpay,
     version: "0.2.5",
     elixir: "~> 1.0",
     description: description,
     package: package,
     deps: deps,
     test_coverage: [tool: ExCoveralls]]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpotion, :exjsx, :uuid]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp description do
    """
    Library to allow elixir apps to easily use the BitPay REST API to authenticate, generate invoices, and retrieve invoices.

    Includes Utilities for using Erlangs library for Elliptic Curve Keys.
    """
  end

  defp package do
    [# These are the default files included in the package
      files: ["lib", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      contributors: ["Paul Daigle"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bitpay/elixir-client"}]
  end

  defp deps do
    [{ :mock, "~> 0.1.0", only: [:dev, :test] }, 
     { :ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.0" },
     { :httpotion, "~> 1.0.0" }, 
     { :exjsx, "~> 3.1.0" },
     { :uuid, "~> 0.1.5" },
     { :earmark, "~> 0.1", only: :dev },
     { :ex_doc, "~> 0.7", only: :dev},
     { :excoveralls, "~> 0.3", only: [:dev, :test]}]
  end
end
