# RestedXP-Navigator v1.7.20

- The minimap displays the current RestedXP step only. Future step markers, connecting lines and future-step overlays are no longer computed there.
- Keep upcoming steps on the world map, using the configured future-step count.
- Pause Navigator route animations on both maps while the SPF bridge is enabled and its API is available.
- Preserve the saved animation preference and resume it when the bridge is disabled.
- Refresh the minimap at 10 Hz while static and at the existing 20 Hz while animated.
- Continue refreshing the HUD arrow at 20 Hz.
- Respect the bridge's active-minimap-line display setting directly in the minimap renderer.
- Remove the obsolete future-step minimap controls and add translated explanations in all 12 client variants.
- Include the effective minimap interval and animation state in /rxpnav perf.

The package contains SPF bridge 0.3.8. SPF's own path rendering is controlled by SPF. In-game performance measurements are needed to quantify the effect.
