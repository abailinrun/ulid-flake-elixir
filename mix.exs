defmodule UlidFlake.MixProject do
  use Mix.Project

  def project do
    [
      app: :ulid_flake,
      version: "1.0.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A compact 64-bit ULID variant inspired by ULID and Twitter's Snowflake.",
      package: package(),
      source_url: "https://github.com/abailinrun/ulid-flake-elixir"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ex_unit]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Benchmarking
      {:benchee, "~> 1.3.1", only: [:dev, :test]},
      # Static checking
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false},
      # Documentation
      {:ex_doc, "~> 0.34.1", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: :ulid_flake,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/abailinrun/ulid-flake-elixir"},
      maintainers: ["abailinrun"]
    ]
  end
end
