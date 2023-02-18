defmodule ECSx.LiveDashboard.Store do
  use GenServer

  @system_buffer_size 10

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = %{
      tick_rate: nil,
      systems: %{},
      components: %{},
      client_events: %{min: :infinity, max: 0, store: []}
    }

    IO.inspect("started!")

    {:ok, state}
  end

  def handle_call(:get_systems, _from, state) do
    {:reply, state.systems, state}
  end

  def handle_cast({:system_run, name, duration_us}, state) do
    {:noreply, %{state | systems: update_systems(state.systems, name, duration_us)}}
  end

  def handle_cast({:component_table, _name, _row_count}, state) do
    {:noreply, state}
  end

  def handle_cast({:client_events, _count}, state) do
    {:noreply, state}
  end

  defp update_systems(systems, name, duration) do
    Map.update(
      systems,
      name,
      %{min: duration, max: duration, buffer: List.duplicate(duration, @system_buffer_size)},
      &add_system_tick(&1, duration)
    )
  end

  defp add_system_tick(%{min: min, max: max, buffer: buffer}, duration) do
    new_buffer = Enum.take([duration | buffer], @system_buffer_size)
    new_min = min(min, duration)
    new_max = max(max, duration)

    %{min: new_min, max: new_max, buffer: new_buffer}
  end

  # API

  def system_run(%{name: name, duration_us: duration_us}),
    do: GenServer.cast(__MODULE__, {:system_run, name, duration_us})

  def component_table(%{name: name, row_count: row_count}),
    do: GenServer.cast(__MODULE__, {:component_table, name, row_count})

  def client_events(%{count: count}),
    do: GenServer.cast(__MODULE__, {:client_events, count})

  def get_systems do
    systems = GenServer.call(__MODULE__, :get_systems)

    for {name, %{min: min, max: max, buffer: buffer}} <- systems do
      %{
        name: name,
        min: min,
        max: max,
        avg: Enum.sum(buffer) / @system_buffer_size
      }
    end
  end
end
