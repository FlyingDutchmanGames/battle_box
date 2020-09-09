defmodule BattleBox.Games.Marooned.Error do
  alias BattleBox.Game.Error

  defmodule InvalidInputFormat do
    @enforce_keys [:input]
    defstruct [:input]

    defimpl Error do
      def level(_), do: :warn

      def to_human(%{input: _input}) do
        """
        You need to format it correctly
        """
      end
    end
  end

  defmodule CannotMoveIntoOpponent do
    @enforce_keys [:target]
    defstruct [:target]

    defimpl Error do
      def level(_), do: :warn

      def to_human(%{input: _input}) do
        """
        You can't move into an opponent
        """
      end
    end
  end

  defmodule CannotMoveOffBoard do
    @enforce_keys [:target]
    defstruct [:target]

    defimpl Error do
      def level(_), do: :warn

      def to_human(%{input: _input}) do
        """
        You can't move off the board
        """
      end
    end
  end

  defmodule CannotMoveIntoRemovedSquare do
    @enforce_keys [:target]
    defstruct [:target]

    defimpl Error do
      def level(_), do: :warn

      def to_human(%{input: input}) do
        """
        You can't move into a removed space!
        """
      end
    end
  end

  defmodule CannotRemoveSpaceAPlayerIsOn do
    @enforce_keys [:target]
    defstruct [:target]

    defimpl Error do
      def level(_), do: :warn

      def to_human(%{target: _target}) do
        """
        You tried to move into the same square that you're removing!!
        """
      end
    end
  end

  defmodule CannotRemoveASpaceAlreadyRemoved do
    @enforce_keys [:target]
    defstruct [:target]

    defimpl Error do
      def level(_), do: :warn

      def to_human(%{target: _target}) do
        """
        You tried to move into the same square that you're removing!!
        """
      end
    end
  end

  defmodule CannotRemoveASpaceOutsideTheBoard do
    @enforce_keys [:target]
    defstruct [:target]

    defimpl Error do
      def level(_), do: :warn

      def to_human(%{target: _target}) do
        """
        You tried to move into the same square that you're removing!!
        """
      end
    end
  end

  defmodule CannotRemoveSameSpaceAsMoveTo do
    @enforce_keys [:target]
    defstruct [:target]

    defimpl Error do
      def level(_), do: :warn

      def to_human(%{target: _target}) do
        """
        You tried to move into the same square that you're removing!!
        """
      end
    end
  end
end
