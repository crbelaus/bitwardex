defmodule BitwardexWeb.SyncView do
  use BitwardexWeb, :view

  alias BitwardexWeb.CiphersView
  alias BitwardexWeb.FoldersView

  def render("sync.json", %{current_user: user, ciphers: ciphers, collections: collections}) do
    %{
      "Profile" => user,
      "Folders" => Enum.map(user.folders, &render_folder/1),
      "Ciphers" => Enum.map(ciphers, &render_cipher(&1, user)),
      "Collections" => Enum.map(collections, &render_user_collection/1),
      "Domains" => [],
      "Object" => "sync"
    }
  end

  defp render_cipher(cipher, user) do
    CiphersView.render("cipher.json", %{current_user: user, cipher: cipher})
  end

  defp render_folder(folder) do
    FoldersView.render("folder.json", %{folder: folder})
  end

  defp render_user_collection({collection, read_only}) do
    %{
      "ReadOnly" => read_only,
      "Id" => collection.id,
      "OrganizationId" => collection.organization_id,
      "Name" => collection.name,
      "Object" => "collectionDetails"
    }
  end
end
