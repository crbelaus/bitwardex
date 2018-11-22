defmodule BitwardexWeb.AccountsController do
  @moduledoc """
  Controller to handle accounts-related operations
  """

  use BitwardexWeb, :controller

  alias Bitwardex.Accounts
  alias Bitwardex.Accounts.Schemas.User

  def register(conn, params) do
    user_params = parse_user_params(params)

    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        resp(conn, 200, "")

      {:error, _ch} ->
        # TOOD send errors
        resp(conn, 500, "")
    end
  end

  def prelogin(conn, %{"email" => email}) do
    case Accounts.get_user_by_email(email) do
      {:ok, user} ->
        json(conn, %{
          "Kdf" => user.kdf,
          "KdfIterations" => user.kdf_iterations
        })

      {:error, :not_found} ->
        # TODO: Check this is correct
        resp(conn, 404, "")
    end
  end

  def prelogin(conn, _params) do
    resp(conn, 404, "")
  end

  def login(conn, %{"username" => username, "password" => password, "grant_type" => "password"}) do
    case Accounts.get_user_by_email(username) do
      {:ok, %User{master_password_hash: ^password} = user} ->
        generate_user_session(conn, user)

      _error ->
        invalid_user_response(conn)
    end
  end

  def login(conn, %{"grant_type" => "refresh_token", "refresh_token" => token}) do
    with {:ok, _claims} <- BitwardexWeb.Guardian.decode_and_verify(token, %{"typ" => "refresh"}),
         {:ok, user, _claims} <- BitwardexWeb.Guardian.resource_from_token(token) do
      generate_user_session(conn, user)
    else
      _ ->
        invalid_user_response(conn)
    end
  end

  def login(conn, _params), do: invalid_user_response(conn)

  def profile(conn, _params) do
    user = BitwardexWeb.Guardian.Plug.current_resource(conn)
    json(conn, user)
  end

  def update_profile(conn, params) do
    user = BitwardexWeb.Guardian.Plug.current_resource(conn)

    params = %{
      culture: Map.get(params, "culture"),
      name: Map.get(params, "name"),
      master_password_hint: Map.get(params, "masterPasswordHint")
    }

    {:ok, updated_user} = Accounts.update_user(user, params)

    json(conn, updated_user)
  end

  def change_email(conn, params) do
    user = BitwardexWeb.Guardian.Plug.current_resource(conn)
    master_password_hash = Map.get(params, "masterPasswordHash")
    new_email = Map.get(params, "newEmail")

    case Accounts.change_user_email(user, master_password_hash, new_email) do
      {:ok, _updated_user} ->
        resp(conn, 200, "")

      {:error, :invalid_master_password} ->
        conn
        |> put_status(400)
        |> json(%{
          "ValidationErrors" => %{
            "MasterPasswordHash" => [
              "Invalid password."
            ]
          },
          "Object" => "error"
        })

      {:error, :invalid_email} ->
        conn
        |> put_status(400)
        |> json(%{
          "ValidationErrors" => %{
            "NewEmail" => [
              "The email provided is not a valid e-mail address or it's already in use."
            ]
          },
          "Object" => "error"
        })

      _err ->
        conn
        |> put_status(400)
        |> json(%{
          "ValidationErrors" => %{
            "NewEmail" => [
              "Unexpected error happened"
            ]
          },
          "Object" => "error"
        })
    end
  end

  def change_master_password(conn, params) do
    user = BitwardexWeb.Guardian.Plug.current_resource(conn)
    master_password_hash = Map.get(params, "masterPasswordHash")
    new_master_password_hash = Map.get(params, "newMasterPasswordHash")
    new_key = Map.get(params, "key")

    case Accounts.change_user_master_password(
           user,
           master_password_hash,
           new_master_password_hash,
           new_key
         ) do
      {:ok, _updated_user} ->
        resp(conn, 200, "")

      {:error, :invalid_master_password} ->
        conn
        |> put_status(400)
        |> json(%{
          "ValidationErrors" => %{
            "MasterPasswordHash" => [
              "Invalid password."
            ]
          },
          "Object" => "error"
        })

      _err ->
        conn
        |> put_status(400)
        |> json(%{
          "ValidationErrors" => %{
            "MasterPasswordHash" => [
              "Unexpected error happened"
            ]
          },
          "Object" => "error"
        })
    end
  end

  def revision_date(conn, _params) do
    user = BitwardexWeb.Guardian.Plug.current_resource(conn)

    updated_at =
      user.updated_at
      |> DateTime.to_unix(:millisecond)
      |> Integer.to_string()

    json(conn, updated_at)
  end

  defp generate_user_session(conn, user) do
    claims = Accounts.generate_user_claims(user)

    ttl = 60 * 60

    {:ok, access_token, _claims} =
      BitwardexWeb.Guardian.encode_and_sign(user, claims,
        ttl: {ttl, :seconds},
        token_type: "access"
      )

    # TODO: Move this to database and generate a ransom base64 string instead.
    # This is set to (almost) unlimited TTL because it doesn't have to change
    # in the response.
    {:ok, refresh_token, _claims} =
      BitwardexWeb.Guardian.encode_and_sign(user, claims,
        ttl: {1, :week},
        token_type: "refresh"
      )

    conn
    |> put_status(200)
    |> json(%{
      "access_token" => access_token,
      "expires_in" => ttl,
      "token_type" => "Bearer",
      "refresh_token" => refresh_token,
      "Key" => user.key
    })
  end

  defp invalid_user_response(conn) do
    conn
    |> put_status(400)
    |> json(%{
      "error" => "invalid_grant",
      "error_description" => "invalid_username_or_password",
      "ErrorModel" => %{
        "Message" => "Username or password is incorrect. Try again.",
        "ValidationErrors" => nil,
        "ExceptionMessage" => nil,
        "ExceptionStackTrace" => nil,
        "InnerExceptionMessage" => nil,
        "Object" => "error"
      }
    })
  end

  defp parse_user_params(params) do
    %{
      name: Map.get(params, "name"),
      email: Map.get(params, "email"),
      master_password_hash: Map.get(params, "masterPasswordHash"),
      master_password_hint: Map.get(params, "masterPasswordHint"),
      key: Map.get(params, "key"),
      kdf: Map.get(params, "kdf"),
      kdf_iterations: Map.get(params, "kdfIterations")
    }
  end
end
