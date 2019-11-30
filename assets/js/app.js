import css from "../css/app.css"

import {Socket as PhxSocket} from "phoenix"
import LiveSocket from "phoenix_live_view"

if(window.useLiveView) {
  // only connect to liveView if the page uses it
  let liveSocket = new LiveSocket("/live", PhxSocket)
  liveSocket.connect()
}

