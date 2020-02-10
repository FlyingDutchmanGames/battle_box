import css from "../css/app.css"
import header_css from "../css/header.css"
import robot_game_css from "../css/robot_game.css"

import {Socket as PhxSocket} from "phoenix"
import LiveSocket from "phoenix_live_view"

if(window.useLiveView) {
  // only connect to liveView if the page uses it
  let liveSocket = new LiveSocket("/live", PhxSocket)
  liveSocket.connect()
}

