defmodule ECSx.LiveDashboard.Page do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder

  alias ECSx.LiveDashboard.Store
  alias Phoenix.LiveDashboard.PageBuilder

  @base_tabs [:systems, :components]

  @impl PageBuilder
  def mount(params, _session, socket) do
    case params["nav"] do
      nil ->
        to = live_dashboard_path(socket, socket.assigns.page, nav: :systems)
        {:ok, push_navigate(socket, to: to)}

      nav ->
        socket =
          socket
          |> assign_systems()
          |> assign_components()
          |> assign(
            selector: nav,
            tabs: @base_tabs,
            component_type: nil,
            component_table: []
          )

        {:ok, socket}
    end
  end

  defp assign_systems(socket) do
    systems = Store.get_systems()
    tick_interval = div(1_000_000, ECSx.tick_rate())

    total_used =
      systems
      |> Enum.map(& &1.avg)
      |> Enum.sum()

    idle = %{name: "Idle", avg: tick_interval - total_used}

    percent_used = 100 * total_used / tick_interval

    pie_chart = make_pie_chart(systems)

    assign(socket, systems: systems, idle: idle, pie_chart: pie_chart, percent_used: percent_used)
  end

  defp assign_components(socket) do
    manager_module = ECSx.manager()
    component_types_list = manager_module.components()

    component_table_row_counts =
      Map.new(component_types_list, fn type ->
        {type, :ets.info(type, :size)}
      end)

    size =
      component_types_list
      |> Enum.map(&:ets.info(&1, :memory))
      |> Enum.sum()
      |> words_to_bytes()
      |> format_size()

    assign(socket, components: component_table_row_counts, components_total_size: size)
  end

  defp words_to_bytes(words) do
    words * :erlang.system_info(:wordsize)
  end

  defp format_size(bytes) do
    "#{bytes} bytes"
  end

  defp assign_component_table(socket) do
    case socket.assigns.component_type do
      nil -> assign(socket, component_table: [])
      type -> assign(socket, component_table: :ets.tab2list(type))
    end
  end

  @impl PageBuilder
  def menu_link(_, _) do
    {:ok, "ECSx"}
  end

  @impl PageBuilder
  def handle_refresh(socket) do
    case socket.assigns.selector do
      "systems" -> {:noreply, assign_systems(socket)}
      "components" -> {:noreply, assign_components(socket)}
      "component" -> {:noreply, assign_component_table(socket)}
    end
  end

  @impl PageBuilder
  def handle_params(params, _, socket) do
    socket =
      case params["nav"] do
        nil ->
          assign(socket,
            selector: "systems",
            component_type: nil,
            component_table: [],
            tabs: @base_tabs
          )

        "component" ->
          if type = params["type"] do
            component_type =
              socket.assigns.components
              |> Map.keys()
              |> Enum.find(fn full_type -> get_alias(full_type) == type end)

            socket
            |> assign(selector: params["nav"], component_type: component_type)
            |> assign(tabs: @base_tabs ++ [:component])
            |> assign_component_table()
          else
            path =
              live_dashboard_path(socket, socket.assigns.page,
                nav: :component,
                type: get_alias(socket.assigns.component_type)
              )

            push_patch(socket, to: path)
          end

        nav when nav in ["systems", "components"] ->
          assign(socket,
            selector: nav,
            component_type: nil,
            component_table: [],
            tabs: @base_tabs
          )
      end

    {:noreply, socket}
  end

  @impl PageBuilder
  def render(assigns) do
    ~H"""
    <.live_nav_bar id="ecsx_nav_bar" page={@page}>
      <:item :for={tab <- @tabs} name={to_string(tab)} label={format_nav_name(tab)} method="patch">
        <div></div>
      </:item>
    </.live_nav_bar>
    <div style="display: flex; flex-direction: column; align-items: center;">
      <%= case @selector do %>

      <% "systems" -> %>
        <div style="width: 50%; margin-bottom: 4rem;">
          <p style="font: bold; font-size: 24px;">
            Total System Load: <%= percent(@percent_used) %>
          </p>
          <div style="height: 50px; width: 100%; border: solid; border-radius: 10px;">
            <div id="percent-used" style={"background-color: #{loadbar_color(@percent_used)}; height: 100%; width: #{@percent_used}%"} />
          </div>
        </div>

        <div style="width: 90%; display: flex; gap: 10%; margin-bottom: 32px;">
          <div style="width: 45%; font-size: 12px;">
            <%= Contex.Plot.to_svg(@pie_chart) %>
          </div>

          <table style="font-size: 16px; width: 45%;">
            <tr>
              <th>Name</th>
              <th>Avg run time</th>
            </tr>
            <%= for %{name: name, avg: avg} <- @systems do %>
              <tr>
                <td><%= get_alias(name) %></td>
                <td><%= avg %> μs</td>
              </tr>
            <% end %>
          </table>
        </div>

      <% "components" -> %>
        <table style="font-size: 16px; width: 50%;">
          <tr>
            <th>Component type</th>
            <th>Count</th>
          </tr>
          <%= for {name, count} <- @components do %>
            <tr>
              <td><%= get_alias(name) %></td>
              <td>
                <.link patch={live_dashboard_path(@socket, @page, nav: :component, type: get_alias(name))}>
                  <%= count %>
                </.link>
              </td>
            </tr>
          <% end %>
        </table>

      <% "component" -> %>
        <p style="font: bold; font-size: 24px;">
          <%= get_alias(@component_type) %> Components
        </p>
        <table style="font-size: 16px; width: 50%;">
          <tr>
            <th>Entity</th>
            <th>Value</th>
            <th>Persist?</th>
          </tr>
          <%= for {entity, value, persist} <- @component_table do %>
            <tr>
              <td><%= entity %></td>
              <td><%= value %></td>
              <td><%= persist %></td>
            </tr>
          <% end %>
        </table>

      <% end %>
    </div>
    """
  end

  defp format_nav_name(:systems), do: "Systems"
  defp format_nav_name(:components), do: "Components"
  defp format_nav_name(:component), do: "Component"

  defp loadbar_color(percent_used) when percent_used > 50, do: "red"
  defp loadbar_color(percent_used) when percent_used > 30, do: "orange"
  defp loadbar_color(_percent_used), do: "green"

  defp get_alias(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
  end

  defp percent(n) do
    n
    |> round()
    |> Integer.to_string()
    |> then(&[&1, "%"])
  end

  defp make_pie_chart(systems) do
    data = Enum.map(systems, &[get_alias(&1.name), &1.avg])

    dataset = Contex.Dataset.new(data, ["Name", "Avg Runtime"])

    opts = [
      mapping: %{category_col: "Name", value_col: "Avg Runtime"},
      legend_setting: :legend_right,
      data_labels: false,
      title: "System Runtimes"
    ]

    Contex.Plot.new(dataset, Contex.PieChart, 600, 400, opts)
  end
end
