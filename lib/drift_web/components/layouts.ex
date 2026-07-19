defmodule DriftWeb.Layouts do
  @moduledoc """
  App layout and root template for Drift.
  """
  use DriftWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="app-shell">
      <%# -- top bar -- %>
      <header class="topbar">
        <div class="topbar-left">
          <a href="/" class="logo-link">
            <span class="logo-icon" aria-hidden="true">◈</span>
            <span class="logo-text">Drift</span>
          </a>
        </div>

        <nav class="topbar-nav">
          <.link href="/logs" class="nav-link">Logs</.link>
        </nav>

        <div class="topbar-right">
          <button
            id="theme-toggle"
            class="icon-btn"
            aria-label="Toggle theme"
            title="Toggle light/dark theme"
          >
            <.icon name={:sun} class="icon-sm theme-light-icon" />
            <.icon name={:moon} class="icon-sm theme-dark-icon" />
          </button>
        </div>
      </header>

      <%# -- flash -- %>
      <.flash_group flash={@flash} />

      <%# -- main content -- %>
      <main class="main-content">
        <%= render_slot(@inner_block) %>
      </main>
    </div>
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="flash-group">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end
end
