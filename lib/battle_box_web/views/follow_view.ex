defmodule BattleBoxWeb.FollowView do
  use BattleBoxWeb, :view
  alias BattleBoxWeb.Live.Follow

  def follow_back_msg(follow, mode) do
    tense = %{active: "Following", passive: "Follow"}[mode]

    case follow do
      %{"lobby" => name} ->
        "Follow Lobby (#{name})"

      %{"bot" => name} ->
        "Follow Bot (#{name})"

      %{"user" => username} ->
        "Follow User (#{username})"
    end
  end
end
