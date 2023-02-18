defmodule ECSx.LiveDashboard.Component do
  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias ECSx.LiveDashboard.Store

  def update(_, socket) do
    systems = Store.get_systems()
    tick_interval = div(1_000_000, ECSx.tick_rate())

    total_used =
      systems
      |> Enum.map(& &1.avg)
      |> Enum.sum()

    idle = %{name: "Idle", avg: tick_interval - total_used}

    bars =
      systems
      |> render_bars(tick_interval)
      |> add_colors()

    pie_chart = make_pie_chart(systems)

    socket = assign(socket, bars: bars, systems: systems, idle: idle, pie_chart: pie_chart)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div>
        <svg viewBox="0 0 100 10">
          <%= for %{offset: offset, percent_size: percent_size, color: color} <- @bars do %>
            <.render_bar offset={offset} percent_size={percent_size} color={color} />
          <% end %>
        </svg>
      </div>

      <table>
        <tr>
          <th>Name</th>
          <th>Avg Time</th>
        </tr>
        <%= for %{name: name, avg: avg} <- @systems do %>
          <tr>
            <td><%= get_alias(name) %></td>
            <td><%= avg %> μs</td>
          </tr>
        <% end %>
      </table>

      <%= Contex.Plot.to_svg(@pie_chart) %>
    </div>
    """
  end

  defp get_alias(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
  end

  defp get_alias(other) when is_binary(other), do: other

  defp render_bars(systems, tick_interval, done \\ [], offset \\ 0)

  defp render_bars([], _tick_interval, done, offset) do
    bar = %{offset: offset, percent_size: 100 - offset}

    [bar | done]
  end

  defp render_bars([system | rest], tick_interval, done, offset) do
    %{name: _name, min: _min, max: _max, avg: avg} = system
    percent_size = 100 * avg / tick_interval

    bar = %{offset: offset, percent_size: percent_size}

    render_bars(rest, tick_interval, [bar | done], offset + percent_size)
  end

  defp add_colors(systems) do
    colors = ColorStream.hex(saturation: 0.5, value: 0.95)

    Enum.zip_with(systems, colors, fn system, color ->
      Map.put(system, :color, "##{color}")
    end)
  end

  def render_bar(assigns) do
    ~H"""
    <rect x={@offset} y="0" width={@percent_size} height="100%" fill={@color} />
    """
  end

  defp make_pie_chart(systems) do
    data = Enum.map(systems, &[get_alias(&1.name), &1.avg])

    dataset = Contex.Dataset.new(data, ["Name", "Avg Runtime"])

    opts = [
      mapping: %{category_col: "Name", value_col: "Avg Runtime"},
      legend_setting: :legend_right,
      data_labels: true,
      title: "System Runtimes"
    ]

    Contex.Plot.new(dataset, Contex.PieChart, 600, 400, opts)
  end
end
