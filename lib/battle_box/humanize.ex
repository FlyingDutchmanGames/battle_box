defmodule BattleBox.Humanize do
  @one_minute_in_seconds 60
  @one_hour_in_seconds @one_minute_in_seconds * 60
  @one_day_in_seconds @one_hour_in_seconds * 24
  @one_week_in_seconds @one_day_in_seconds * 7
  @one_year_in_seconds @one_week_in_seconds * 52

  def humanize_seconds_ago(%NaiveDateTime{} = time_in_past) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.diff(time_in_past)
    |> humanize_seconds_ago()
  end

  def humanize_seconds_ago(seconds_ago) when is_integer(seconds_ago) do
    case seconds_ago do
      x when x in 0..@one_minute_in_seconds ->
        "Less than a minute ago"

      x when x in @one_minute_in_seconds..@one_hour_in_seconds ->
        "#{Integer.floor_div(seconds_ago, @one_minute_in_seconds)} minute(s) ago"

      x when x in @one_hour_in_seconds..@one_day_in_seconds ->
        "#{Integer.floor_div(seconds_ago, @one_hour_in_seconds)} hour(s) ago"

      x when x in @one_day_in_seconds..@one_week_in_seconds ->
        "#{Integer.floor_div(seconds_ago, @one_day_in_seconds)} day(s) ago"

      x when x in @one_week_in_seconds..@one_year_in_seconds ->
        "#{Integer.floor_div(seconds_ago, @one_week_in_seconds)} week(s) ago"

      x when x > @one_year_in_seconds ->
        "#{Integer.floor_div(seconds_ago, @one_year_in_seconds)} year(s) ago"
    end
  end
end
