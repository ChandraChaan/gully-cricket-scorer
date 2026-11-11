# Changelog

All notable changes to this project are documented here.

## [1.2.0] - 2026-11-11

### Added
- Five more games:
  - **Akhada Duel** (3D): one-on-one bouts in a mud pit. Punch, kick and
    block your way through tougher and tougher wrestlers.
  - **Kabaddi Raid** (3D): draw a defender's dive, dodge it, tag them and get
    home before the raid clock runs out.
  - **Gilli Danda** (3D): flick the gilli up and hit it as it crosses the
    stick. The score is the total distance.
  - **Kite Fight** (2D): sweep your string across rival kites to cut them
    before they swoop at yours.
  - **Carrom Strike** (2D): pocket coins against the clock on a full carrom
    board.

### Changed
- The app is now called **Gully Games**. It opens on a hub with every game
  and the cricket scorer.
- The cricket scorer moved to `/scorer`. Old links to `/new` and
  `/match/...` still work.

## [1.1.0] - 2026-11-11

### Added
- Gully games: four quick action games, opened from the controller icon on
  the home screen. Best scores are kept on the device.
  - **Gully Batting** (3D): time your swing against a bowler who gets quicker
    every over. Three wickets.
  - **High Catch** (3D): run the fielder under skied balls before they land.
  - **Direct Hit** (3D): aim and throw down the stumps before the runner
    makes the crease.
  - **Gully Dash** (2D): sprint down a three-lane gully dodging scooters,
    cows and potholes.

### Changed
- Android release builds are signed with the upload key when
  `android/key.properties` is present.
