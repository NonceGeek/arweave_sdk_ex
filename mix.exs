defmodule ArweaveSdkEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :arweave_sdk_ex,
      version: "0.1.6",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
    ]
  end

  defp description do
    """
      Interact with Arweave.
    """
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README.md"],
     maintainers: ["leeduckgo"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/WeLightProject/arweave_sdk_ex.git",
              "Docs" => "https://hexdocs.pm/arweave_sdk_ex/"}
     ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [

      extra_applications: [:logger, :export]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [

      {:httpoison, "~> 1.8"},
      {:ex_struct_translator, "~> 0.1.1"},
      {:jose, "~> 1.11"},
      {:export, "~> 0.1.0"},
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 0.1", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
