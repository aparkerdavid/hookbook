defmodule Testbed.Repo.Migrations.InitializeSchema do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add(:name, :string, null: false)
      add(:description, :text)

      timestamps()
    end

    create table(:people) do
      add(:first_name, :string, null: false)
      add(:last_name, :string, null: false)
      add(:email, :string)
      add(:organization_id, references(:organizations))

      timestamps()
    end

    create(index(:people, [:organization_id]))
  end
end
