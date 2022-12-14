# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 25.04.2019

- Original work by Jadawin

## [2.0.0] - 01.08.2022

- Complete rework from scratch
- Added automatic support for DLC and mod units
- Improved AI limits enforcement algorithm
- Removed MCT settings from the save game
- Removed costs from unit names

## [2.1.0] - 02.08.2022

- Removed Army Limits for Cathayan Caravans and Ogre Camps
- Reduced Supply Lines values to reflect Warhammer III changes
- Tooltip texts changed to improve UX
- Technical changes:
  - Refactored code to remove hardcoded variables
  - Moved tooltip text code into a new script
  - Moved supply lines code into a new script
  - New method `is_army_punishable(military_force)` added to the CBAC lib API

## [2.2.0] - 04.08.2022

- Introduced enforcement of AI cost limits via a new automatic method
  - This new algorithm does not require manual maintenance
  - It supports all units and races by default, even the mod ones
  - It is possible it is CPU heavy / makes AI turns longer
  - Requires testing
- Fixed a bug that caused the Tooltip text to be hidden if Dynamic Costs were disabled
- Added a new Tooltip text for Dynamic Costs if the capacity has reached its maximum amount
- Technical changes:
  - New method `is_faction_punishable(faction)` added to the CBAC lib API
  - New method `is_hero(unit_key)` added to the CBAC lib API

## [2.3.0] - 04.08.2022

- Added information about unit costs in the Info button
- Added support for localization. Now the mod can be translated!
- Improved optimization, reducing AI turns time
- Fixed a bug that caused Tooltip texts to also appear on heroes without armies
- Updated CHANGELOG.md format
- Technical changes:
  - New method `gls(localised_string_key)` added to the CBAC lib API

## [2.4.0] - 05.08.2022

- Added a new MCT option: Extra points for Faction Leader
- Reordered the MCT panel

## [2.4.1] - 07.08.2022

- Greatly optimized AI limits enforcement algorithm
  - Number of CBAC (IO) calls reduced to a minimum
  - AI turns time notably reduced
- Improved logging features for better bug reports
- Added an `Enable logging` checkbox to MCT
- Added a reimbursement to AI after a downgrade is enforced
- Set the minimum value for AI Limit (Base) to 7000 points
- Renamed last MCT section into "Advanced Options"
- Fixed a bug that caused tooltip's Heroes costs to be empty
- Fixed all SFO incompatibilities
- Technical changes:
  - New method `get_unit_cost_from_key(unit_key)` added to the CBAC lib API
  - Renamed `script/campaign/mod/cbac.lua` into `script/campaign/mod/cbac-tooltip.lua`
  - Introduced and enforced a 120 chars per line limit

## [2.4.2] - 08.08.2022

- Moved logging back to the common file

## [2.4.3] - 12.08.2022

- Fixed a bug where limits were only enforced when Lua console was loaded

## [2.5.0] - 18.08.2022

- Added support for instant recruitment (i.e. Nurgle/Regiment of Renown)
- Updated versioning to reflect original work by Jadawin

## [2.5.1] - 23.08.2022

- Fixed a bug that prevented the debuff from disappearing after disbanding units
