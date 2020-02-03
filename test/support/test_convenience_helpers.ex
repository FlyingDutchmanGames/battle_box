defmodule BattleBox.TestConvenienceHelpers do
  def named_proxy(name) do
    me = self()

    spawn_link(fn ->
      Stream.iterate(0, & &1)
      |> Enum.each(fn _ ->
        receive do
          x -> send(me, {name, x})
        end
      end)
    end)
  end
end
