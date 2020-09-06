defmodule BattleBoxWeb.Sockets.BattleBoxSocketTest do
  use BattleBoxWeb.ChannelCase

  defmacrop assert_recieve_msg(conn, msg) do
    quote do: assert_receive({:gun_ws, ^unquote(conn), _ref, {:text, unquote(msg)}})
  end

  test "You get an invalid json error message" do
    {:ok, conn} = connect()
    :ok = :gun.ws_send(conn, {:text, "{NOT VALID JSON!!!"})
    assert_recieve_msg(conn, msg)
    assert %{"error" => "invalid_json"} == Jason.decode!(msg)
  end

  describe "ping" do
    test "you can ping the socket with just the bytes ping" do
      {:ok, conn} = connect()
      :ok = :gun.ws_send(conn, {:text, "ping"})
      assert_recieve_msg(conn, "pong")
    end

    test "you can ping the socket with the json encoded \"ping\"" do
      {:ok, conn} = connect()
      :ok = send_msg(conn, "ping")
      assert_recieve_msg(conn, "pong")
    end
  end

  defp send_msg(conn, msg) do
    msg = Jason.encode!(msg)
    :ok = :gun.ws_send(conn, {:text, msg})
  end

  defp connect do
    {:ok, conn} = :gun.open('localhost', 4002)
    {:ok, :http} = :gun.await_up(conn)
    ref = :gun.ws_upgrade(conn, "/battle_box/websocket")

    receive do
      {:gun_upgrade, ^conn, ^ref, ["websocket"], _headers} -> :upgraded
    after
      1000 -> raise "FAILED TO CONNECT"
    end

    {:ok, conn}
  end
end
