defmodule Testbed.Organizations do
  alias Testbed.Organizations.Organization
  alias Testbed.Repo

  def list_organizations do
    Repo.all(Organization)
  end

  def seed_organizations do
    clear_organizations()

    now = NaiveDateTime.new!(Date.utc_today(), Time.utc_now()) |> NaiveDateTime.truncate(:second)

    data =
      for _n <- 0..100 do
        %{
          name: random_organization_name(),
          description: random_organization_description(),
          inserted_at: now,
          updated_at: now
        }
      end

    Repo.insert_all(Organization, data)
  end

  def random_organization_name() do
    Faker.Person.last_name() <>
      " " <>
      Enum.random([
        Faker.Industry.industry(),
        Faker.Industry.sector(),
        Faker.Industry.sub_sector()
      ])
  end

  def random_organization_description() do
    "We " <>
      Faker.Company.bs() <>
      ", " <>
      Faker.Company.bs() <>
      ", and " <>
      Faker.Company.bs() <>
      "."
  end

  defp clear_organizations do
    Repo.delete_all(Organization)
  end
end
