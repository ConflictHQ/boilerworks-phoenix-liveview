defmodule BoilerworksWeb.Router do
  use BoilerworksWeb, :router

  import BoilerworksWeb.Plugs.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BoilerworksWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Health check (no auth)
  scope "/", BoilerworksWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  # Public routes (not authenticated)
  scope "/", BoilerworksWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_authenticated,
      on_mount: [{BoilerworksWeb.Plugs.LiveAuth, :redirect_if_authenticated}] do
      live "/login", AuthLive.Login, :login
      live "/register", AuthLive.Register, :register
    end

    post "/login", AuthController, :create
    post "/register", AuthController, :register
  end

  # Authenticated routes
  scope "/", BoilerworksWeb do
    pipe_through [:browser, :require_authenticated_user]

    delete "/logout", AuthController, :delete

    live_session :authenticated,
      on_mount: [{BoilerworksWeb.Plugs.LiveAuth, :ensure_authenticated}] do
      live "/", DashboardLive, :index

      # Products
      live "/products", ProductLive.Index, :index
      live "/products/new", ProductLive.Index, :new
      live "/products/:id/edit", ProductLive.Index, :edit
      live "/products/:id", ProductLive.Show, :show

      # Categories
      live "/categories", CategoryLive.Index, :index
      live "/categories/new", CategoryLive.Index, :new
      live "/categories/:id/edit", CategoryLive.Index, :edit

      # Forms
      live "/forms", FormLive.Index, :index
      live "/forms/new", FormLive.Index, :new
      live "/forms/:id/edit", FormLive.Index, :edit
      live "/forms/:id", FormLive.Show, :show
      live "/forms/:id/submit", FormLive.Submit, :submit

      # Workflows
      live "/workflows", WorkflowLive.Index, :index
      live "/workflows/new", WorkflowLive.Index, :new
      live "/workflows/:id/edit", WorkflowLive.Index, :edit
      live "/workflows/:id", WorkflowLive.Show, :show
    end
  end

  # Dev routes
  if Application.compile_env(:boilerworks, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BoilerworksWeb.Telemetry
    end
  end
end
