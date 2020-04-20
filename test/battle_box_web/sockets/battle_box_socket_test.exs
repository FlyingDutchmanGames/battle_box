defmodule BattleBoxWeb.BattleBoxSocketTest do
  use BattleBoxWeb.ChannelCase

  test "you can connect a socket and ping the socket" do
    {:ok, conn} = :gun.open('localhost', 4002)
    {:ok, protocol} = :gun.await_up(conn)
    ref = :gun.ws_upgrade(conn, "/battle_box/websocket")

    receive do
      {:gun_upgrade, pid, ^ref, ["websocket"], headers} -> :upgraded
    after
      1000 -> raise "FAILED TO CONNECT"
    end

    :ok = :gun.ws_send(conn, {:text, "ping"})
    assert_receive {:gun_ws, _pid, _ref, {:text, "pong"}}
  end
end
