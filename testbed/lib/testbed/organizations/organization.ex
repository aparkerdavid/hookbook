defmodule Testbed.Organizations.Organization do
  use Ecto.Schema
  alias Ecto.Changeset

  schema "organizations" do
    field :name, :string
    field :description, :string
    has_many :people, Person

    timestamps()
  end

  def changeset(organization, attrs) do
    organization
    |> Changeset.cast(attrs, [:name, :description])
    |> Changeset.validate_required([:name])
    |> Changeset.validate_length(:name, max: 255)
    |> Changeset.validate_format(:name, ~r/\A[a-zA-Z0-9\s]+\z/)
  end
end
