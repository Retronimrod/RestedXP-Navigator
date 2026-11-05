# RestedXP-Navigator v1.7.0-beta.3

Fixes hearthstone binding steps being displayed as hearthstone-use instructions.

- RestedXP home/bindlocation commands are innkeeper interactions, not teleport actions.
- The dedicated Use your Hearthstone announcement now only applies to actual use steps. Binding keeps normal target navigation and the guide instruction instead of replacing it with a teleport prompt.
- Shared bind/use recognition handles parsed and normalized tags plus English/German text fallbacks. Binding text is checked before generic Hearthstone-to text.
- Includes the local raid-symbol appearance and group toolbar from beta.2.

Validation: mocked regressions cover the Crossroads/Innkeeper Boorand active-step case, binding tags, sibling scanning, normalized tags, localized text, completed steps and real hearthstone use. Client verification remains required.
