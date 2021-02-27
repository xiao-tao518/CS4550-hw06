defmodule Bulls.Game do

  defp update_status(guess, secret) do
    ls = String.graphemes(secret)
    lg = String.graphemes(guess)
    Enum.zip(ls, lg)
    |> Enum.reduce(%{right_place: 0, wrong_place: 0}, fn {s, g}, 
        %{right_place: bull, wrong_place: cow} ->
      cond do
        g == s -> %{right_place: bull + 1, wrong_place: cow}
        g in ls -> %{right_place: bull, wrong_place: cow + 1}
        true -> %{right_place: bull, wrong_place: cow}
      end
    end)
    |> Map.put(:guess, guess)
  end
  
  def new(callback) do
    %{
      secret: generate_secret(),
      guesses: MapSet.new,
      info: %{},
      round: 0,
      user: %{},
      winner: %{},
      sched: callback,
    }
  end
  
    
  defp is_win(st), do: st.secret in st.guesses
  
  defp is_lose(st), do: MapSet.size(st.guesses) >= 8
  
  def add_player(st, {name, :observer}) do
    if is_registered(st, name) do
      st
    else
      %{st | user: Map.put(st.user, name, :observer)}
    end
  end
  
  def add_player(st, {name, :player}) do
     cond do
         is_registered(st, name) -> st
         st.round > 0 -> %{st | user: Map.put(st.user, name, :observer)}
         true -> %{st | user: Map.put(st.user, name, {:lobby, 0, 0})}
     end
  end
  

  def ready_player(st, name) do
    case Map.get(st.user, name) do
      {:lobby, ws, ls} ->
        result = %{
          st |
          user: Map.put(st.user, name, {:player, ws, ls}),
          guesses: Map.put(st.guesses, name, [])
        }
        
        if Enum.all?(result.participants, fn
          {_, {type, _, _}} -> type != :lobby
          _ -> true
        end) do
          st.sched.(1)
          %{result | round: 1}
        else
          result
        end
    _ -> st
    end
  end
  
  def is_registered(st, name), do: 
     name in Map.keys(st.user)
    

  def view(st) do
    success = is_win(st)
    %{
      won: success,
      lost: is_lose(st) and not success,
      info: Map.get(st, :info, ""),
      guesses: Enum.map(st.guesses, &(update_status(&1, st.secret)))
    }
  end

  
  defp generate_secret do
    secret = Enum.join(Enum.take_random(0..9, 4))
    {num, _} = Integer.parse(secret)
    if num < 1000 do
      generate_secret()
    else
      secret
    end
  end
  
  def pass(st, player) do
    pguesses = Map.get(st.guesses, player, [])
    pguesses = [{"    ", st.round} | pguesses]
    result = %{ st | guesses: Map.put(st.guesses, player, pguesses)}
    
    if is_finish(result) do
      finish_round(result, st.round)
    else
      result
    end
  end

  def guess(st, player, num) do
    digit_list = String.graphemes(num)
    cond do
      is_ready(Map.get(st.user, player, :observer)) -> %{st | info: Map.put(st.info, player, "not ready")}
      num == "    " -> pass(%{st | info: Map.put(st.info, player, "")}, player)
      Regex.match?(~r/^[1-9]\d{3}$/, num) ->
        guess_helper(%{st | info: Map.put(st.finfo, player, "")}, player, num)
      true -> %{st | info: Map.put(st.info, player, "invalid guess")}
    end
  end

  def is_ready({:player, _, _,}), do: false
  def is_ready({:observer}), do: true
  def is_ready(:lobby), do: true
  
  def guess_helper(st, player, num) do
    pguesses = Map.get(st.guesses, player, [])
    cond do
      have_guessed(st, pguesses) ->
        st
      true ->
        pguesses = [{num, st.round} | pguesses]
        result = %{st | guesses: Map.put(st.guesses, player, pguesses)}
        if is_finish(result) do
          finish_round(result, st.round)
        else
          result
        end
    end
  end
  

  
  def have_guessed(_, []), do: false
  def have_guessed(st, [{_, round} | _]), do: st.round == round
  
  def is_finish(st) do
    round_guesses = st.guesses
    |> Enum.flat_map(fn {_, gs} -> gs end)
    |> Enum.filter(fn {_, round} -> st.round == round end)
    |> Enum.count()
    players = st.user
    |> Enum.filter(fn
      {_, {r, _, _}} -> r == :player
      _ -> false
    end)
    |> Enum.count()
    round_guesses == players
  end
  
  def finish_round(st, round) do
    cond do
      st.round != round -> st
      Enum.empty?(get_winners(st)) ->
        new = st.round + 1
        guesses = st.guesses
        |> Enum.map(fn (player, guesses) -> {player, player_guess(st, guesses)} end)
        |> Enum.into(%{})
        st.sched.(new)
        %{st | guesses: guesses, round: new}
      true -> conclude(st)
      end
  end
  
  def player_guess(st, guesses) do
    if not have_guessed(st, guesses) do
      [{"    ", st.round} | guesses]
    else
      guesses
    end
  end
end
