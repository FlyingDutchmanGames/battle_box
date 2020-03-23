defmodule BattleBoxWeb.HealthControllerTest do
  use BattleBoxWeb.ConnCase, async: false

  test "the basic health check returns OK", %{conn: conn} do
    conn = get(conn, "/health")
    assert json_response(conn, 200) == %{"status" => "OK"}
  end

  test "the db health check returns OK", %{conn: conn} do
    conn = get(conn, "/health/database")
    assert %{"status" => "OK", "query_time_microseconds" => ms} = json_response(conn, 200)
    assert is_integer(ms) && ms < 10_000
  end

  test "the info health check works", %{conn: conn} do
    conn = get(conn, "/health/info")
    assert %{
      "status" => "OK",
      "uptime_milliseconds" => uptime,
      "sha" => sha
    } = json_response(conn, 200)
    assert is_integer(uptime)
    assert is_binary(sha)
  end
end
