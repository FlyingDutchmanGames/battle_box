defmodule BattleBox.Release do
  require Logger

  defmodule Migrator do
    def child_spec(_opts) do
      %{
        id: __MODULE__,
        restart: :temporary,
        start: {Task, :start_link, [&BattleBox.Release.migrate/0]}
      }
    end
  end

  @app :battle_box

  def migrate do
    Logger.info("Running Battle Box Migrations")

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
