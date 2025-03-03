defmodule Vix.MixProject do
  use Mix.Project

  @version "0.16.0"
  @scm_url "https://github.com/akash-akya/vix"

  def project do
    [
      app: :vix,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_targets: ["all"],
      make_clean: ["clean"],
      deps: deps(),
      aliases: aliases(),

      # elixir_make config
      make_precompiler: make_precompiler(),
      make_precompiler_url: "#{@scm_url}/releases/download/v#{@version}/@{artefact_filename}",
      make_precompiler_priv_paths: [
        "vix.*",
        "precompiled_libvips/lib/libvips.dylib",
        "precompiled_libvips/lib/libvips.*.dylib",
        "precompiled_libvips/lib/libvips.so",
        "precompiled_libvips/lib/libvips.so.*",
        "precompiled_libvips/lib/*.dll",
        "precompiled_libvips/lib/*.lib"
      ],
      make_force_build: make_force_build(),
      cc_precompiler: [
        cleanup: "clean_precompiled_libvips"
      ],

      # Coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Package
      package: package(),
      description: description(),

      # Docs
      source_url: @scm_url,
      homepage_url: @scm_url,
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        extras: [
          "README.md",
          "LICENSE",
          "livebooks/introduction.livemd",
          "livebooks/picture-language.livemd"
        ],
        groups_for_extras: [
          Livebooks: Path.wildcard("livebooks/*.livemd")
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :public_key]
    ]
  end

  defp description do
    "NIF based bindings for libvips"
  end

  defp package do
    [
      maintainers: ["Akash Hiremath"],
      licenses: ["MIT"],
      files:
        ~w(lib checksum.exs mix.exs README.md LICENSE Makefile c_src/Makefile c_src/*.{h,c} c_src/g_object/*.{h,c}),
      links: %{
        GitHub: @scm_url,
        libvips: "https://libvips.github.io/libvips"
      }
    ]
  end

  defp deps do
    maybe_kino() ++
      [
        {:elixir_make, "~> 0.8 or ~> 0.7.3", runtime: false},
        {:cc_precompiler, "~> 0.2 or ~> 0.1.4", runtime: false},
        {:castore, "~> 0.1"},

        # development & test
        {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
        {:ex_doc, ">= 0.0.0", only: :dev},
        {:excoveralls, "~> 0.15", only: :test},
        {:temp, "~> 0.4", only: :test, runtime: false}
      ]
  end

  defp maybe_kino do
    if Version.compare(System.version(), "1.13.0") in [:gt, :eq] do
      [{:kino, "~> 0.7", optional: true}]
    else
      []
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      deep_clean: "cmd make clean_precompiled_libvips",
      precompile: [
        "deep_clean",
        "elixir_make.precompile"
      ]
    ]
  end

  defp make_precompiler do
    if compilation_mode() == "PLATFORM_PROVIDED_LIBVIPS" do
      nil
    else
      {:nif, CCPrecompiler}
    end
  end

  defp make_force_build, do: compilation_mode() == "PRECOMPILED_LIBVIPS"

  defp compilation_mode do
    (System.get_env("VIX_COMPILATION_MODE") || "PRECOMPILED_NIF_AND_LIBVIPS")
    |> String.upcase()
  end
end
