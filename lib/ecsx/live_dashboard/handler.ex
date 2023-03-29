defmodule ECSx.LiveDashboard.Handler do
  alias ECSx.LiveDashboard.Store
  require Logger

  def handle_event([:ecsx, :system_run], measurements, metadata, _config) do
    system_run = %{
      name: metadata.system,
      duration_us: System.convert_time_unit(measurements.duration, :native, :microsecond)
    }

    # Logger.info("[#{metadata.system}] took #{us_duration} us")
    Store.system_run(system_run)
  end

  def handle_event([:ecsx, :component, action], measurements, metadata, _config) do
    # Logger.info("[#{metadata.component}] has #{measurements.count} rows")

    Store.component_action(%{name: metadata.type, action: action, second: measurements.second})
  end

  def handle_event([:ecsx, :client_events], measurements, _metadata, _config) do
    # Logger.info("[ClientEvents] #{measurements.count} handled")
    Store.client_events(%{count: measurements.count})
  end
end
