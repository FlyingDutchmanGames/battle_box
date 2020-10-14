defmodule BattleBox.Games.Marooned.Error do
  alias BattleBox.Games.Marooned

  defmodule Template do
    defmacro __using__(_opts) do
      quote do
        import unquote(__MODULE__), only: [decoration: 3, game_size_info: 1]
        @derive Jason.Encoder
        @enforce_keys [:msg]
        defstruct [:msg]
      end
    end

    def decoration(msg, %Marooned{turn: turn, next_player: next_player}, module) do
      error =
        module
        |> Module.split()
        |> List.last()

      """
      ====== (Debug) Marooned - #{error} ======
      Turn: #{turn}
      Player: #{next_player}
      Explanation:
      #{String.trim(msg)}

      To keep the game moving, your player will move randomly
      ====== (Debug) Marooned - #{error} ======
      """
    end

    def game_size_info(%Marooned{rows: rows, cols: cols}) do
      """
      The game board is always zero indexed and this particular ruleset has #{rows} rows,
      and #{cols} cols, The range of acceptable coordinates are as follows (inclusive)

      x -> 0..#{cols - 1}
      y -> 0..#{rows - 1}
      """
    end
  end

  defmodule InvalidInputFormat do
    use Template

    def new(%Marooned{} = game, input) do
      msg =
        decoration(
          """
          Your bot sent the following commands with an invalid format:

          #{Jason.encode!(input, pretty: true)}

          All commands must be in the following format

          #{Jason.encode!(%{"to" => "<location>", "remove" => "<location>"}, pretty: true)}

          Where <location> is an [x, y] coordinate pair, such that x and y are integers and
          within the board

          If you'd like to move to the location [0, 0] and remove the location [1, 1] you'd
          send the following JSON

          #{Jason.encode!(%{"to" => [0, 0], "remove" => [1, 1]}, pretty: true)}
          """,
          game,
          __MODULE__
        )

      %__MODULE__{msg: msg}
    end
  end

  defmodule CannotMoveToNonAdjacentSquare do
    defstruct [:target]
  end

  defmodule CannotMoveToSquareYouAlreadyOccupy do
    defstruct [:target]
  end

  defmodule CannotMoveIntoOpponent do
    defstruct [:target]
  end

  defmodule CannotMoveOffBoard do
    use Template

    def new(game, target) do
      msg =
        decoration(
          """
          Your bot sent the following as part of it's commands

          #{Jason.encode!(%{to: target})}

          This is invalid because the square you tried to move to (#{inspect(target)})
          falls outside of the field of play.

          #{game_size_info(game)}
          """,
          game,
          __MODULE__
        )

      IO.puts(msg)
      %__MODULE__{msg: msg}
    end
  end

  defmodule CannotMoveIntoRemovedSquare do
    defstruct [:target]
  end

  defmodule CannotRemoveSquareAPlayerIsOn do
    defstruct [:target]
  end

  defmodule CannotRemoveASquareAlreadyRemoved do
    defstruct [:target]
  end

  defmodule CannotRemoveASquareOutsideTheBoard do
    use Template

    def new(game, target) do
      msg =
        decoration(
          """
          Your bot sent the following as part of it's commands

          #{Jason.encode!(%{remove: target})}

          This is invalid because the square you tried to remove (#{inspect(target)})
          falls outside of the field of play.

          #{game_size_info(game)}
          """,
          game,
          __MODULE__
        )

      %__MODULE__{msg: msg}
    end
  end

  defmodule CannotRemoveSameSquareAsMoveTo do
    use Template

    def new(game, target) do
      msg =
        decoration(
          """
          Your bot sent the following

          #{Jason.encode!(%{to: target, remove: target})}

          The square you tried to remove, and the square you tried to
          move to are the same (#{inspect(target)})

          This is invalid, as you can not move into the same square you
          are removing
          """,
          game,
          __MODULE__
        )

      %__MODULE__{msg: msg}
    end
  end
end
