# CivHaven

An open-source, turn-based **4X strategy game** for iOS/iPadOS — explore a procedurally
generated hex world, found cities, research technology, and conquer AI rivals. Built in
pure SwiftUI (Canvas renderer, no game-engine dependencies) so it compiles headlessly and
ships as an **unsigned `.ipa`** via GitHub Actions.

> Independent project inspired by the 4X genre. Not affiliated with or derived from
> Sid Meier's Civilization. No third-party assets or code.

<img src="Resources/icon.svg" width="96" align="right" />

## What's in this build

- **Procedural hex map** — elevation + latitude biomes: ocean, coast, grassland, plains,
  desert, tundra, snow, hills, mountains; forests/jungles; bonus resources. Deterministic
  seeds → reproducible maps.
- **Units** — settlers, warriors, workers, archers (ranged), spearmen, horsemen — each with
  movement, HP, and combat strength. Dijkstra pathfinding over terrain movement cost.
- **Cities** — found on settleable land, work surrounding tiles for food/production/gold,
  grow population, and build a queue of units + structures (granary, walls, library,
  barracks).
- **Tech tree** — 8 interlinked technologies that unlock units and buildings.
- **Combat** — strength-vs-strength with HP, terrain/fortify bonuses, ranged attacks, and
  city assault + capture.
- **Fog of war** — tiles are revealed as your units explore.
- **AI opponents** — settle, expand, build, and march on the nearest enemy.
- **Win condition** — last civilization standing.

## Play

Main menu → pick a map size, number of opponents, and an optional seed → **New Game**.

- **Tap a unit** to select it; tap a highlighted tile to move (movement range is shaded).
- Walking into an enemy attacks it; into an enemy city assaults it.
- **Settler → Found City.** **Combat unit → Fortify** for a defensive bonus.
- Open a city to set production; open **Tech** to choose research.
- **End Turn** to let cities grow, research advance, and the AI act.

## Build it yourself

Requires macOS + Xcode 15/16 and [XcodeGen](https://github.com/yonyz/XcodeGen).

```bash
brew install xcodegen
xcodegen generate            # creates CivHaven.xcodeproj from project.yml
open CivHaven.xcodeproj       # run on a simulator or device from Xcode
```

### Unsigned IPA (command line)

```bash
xcodegen generate
xcodebuild -project CivHaven.xcodeproj -scheme CivHaven \
  -configuration Release -sdk iphoneos -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO clean build
mkdir -p Payload && cp -R build/Build/Products/Release-iphoneos/CivHaven.app Payload/
zip -qr CivHaven.ipa Payload
```

## CI / Releases

`.github/workflows/build-ipa.yml` builds an unsigned IPA on every push to `main`, on every
`v*` tag, and on manual dispatch.

- **Push a tag** (`git tag v1.0.0 && git push --tags`) to build **and attach the IPA to a
  GitHub Release** automatically.
- Manual runs upload the IPA as a workflow **artifact** (and to a Release if you pass a tag).

The IPA is **not code-signed** — install it with LiveContainer, AltStore, SideStore, or your
own signing setup.

## Project layout

```
Sources/CivHaven/
  CivHavenApp.swift        app entry + main menu
  Models/                  HexCoord, Terrain, Tile, Unit, City, Player, Tech
  Engine/                  GameMap (procgen), Pathfinder, GameState, AIController
  Views/                   HexMapView, HUDView, CityView, TechTreeView, GameView
Resources/                 Info.plist, Assets.xcassets, icon.svg
project.yml                XcodeGen project definition
```

## License

MIT — see [LICENSE](LICENSE).
