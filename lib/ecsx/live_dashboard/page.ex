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
end
