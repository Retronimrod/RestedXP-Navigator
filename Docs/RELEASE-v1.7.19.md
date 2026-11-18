# RestedXP-Navigator v1.7.19

- Share successful player-map lookups within the same frame, keyed by fallback map.
- Share continent hierarchy lookups and player world-coordinate conversion within the same frame.
- Invalidate shared results on guide, quest, zone and death/ghost events. Failed lookups are retried.
- Skip continent hierarchy checks when player and target already share the same map.
- Use known live player coordinates for minimap and HUD distance calculation.
- Avoid unchanged style, size, label and anchor writes for future minimap markers.
- Keep overlay lines visible while updating and hide only unused pooled lines.
- Avoid unchanged normal HUD rotation and distance-text writes.
- Add separate minimap overlay and future-marker phases to the performance report.
- Preserve the update intervals and existing navigation, marker, map and bridge settings.

Verification includes frame/event cache invalidation, live movement, failed lookup recovery, future-marker visibility and 18 differential projection cases against v1.7.18. FPS impact still requires an in-game comparison.
