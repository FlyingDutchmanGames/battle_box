defmodule BattleBoxWeb.HealthController do
  use BattleBoxWeb, :controller
  alias BattleBox.Repo

  @sha (case(System.cmd("git", ["rev-parse", "HEAD"])) do
          {sha, 0} -> String.trim(sha)
          {_, _} -> "Unable to get version"
        end)

  def health(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{status: "OK"})
  end

  def info(conn, _params) do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)

    conn
    |> put_status(200)
    |> json(%{
      sha: @sha,
      status: "OK",
      uptime_milliseconds: uptime_ms
    })
  end

  def db(conn, _params) do
    start = System.monotonic_time()

    case Repo.query("select 1 as success;") do
      {:ok, %{rows: [[1]]}} ->
        duration =
          System.convert_time_unit(System.monotonic_time() - start, :native, :microsecond)

        conn
        |> put_status(200)
        |> json(%{status: "OK", query_time_microseconds: duration})

      {:error, _} ->
        conn
        |> put_status(500)
        |> json(%{status: "ERROR"})
    end
  end
end
