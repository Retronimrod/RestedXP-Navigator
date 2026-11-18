# RestedXP-Navigator v1.7.21

- Fix Core initialization by registering the new minimap/animation policy methods after Navigator.API is created.
- This also resolves the subsequent nil API error in UpdateNotice.lua.
- Includes v1.7.20 current-step-only minimap, SPF bridge animation suppression and 10 Hz static minimap updates.

Verification loads the complete Core and all modules in TOC order with simulated WoW UI objects, then exercises the UpdateNotice login callback. In-game verification remains pending.
