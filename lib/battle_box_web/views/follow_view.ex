defmodule BattleBoxWeb.FollowView do
  use BattleBoxWeb, :view
  alias BattleBoxWeb.Live.Follow

  def follow_back_target(follow) do
    case follow do
      %{"lobby" => name} ->
        "Lobby (#{name})"

      %{"bot" => name} ->
        "Bot (#{name})"

      %{"user" => username} ->
        "User (#{username})"
    end
  end
end
