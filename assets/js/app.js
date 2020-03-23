import css from "../css/app.css"
import bot_css from "../css/bots.css"
import header_css from "../css/header.css"
import robot_game_css from "../css/robot_game.css"
import game_css from "../css/game.css"
import not_found_css from "../css/not_found.css"
import bot_follow_css from "../css/bot_follow.css"

import {Socket as PhxSocket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

if(window.useLiveView) {
  // only connect to liveView if the page uses it
  let liveSocket = new LiveSocket("/live", PhxSocket, {params: {_csrf_token: csrfToken}});
  liveSocket.connect()
}

