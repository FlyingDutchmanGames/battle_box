defmodule BattleBox.TestConvenienceHelpers do
  def named_proxy(name, init_func \\ nil) do
    me = self()

    spawn_link(fn ->
      if init_func, do: init_func.()

      Stream.iterate(0, & &1)
      |> Enum.each(fn _ ->
        receive do
          x -> send(me, {name, x})
        end
      end)
    end)
  end
end
