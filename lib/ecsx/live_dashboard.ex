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
      [:ecsx, :client_events],
      [:ecsx, :component_table],
      [:ecsx, :system_run]
    ]
  end
end
