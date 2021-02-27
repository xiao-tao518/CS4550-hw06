import React, { useState, useEffect } from 'react';
import { ch_join, ch_push } from './socket';



function gameLobby({gameState, joinPlayer, joinObserver, setGameState}) {
    const [names, setNames] = useState({game: "", name: gameState.player});
    
    function updateGameName(ev) {
      setNames({game: ev.target.value, name: names.name});
    }
    
    function updateUserName(ev) {
      setNames({game: names.game, name: ev.target.value});
    }

    function renderUser(name, role, winCount, lossCount) {
        return (
        <tr>
          <td>{name}</td>
          <td>{role}</td>
          <td>{winCount}</td>
          <td>{lossCount}</td>
        </tr>
        );
    }
    
    function keyPress(ev) {
      if (ev.key === "Enter") {
        joinPlayer();
      }
    }
    
    function ready() {
      ch.push("ready", "");
    }
    
    function updatePlayerState() {
      joinPlayer(names.game, names.name);
    }
    
    function updateObserverState() {
      joinObserver(names.game, names.name);
    }
    
    let renderLogin = (
   <div>
      <div className="row">
        <div className="column">
                  <input
            type="text"
            value={names.game}
            onChange={updateGameName}
            onKeyPress={keyPress}
          />
        </div>
        <div className="column">
         <p>Game Name:</p>
        </div>
        <div className="column">
        <input
            type="text"
            value={names.name}
            onChange={updateUserName}
            onKeyPress={keyPress}
          />
        </div>
        <div className="column">
          <p>User Name:</p>
        </div>
      </div>
      <div className="row">
        <div className="column">
          <p>
          <button onClick={joinPlayer}>player</button>
          </p>
          <p>
          <button onClick={joinObserver}>observer</button>
          </p>
        </div>
      </div>
    </div>
    
      if (names.name in gameState.user) {
    if (gameState.user[names.name][0] == "Player") {
      header = (
          <div>
            <table>
        <thead>
          <tr>
            <th>Username</th>
            <th>role</th>
            <th>Wins</th>
            <th>Losses</th>
          </tr>
        </thead>
        <tbody>
          {Object.entries(gameState.participants).map((player) =>
            renderUser(player[0], player[1][0], player[1][1], player[1][2])
          )}
        </tbody>
      </table>
        <div>
        <button onClick={ready}>Ready</button>
        </div>
      </div>);
    } else {
      header = <h2>waiting for players</h2>;
    }
  } else {
    header = renderLogin;
  }

  return (
    <div>
      {header}
    </div>
  );
}


function BullGame({reset, gameState, setGameState}) {
  const [input, setInput] = useState("");

  function guess() {
      var input_list = input.split('');
      if (new Set(input_list).size != 4) {
	  return
      }
      ch_push("guess", {number: input});
      setInput("");
  }
  
  function pass() {
      ch_push("guess", {number:"    "});
  }

  function keyPress(ev) {
    if (ev.key === "Enter") {
      guess();
    }
  }
  
  function updateGuess(ev) {
    setInput(ev.target.value);
  }



  function render(guess, index) {
    return (
      <tr key={index}>
        <td>{index + 1}</td>
        <td>{guess.guess}   {`${guess.right_place}A${guess.wrong_place}B`}</td>
      </tr>
    );
  }
  
  return (
      <div>
        <div className="row">
		  <div className="column">
		    <p>Four digit number</p>
		    <p>
		      <input type="text"
		             value={input}
		             onChange={updateGuess}
		             onKeyPress={keyPress} />
		    </p>
		  </div>
	          <div classNmae="column">
		  <p>
		      <button onClick={guess}>Guess</button>
		      <button onClick={() => {reset(); setInput("");}}>Reset</button>
                  </p>
	          </div>
	 </div>
         <h2>reports</h2>
	 <p>A stands for correct and B stands for misplace</p>
	 <div className="row">
            <p>
	      {gameState.guesses.map((guess, index) => render(guess, index))}
	    </p>
	 </div>
       </div>
  );
}

function Bulls() {
  const [gameState, setGameState] = useState({
    guesses: [],
    winner: [],
    user: [],
    player: "",
    ready: true,
  });
  
    function setGameStateWOName(st){
      let new_state = Object.assign(st, {player: gameState.player})
      setGameState(new_state)
    }

  useEffect(() => ch_join(setGameStateWOName));

  function reset() {
    ch_push("reset", "");
  }
  
  function updateName(name) {
      let st = gameState
      st.player = name
      setGameState(st)
  }
  
  function addPlayer(game, name) {
    updateName(name)
    ch_start(game, {player: name});
  }
  
  function addObserver(game, name) {
    updateName(name)
    ch_start(game, {observer: name});
  }

  if (gameState.ready) {
    return (
        <gameLobby
            gameState={gameState}
            setGameState={setGameState}
            addPlayer={addPlayer}
            addObserver={addObserver}
            />
    );
  } 
  else {
    return (
        <BullGame reset={reset}
                           gameState={gameState}
                           setGameState={setGameState}/>
           );
  }
}

export default Bulls;
