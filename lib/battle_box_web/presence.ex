defmodule BattleBoxWeb.Presence do
  use Phoenix.Presence, otp_app: :battle_box,
    pubsub_server: BattleBox.PubSub
end
