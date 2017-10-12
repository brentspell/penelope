defmodule Penelope.Mixfile do
  use Mix.Project

  def project do
    [
      app:             :penelope,
      name:            "Penelope",
      version:         "0.1.0",
      elixir:          "~> 1.5",
      compilers:       ["nif" | Mix.compilers],
      aliases:         [clean: ["clean", "clean.nif"]],
      elixirc_paths:   elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps:            deps(),
      dialyzer:        [ignore_warnings: ".dialyzerignore",
                        plt_add_deps:    :transitive],
      docs:            [extras: ["README.md"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:xxhash, "~> 0.2.0", hex: :erlang_xxhash},
      {:e2qc, "~> 1.2"},
      {:benchee, "~> 0.9", only: :dev},
      {:stream_data, "~> 0.3", only: [:test]},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
end

defmodule Mix.Tasks.Compile.Nif do
  def run(_args) do
    {result, _errcode} = System.cmd("make", ["-C", "c_src"])
    IO.binwrite(result)
  end
end

defmodule Mix.Tasks.Clean.Nif do
  def run(_args) do
    {result, _errcode} = System.cmd("make", ["-C", "c_src", "clean"])
    IO.binwrite(result)
  end
end