defmodule BattleBox.GameEngine.PubSub do
  use Supervisor

  def start_link(%{names: names} = opts) do
    Supervisor.start_link(__MODULE__, opts, name: names.pubsub)
  end

  def init(%{names: names}) do
    children = [{Registry, keys: :duplicate, name: registry_name(names.pubsub)}]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def broadcast(pubsub, topic, message) do
    Registry.dispatch(registry_name(pubsub), topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, message)
    end)
  end

  def subscribe(pubsub, topic) do
    Registry.register(registry_name(pubsub), topic, [])
  end

  defp registry_name(pubsub_name) do
    Module.concat(pubsub_name, Registry)
  end
end
