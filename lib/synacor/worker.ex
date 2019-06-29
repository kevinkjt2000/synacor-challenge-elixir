defmodule Synacor.Worker do
  use GenServer

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    schedule()
    {:ok, state}
  end

  defp schedule(time \\ 1000) do
    :timer.sleep(time)
    send(self(), :loop)
  end

  def handle_info(:loop, state) do
    schedule()
    {:noreply, state}
  end
end
