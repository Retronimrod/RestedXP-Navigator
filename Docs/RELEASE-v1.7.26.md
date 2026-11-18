# RestedXP-Navigator v1.7.26

This release reduces repeated navigation calculations and improves the built-in performance report.

- The minimap now shows only the current step. Upcoming steps remain available on the world map.
- Navigator route animation pauses while the SPF bridge is enabled; your animation preference is preserved.
- HUD and minimap share travel information and selected routes for up to 0.25 seconds. Step, target and map changes invalidate cached results. Direction and distance continue updating at the existing rate.
- Reuse successful player-map and world-position lookups within the same frame.
- Avoid resetting unchanged travel HUD text and arrow rotation.
- Expand `/rxpnav perf` with HUD phases, minimap policy and version/settings details. The report opens for copying after a 30-second recording.
- Fix initialization errors in the core API and update notice encountered during testing.
- Remove the unsupported `NEW_TAXI_PATH` event and protect optional travel-event registration across client variants.
- Include SPF bridge 0.3.8 in the same package. Shortest Path Forever itself remains a separate installation.
- Updated version notices in all 12 supported client-language variants.

In the supplied 30-second movement tests, measured minimap time per update fell from 0.561 ms in v1.7.19 to 0.184 ms in v1.7.26 (about 67%). HUD time per update fell from 0.280 to 0.188 ms (about 33%). These are individual instrumented test runs, not a guaranteed FPS improvement or a measurement of all addon CPU usage; combat and an open world map were not covered by these runs. Nested timings overlap their parent sections and must not be added to the subtotal.

Thanks to T3sco for the original caching suggestions and to everyone who provided performance reports and tested the builds.
