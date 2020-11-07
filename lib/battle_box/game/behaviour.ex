defmodule BattleBox.Game.Behaviour do
  # Due to the way we're using macros is BattleBox.Game,
  # This behaviour has to live outside of that module

  @callback color() :: binary()
  @callback view_module() :: atom()
  @callback title() :: binary()
  @callback name() :: atom()
  @callback players_for_settings(map()) :: [integer(), ...]
  @callback ais() :: [atom(), ...]
  @callback default_arenas() :: [%{name: binary(), description: binary(), settings: map()}]
  @callback docs_tree() :: map()
end
