defmodule BattleBoxWeb.Live.FollowTest do
  use BattleBoxWeb.ConnCase, async: false
  alias BattleBoxWeb.Live.Follow
  import Phoenix.LiveViewTest
  alias BattleBox.{Arena, Bot, User}

  @id Ecto.UUID.generate()
  @game_id Ecto.UUID.generate()

  redirect_cases = [
    {%{"follow" => :next_available, "follow_back" => "next-available"},
     "/games/#{@game_id}?follow=next-available"},
    {%{"follow" => {User, @id}, "follow_back" => %{"user" => "user-name"}},
     "/games/#{@game_id}?follow[user]=user-name"},
    {%{"follow" => {Bot, @id}, "follow_back" => %{"user" => "user-name", "bot" => "bot-name"}},
     "/games/#{@game_id}?follow[bot]=bot-name&follow[user]=user-name"},
    {%{
       "follow" => {Arena, @id},
       "follow_back" => %{"user" => "user-name", "arena" => "arena-name"}
     }, "/games/#{@game_id}?follow[arena]=arena-name&follow[user]=user-name"}
  ]

  for {session, expected} <- redirect_cases do
    test "it redirects correctly on :game_update to #{expected}", context do
      {:ok, view, _html} =
        live_isolated(context.conn, Follow, session: unquote(Macro.escape(session)))

      send(view.pid, {:game_update, :game_update, @game_id})
      assert_redirect(view, unquote(expected))
    end
  end
end
