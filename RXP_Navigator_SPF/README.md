# RestedXP-Navigator: Shortest Path Bridge

WoW Forever test build. Install both RestedXP-Navigator and Shortest Path Forever, then extract the RXP_Navigator_SPF folder into Interface/AddOns.

Disable Shortest Path Forever's own RestedXP following before enabling the bridge. Use /rxpspf on to hand over the active Navigator target and /rxpspf off to cancel the bridge's route. The bridge starts disabled.

With the bridge enabled, the Navigator supplies the HUD arrow and the bridge disables the Shortest Path arrow and compass through SPF's registered settings. Enable the arrow in the Navigator settings. /rxpspf off restores the previous SPF display settings. The bridge defers display changes until combat ends. SPF still plans routes and displays them on its configured maps and tracker.

A separate Shortest Path journey takes priority. The bridge does not continuously restart a cleared route to the same target. If you want to restart it, use /rxpspf off followed by /rxpspf on.

Use /rxpspf route for an on-demand estimate in a Navigator-themed window. This command does not start a Shortest Path journey. Use /rxpspf off to stop the original handoff mode if you want only the estimate. The public API returns leg names and timing, not coordinates for the HUD or map.

While the bridge is enabled, it hides the active Navigator map line and its moving arrows. The Navigator still draws later steps, pins and other overlays. Enable the walking line for both maps in Shortest Path Forever. The world map keeps its original line if the active pin cannot be matched to a route point.

The Shortest Path Forever page in the Navigator settings controls activation, SPF arrow and compass visibility, and the active Navigator line on each map.

SPF journey and departure information is shown in the quest tracker while the bridge is enabled.
