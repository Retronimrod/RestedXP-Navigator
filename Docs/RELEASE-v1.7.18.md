# RestedXP-Navigator v1.7.18

- Accept valid player-map coordinates before probing fallback map hierarchies.
- Coalesce RestedXP refresh messages and avoid redundant theme, layout and settings refreshes.
- Cache objective text and type for up to 0.1 seconds with quest and guide invalidation.
- Cache grind goal parsing for up to 0.25 seconds, keeping XP and completion checks live.
- Reuse world-marker target metadata for up to 0.1 seconds.
- Avoid quest-log scans when group announcements cannot be sent.
- Reuse visible future minimap regions instead of hiding all of them before every redraw.
- Expand /rxpnav perf with map resolution, route planning, overlays, quest messages, SPF and event measurements.
- Add a 30-second performance recording button under Advanced. The report opens for copying when recording finishes.
- Retain the v1.7.17 target box toggle.

Performance work incorporates the caching approach suggested by T3sco, adapted to the current return values and lifecycle.
https://gist.github.com/t3sco/c511c0fbea6666780dad0713a2bcb3e5

Run one recording while moving with the world map closed, then a second with the world map open. Copy each report before the next recording. Nested measurements overlap parent sections and must not be added to the subtotal. The subtotal covers the instrumented sections, rather than all addon CPU or render/GPU work.
