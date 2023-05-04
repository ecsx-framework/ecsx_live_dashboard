defmodule ECSx.LiveDashboard.MixProject do
  use Mix.Project

  @gh_url "https://github.com/APB9785/ecsx_live_dashboard"
  @version "0.1.0"

  def project do
    [
      app: :ecsx_live_dashboard,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "ECSx Live Dashboard",
      docs: docs(),
      description: "Adds an ECSx page to Phoenix Live Dashboard"
    ]
  end

  def application do
    [
      mod: {ECSx.LiveDashboard, []},
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md"],
      logo: nil,
      source_url: @gh_url
    ]
  end

  defp package do
    [
      maintainers: ["Andrew P Berrien"],
      licenses: ["GPL-3.0"],
      links: %{
        "Changelog" => "#{@gh_url}/blob/master/CHANGELOG.md",
        "GitHub" => @gh_url
      }
    ]
  end

  defp deps do
    [
      {:ecsx, github: "APB9785/ECSx"},
      {:phoenix_live_dashboard, github: "phoenixframework/phoenix_live_dashboard"},
      {:contex, "~> 0.4"}
    ]
  end
end
