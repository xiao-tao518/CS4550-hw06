## Based on lecture notes
## https://github.com/NatTuck/scratch-2021-01/blob/master/4550/0219/hangman/lib/hangman/game_server.ex

defmodule Bulls.GameServer do
  use GenServer

  # public interface

  def reg(name) do
    {:via, Registry, {Bulls.GameReg, name}}
  end

  def start(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker
    }
    Bulls.GameSup.start_child(spec)
  end

  def start_link(name) do
    game = BackupAgent.get(name) || Game.new
    GenServer.start_link(
      __MODULE__,
      game,
      name: reg(name)
    )
  end

  def reset(name) do
    GenServer.call(reg(name), {:reset, name})
  end

  def guess(name, user, num) do
    GenServer.call(reg(name), {:guess, name, user, num})
  end
  
  def view(name) do
    GenServer.call(reg(name), {:view, name})
  end

  def join(name, user) do
    GenServer.call(reg(name), {:join, name, user})
  end
  
  def ready(name, user) do
    GenServer.call(reg(name), {:ready, name, user})
  end
  
  def peek(name) do
    GenServer.call(reg(name), {:peek, name})
  end


  def init(game) do
    Process.send_after(self(), :pook, 10_000)
    {:ok, game}
  end

  def handle_call({:reset, name}, _from, game) do
    game = Game.conclude(game)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:guess, name, num}, _from, game) do
    game = Game.guess(game, num)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:peek, _name}, _from, game) do
    {:reply, game, game}
  end
  
  def handle_call({:ready, name, user}, _from, game) do
    game = Game.ready_player(game, user)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end
  
  def handle_call({:join, name, user}, _from, game) do
    game = Game.add_player(game, user)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:view, name}, _from, game) do
    view = Game.view(game)
    BackupAgent.put(name, game)
    {:reply, view, game}
  end
  
  def handle_info({:maintain_round, name, round}, game) do
    game = Game.finish_round(game, round)
    view = Bulls.Game.view(game)
    BullsWeb.Endpoint.broadcast(
      "game:" <> name,
      "view",
      view)
    {:noreply, game}
  end
end
