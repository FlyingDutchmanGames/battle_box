defmodule BattleBox.Connection.LogicTest do
  use ExUnit.Case, async: true
  alias BattleBox.Connection.Logic

  describe "init/1" do
    test "it adds the fact that the state is 'unauthed'" do
      assert %{foo: :bar, state: :unauthed} == Logic.init(%{foo: :bar})
    end
  end

  describe "PING" do
    test "sending a PING recieves a PONG" do
      assert {_data, [{:send, "\"PONG\""}], :continue} =
               Logic.handle_message({:client, "PING"}, %{})
    end
  end
end
