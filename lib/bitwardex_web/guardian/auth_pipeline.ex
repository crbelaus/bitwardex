defmodule BitwardexWeb.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :bitwardex,
    module: BitwardexWeb.Guardian

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
  plug BitwardexWeb.CurrentUserPlug
end
