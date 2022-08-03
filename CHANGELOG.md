# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] Initial Release - 01.08.2022

- Initial Release

## [1.1.0] Minor Update - 02.08.2022

- Removed Army Limits for Cathayan Caravans and Ogre Camps
- Reduced Supply Lines values to reflect Warhammer III changes
- Tooltip texts changed to improve UX
- Technical changes:
  - Refactored code to remove hardcoded variables
  - Moved tooltip text code into a new script
  - Moved supply lines code into a new script
  - New method `is_army_punishable(military_force)` added to the CBAC lib API

## [1.2.0] Minor Update - 04.08.2022

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
