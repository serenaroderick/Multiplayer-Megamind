defmodule HangmanWeb.GameChannel do
  use HangmanWeb, :channel

  alias Hangman.Game
  alias Hangman.GameServer

  @impl true
  def join("game:" <> name, payload, socket) do  
    GameServer.start(name)
    socket = socket
    |> assign(:name, name)
    |> assign(:user, name)
    game = GameServer.peek(name)
    view = Game.view(game, name)
    {:ok, view, socket}
  end

  @impl true
  def join("game:", payload, socket) do
    {:ok, socket}
  end

  def join("game:", _, socket) do
    send self(), :after_join
    {:ok, socket}
  end

  @impl true
  def handle_in("login", %{"name" => user}, socket) do
    socket = assign(socket, :user, user)
    view = socket.assigns[:name]
    |> GameServer.peek()
    |> Game.view(user)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("guess", %{"letter" => ll}, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
    |> GameServer.guess(ll)
    |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("reset", _, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name] # game name
    |> GameServer.reset()
    |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  intercept ["view"]

  @impl true
  def handle_out("view", msg, socket) do
    user = socket.assigns[:user]
    msg = %{msg | name: user}
    push(socket, "view", msg)
    {:noreply, socket}
  end

end
