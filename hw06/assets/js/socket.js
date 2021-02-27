import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: ""}});
socket.connect();

let gameState = {
  guesses: [],
  won: false,
  lost: false,
  info: "",
  user: [],
  winner: [],
  lobby: true,
};


function state_update(st) {
  gameState = st;
  if (callback) {
    callback(st);
  }
}

export function ch_join(cb) {
  callback = cb;
  callback(gameState);
}

export function ch_start(game, user) {
    ch = socket.channel(`game:$game`, user);
    ch
      .join()
      .receive("ok", state_update)
      .receive("error", resp=> console.log("Unable to Join", resp));
    ch.on("view", state_update);
}

export function ch_push(type, msg) {
  channel.push(type, msg)
    .receive("ok", state_update)
    .receive("error", resp => console.log("Unable to push", resp));
}

channel.join()
  .receive("ok", state_update)
  .receive("info", resp => console.log("Unable to join", resp));
