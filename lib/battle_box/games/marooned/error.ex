defmodule BattleBox.Games.Marooned.Error do
  alias BattleBox.Games.Marooned

  defmodule Template do
    defmacro __using__(_opts) do
      quote do
        @derive Jason.Encoder
        @enforce_keys [:msg]
        defstruct [:msg]

        def decoration(msg, %Marooned{turn: turn, next_player: next_player}) do
          error =
            __MODULE__
            |> Module.split()
            |> List.last()

          """

          ====== (Debug) Marooned - #{error} ======
          Turn: #{turn}
          Player: #{next_player}
          Explanation:
          #{String.trim(msg)}

          To keep the game moving, your player will move to and remove
          a sqaure randomly this turn
          ====== (Debug) Marooned - #{error} ======

          """
        end
      end
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
          game
        )

      %__MODULE__{msg: msg}
    end
  end

  defmodule CannotMoveToNonAdjacentSquare do
    @enforce_keys [:target]
    defstruct [:target]
  end

  defmodule CannotMoveToSquareYouAlreadyOccupy do
    @enforce_keys [:target]
    defstruct [:target]
  end

  defmodule CannotMoveIntoOpponent do
    @enforce_keys [:target]
    defstruct [:target]
  end

  defmodule CannotMoveOffBoard do
    @enforce_keys [:target]
    defstruct [:target]
  end

  defmodule CannotMoveIntoRemovedSquare do
    @enforce_keys [:target]
    defstruct [:target]
  end

  defmodule CannotRemoveSquareAPlayerIsOn do
    @enforce_keys [:target]
    defstruct [:target]
  end

  defmodule CannotRemoveASquareAlreadyRemoved do
    @enforce_keys [:target]
    defstruct [:target]
  end

  defmodule CannotRemoveASquareOutsideTheBoard do
    @enforce_keys [:target]
    defstruct [:target]
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
          game
        )

      %__MODULE__{msg: msg}
    end
  end
end
