defmodule Testbed.Repo do
  use Ecto.Repo,
    otp_app: :testbed,
    adapter: Ecto.Adapters.Postgres
end
