defmodule BitwardexWeb.Router do
  use BitwardexWeb, :router

  alias BitwardexWeb.Guardian.AuthPipeline, as: GuardianAuthPipeline

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BitwardexWeb do
    pipe_through :api

    post "/accounts/register", AccountsController, :register
    post "/accounts/prelogin", AccountsController, :prelogin

    scope "/" do
      pipe_through(GuardianAuthPipeline)

      get "/sync", SyncController, :sync

      resources "/folders", FoldersController, only: [:create, :update, :delete]
    end
  end

  scope "/identity", BitwardexWeb do
    pipe_through :api

    post "/connect/token", AccountsController, :login
  end
end
