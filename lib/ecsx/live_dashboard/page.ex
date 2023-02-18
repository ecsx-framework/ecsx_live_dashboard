defmodule ECSx.LiveDashboard.Page do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder
  alias Phoenix.LiveDashboard.PageBuilder

  @impl PageBuilder
  def menu_link(_, _) do
    {:ok, "ECSx"}
  end

  @impl PageBuilder
  def render_page(_assigns) do
    {ECSx.LiveDashboard.Component, %{id: :ecsx_component}}
  end

  # @impl PageBuilder
  # def render_page(_assigns) do
  #   table(
  #     columns: table_columns(),
  #     id: :ecsx_table,
  #     row_fetcher: &fetch_components/2,
  #     rows_name: "component types",
  #     title: "Components"
  #   )
  # end

  # defp fetch_components(params, _node) do
  #   %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

  #   components =
  #     [
  #       %{name: "a", count: 50},
  #       %{name: "b", count: 40}
  #     ]
  #     |> Enum.sort_by(& &1[sort_by], sort_dir)

  #   {components, length(components)}
  # end

  # defp table_columns do
  #   [
  #     %{field: :name, sortable: :asc},
  #     %{field: :count, sortable: :desc}
  #   ]
  # end
end
