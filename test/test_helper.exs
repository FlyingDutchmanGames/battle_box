ExUnit.start(capture_log: true)
Ecto.Adapters.SQL.Sandbox.mode(BattleBox.Repo, :manual)
Application.ensure_all_started(:bypass)
