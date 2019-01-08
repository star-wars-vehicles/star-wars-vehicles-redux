# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning].
This file uses change log convention from [Keep a CHANGELOG].

## [Unreleased]
### Changed
- Changing weapons internally to support more options.

## [0.3.0] - 2019-01-08
### Changed
- Changed all NWVars to use NW2Vars instead, as per recommendation.
- Changed `ENT:PhysicsSimulate` again, splitting into even more methods to support vehicle states.
- Changed `ENT:Takeoff` to support new vehicle states.
- Changed `ENT:Land` to support new vehicle states.
- Changed `ENT:CalcFirstPersonView` and `ENT:CalcThirdPersonView` to accept the player as a second argument.

### Added
- Added new state enumerations under `swvr.enum.State`.
- Added `ENT:GetVehicleState` and `ENT:SetVehicleState`.
- Added `ENT:SimulateIdle`. This is the default behavior upon spawning and when landed.
- Added `ENT:SimulateTakeoff`. This controls the physics interactions when taking off.
- Added `ENT:SimulateLanding`. This controls the physics interactions when landing.
- Added helper function `ENT:IsTakingOff`.
- Added helper function `ENT:IsLanding`.

### Fixed
- `ENT:GetCooldown` will now return `-1` instead of `nil` if the cooldown has not ever been set.

## [0.2.0] - 2019-01-04
### Changed
- Changed `ENT:PhysicsSimulate` to split into two new methods `ENT:SimulateThrust` and `ENT:SimulateAerodynamics`.
### Added
- Added internal function `ENT:SimulateThrust`.
- Added internal function `ENT:SimulateAerodynamics`.

## [0.1.1] - 2019-01-04
### Changed
- Changed `.travis.yml` to alert development server on build status.

## [0.1.0] - 2019-01-04
### Added
- Added CHANGELOG.md file to repository for easy release tracking.

[Keep a CHANGELOG]: http://keepachangelog.com
[Semantic Versioning]: http://semver.org/

[unreleased]: https://github.com/DoctorJew/star-wars-vehicles-redux/compare/0.2.0...HEAD
[0.2.0]: https://github.com/DoctorJew/star-wars-vehicles-redux/compare/0.1.1...0.2.0
[0.1.1]: https://github.com/DoctorJew/star-wars-vehicles-redux/compare/0.1.0...0.1.1
