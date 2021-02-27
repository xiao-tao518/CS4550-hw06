defmodule BullsWeb.GameChannel do
  
  # this is from CS4550 lecture code
  
  use BullsWeb, :channel

  @impl true
  def join("game:" <> name, %{"observer" => observer}, socket) do
    join_helper(name, {observer, :observer}, socket)
  end
  
  @impl true
  def join("game:" <> name, %{"player" => player}, socket) do
    join_helper(name, {player, :player}, socket)
  end
  
  @impl true
  def join_helper(name, {player, _} = user, socket) do
    GameServer.start(name)
    GameServer.join(name, user)
    socket=socket
    |> assign(:name, name)
    |> assign(:user, player)
    view = GameServer.view(name)
    send(self(), :player_join)
    {:ok, view, socket}
  end
  

  @impl true
  def handle_in("guess", %{"number" => n}, socket) do
    name = socket.assigns[:name]
    user = socket.assigns[:user]
    GameServer.guess(name, user, n)
    view = Bulls.GameServer.view(name)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("reset", _, socket) do
    name = socket.assigns[:name]
    GameServer.reset(name)
    view = Bulls.GameServer.view(name)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("ready", _, socket) do
    name = socket.assigns[:name]
    user = socket.assigns[:user]
    GameServer.ready(name, user)
    view = Bulls.GameServer.view(name)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end
  
  defp authorized?(_payload) do
    true
  end
end
