defmodule BattleBox.Utilities.HumanizeTest do
  use ExUnit.Case, async: true
  alias BattleBox.Utilities.Humanize

  test "seconds_ago_to_human_time" do
    [
      {0, "< 1 minute ago"},
      {10, "< 1 minute ago"},
      {59, "< 1 minute ago"},
      {61, "1 minute(s) ago"},
      {121, "2 minute(s) ago"},
      {2701, "45 minute(s) ago"},
      {3601, "1 hour(s) ago"},
      {36001, "10 hour(s) ago"},
      {86399, "23 hour(s) ago"},
      {86401, "1 day(s) ago"},
      {86401, "1 day(s) ago"},
      {604_801, "1 week(s) ago"},
      {184_000_001, "5 year(s) ago"}
    ]
    |> Enum.each(fn {seconds, expected} ->
      assert Humanize.humanize_seconds_ago(seconds) == expected
    end)
  end
end
