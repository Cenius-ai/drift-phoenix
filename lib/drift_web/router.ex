defmodule DriftWeb.Router do
  use DriftWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DriftWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Main app — browser pipeline
  scope "/", DriftWeb do
    pipe_through :browser

    live "/", LogListLive, :index
    live "/logs", LogListLive, :index
    live "/logs/:id", LogDetailLive, :show
  end

  # API — JSON pipeline for programmatic log ingestion
  scope "/api", DriftWeb do
    pipe_through :api

    get "/logs", LogController, :index
    get "/logs/:id", LogController, :show
    post "/logs", LogController, :create
  end
end
