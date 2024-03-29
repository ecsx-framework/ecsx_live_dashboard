defmodule ECSx.LiveDashboard do
  @moduledoc """
  See [README](readme.html) for documentation.
  """
  use Application

  def start(_, _) do
    :ok =
      :telemetry.attach_many(
        "ecsx-telemetry-handler",
        telemetry_events(),
        &ECSx.LiveDashboard.Handler.handle_event/4,
        nil
      )

    children = [
      ECSx.LiveDashboard.Store
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp telemetry_events do
    [
      [:ecsx, :component_action, :write],
      [:ecsx, :component_action, :lookup],
      [:ecsx, :component_action, :scan],
      [:ecsx, :system_run]
    ]
  end
end
