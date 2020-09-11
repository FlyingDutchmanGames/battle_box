defmodule BattleBox.Connection.LogicTest do
  alias BattleBox.GameEngine
  use BattleBox.DataCase, async: false
  alias BattleBox.{Repo, Connection.Logic}

  setup %{test: name} do
    {:ok, _} = GameEngine.start_link(name: name)
    {:ok, names: GameEngine.names(name)}
  end

  describe "init/1" do
    test "it adds the fact that the state is 'unauthed'", %{names: names} do
      assert %{foo: :bar, state: :unauthed, names: ^names} =
               Logic.init(%{foo: :bar, names: names})
    end
  end

  describe "PING" do
    test "sending a PING recieves a PONG" do
      assert {_data, [{:send, "\"PONG\""}], :continue} =
               Logic.handle_message({:client, "PING"}, %{})
    end
  end

  describe "authing" do
    setup do
      {:ok, key} = create_key()
      %{key: key}
    end

    test "when you use a bad key, you get told", %{names: names} do
      assert {%{state: :unauthed}, [send: "{\"error\":{\"token\":[\"Invalid API Key\"]}}"],
              :continue} =
               Logic.handle_message(
                 {:client,
                  %{
                    "bot" => "bot-name",
                    "token" => "fake-token"
                  }},
                 %{state: :unauthed, names: names}
               )
    end

    test "when you provide a bad bot name you get told", %{key: key, names: names} do
      assert {%{state: :unauthed}, [{:send, msg}], :continue} =
               Logic.handle_message(
                 {:client,
                  %{
                    "bot" => :binary.copy("A", 100),
                    "token" => key.token
                  }},
                 %{state: :unauthed, names: names}
               )

      assert %{"error" => %{"bot" => %{"name" => ["should be at most 39 character(s)"]}}} =
               Jason.decode!(msg)
    end

    test "when you provide a good name/key it starts correctly", %{names: names, key: key} do
      key = Repo.preload(key, :user)
      user = key.user

      assert {%{state: :idle}, [{:monitor, bot_server_pid}, {:send, msg}], :continue} =
               Logic.handle_message(
                 {:client,
                  %{
                    "bot" => "bot-name",
                    "token" => key.token
                  }},
                 %{state: :unauthed, names: names, connection_id: "1234"}
               )

      assert Process.alive?(bot_server_pid)

      assert %{
               "bot_server_id" => _,
               "status" => "idle",
               "connection_id" => "1234",
               "watch" => watch_links
             } = Jason.decode!(msg)

      expected = %{
        "user" => "http://localhost:4002/users/#{user.username}/follow",
        "bot" => "http://localhost:4002/users/#{user.username}/bots/bot-name/follow"
      }

      assert watch_links == expected
    end
  end

  describe "match_making" do
    setup do
      {:ok, key} = create_key()
      {:ok, arena} = marooned_arena()
      %{key: key, arena: arena}
    end

    test "match_making with an invalid arena fails", %{key: key, names: names} do
      {data, _actions, :continue} =
        Logic.handle_message(
          {:client, %{"bot" => "bot-name", "token" => key.token}},
          %{state: :unauthed, names: names, connection_id: "1234"}
        )

      {%{state: :idle}, [send: msg], :continue} =
        Logic.handle_message(
          {:client, %{"action" => "start_match_making", "arena" => "not-real-arena"}},
          data
        )

      assert %{"error" => %{"arena" => ["Arena \"not-real-arena\" does not exist"]}} =
               Jason.decode!(msg)
    end

    test "match_making with a valid arena succeeds", %{arena: arena, key: key, names: names} do
      {data, _actions, :continue} =
        Logic.handle_message(
          {:client, %{"bot" => "bot-name", "token" => key.token}},
          %{state: :unauthed, names: names, connection_id: "1234"}
        )

      {%{state: :match_making}, [send: msg], :continue} =
        Logic.handle_message(
          {:client, %{"action" => "start_match_making", "arena" => arena.name}},
          data
        )

      assert %{"status" => "match_making"} = Jason.decode!(msg)
    end
  end

  describe "practice" do
    setup do
      {:ok, key} = create_key()
      {:ok, arena} = marooned_arena()
      %{key: key, arena: arena}
    end

    test "practice with an invalid arena fails", %{key: key, names: names} do
      {data, _actions, :continue} =
        Logic.handle_message(
          {:client, %{"bot" => "bot-name", "token" => key.token}},
          %{state: :unauthed, names: names, connection_id: "1234"}
        )

      {%{state: :idle}, [send: msg], :continue} =
        Logic.handle_message(
          {:client, %{"action" => "practice", "arena" => "not-real-arena"}},
          data
        )

      assert %{"error" => %{"arena" => ["Arena \"not-real-arena\" does not exist"]}} =
               Jason.decode!(msg)
    end

    test "practice with a valid arena but invalid opponent fails", %{
      arena: arena,
      key: key,
      names: names
    } do
      {data, _actions, :continue} =
        Logic.handle_message(
          {:client, %{"bot" => "bot-name", "token" => key.token}},
          %{state: :unauthed, names: names, connection_id: "1234"}
        )

      {%{state: :idle}, [send: msg], :continue} =
        Logic.handle_message(
          {:client, %{"action" => "practice", "arena" => arena.name, "opponent" => "fake"}},
          data
        )

      assert %{"error" => %{"opponent" => ["No opponent matching (\"fake\")"]}} =
               Jason.decode!(msg)
    end

    test "practice with a valid arena succeeds", %{arena: arena, key: key, names: names} do
      {data, _actions, :continue} =
        Logic.handle_message(
          {:client, %{"bot" => "bot-name", "token" => key.token}},
          %{state: :unauthed, names: names, connection_id: "1234"}
        )

      {%{state: :match_making}, [send: msg], :continue} =
        Logic.handle_message(
          {:client, %{"action" => "practice", "arena" => arena.name, "opponent" => "kansas"}},
          data
        )

      assert %{"status" => "match_making"} = Jason.decode!(msg)
    end
  end

  test "nonsense gets and invalid_msg_sent_error" do
    assert {%{}, [send: "{\"error\":\"invalid_msg_sent\"}"], :continue} =
             Logic.handle_message({:client, "Nonsense"}, %{})
  end
end
