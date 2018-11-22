defmodule Bitwardex.Accounts.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Bitwardex.Core.Schemas.Cipher
  alias Bitwardex.Core.Schemas.Folder

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :culture, :string, default: "en-US"
    field :email, :string
    field :email_verified, :boolean, default: true
    field :kdf, :integer
    field :kdf_iterations, :integer
    field :key, :string
    field :master_password_hash, :string
    field :master_password_hint, :string
    field :name, :string
    field :premium, :boolean, default: true

    has_many :ciphers, Cipher
    has_many :folders, Folder

    timestamps(type: :utc_datetime)
  end

  @required_fields [:email, :master_password_hash, :key, :kdf, :kdf_iterations]
  @optional_fields [:name, :master_password_hint, :email_verified, :premium, :culture]

  @email_regex ~r/^[A-Za-z0-9._%+-\\']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, @email_regex)
    |> unique_constraint(:email)
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, _opts) do
      encoded_struct = %{
        "Id" => struct.id,
        "Name" => struct.name,
        "Email" => struct.email,
        "EmailVerified" => struct.email_verified,
        "Premium" => struct.premium,
        "MasterPasswordHint" => struct.master_password_hint,
        "Culture" => struct.culture,
        "TwoFactorEnabled" => false,
        "Key" => struct.key,
        "PrivateKey" => nil,
        "SecurityStamp" => struct.id,
        "Organizations" => [],
        "Object" => "profile"
      }

      Jason.encode!(encoded_struct)
    end
  end
end
