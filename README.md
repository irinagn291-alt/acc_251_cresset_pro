# Cresset

Place a book on an island and log the minutes you read.

Cresset is a reading board for people who will open a place they walk, not a percentage bar or a shelf of spines. Home is an archipelago of genre isles. Moor a volume, log minutes into a wake, then **Step** the token. There is no account, no catalog, and no Game tab.

## Architecture

Wake ADT fold. An `Isle` is a fold over sittings, not a bag of flags. Each sitting adds minutes times pace as pages onto that isle's `Wake`. The folded value is `Pooling`, `Stepped`, or `Lit`.

Pooling holds only the Wake remainder; the token does not move. **Step** spends ten Wake pages, appends one `TileMark`, and yields Stepped. The first TileMark also writes the `Lamp`, unlocks the eight-tile ring, and yields Lit. Later steps stay Lit until eight. Tile index equals `min(TileMark count, totalTiles − 1)`.

This pattern fits the product: the home verb is step-the-token. Logging only fills Wake. Analytics count TileMarks and lamps, not unread titles. A tab plus a list of sessions would be a journal clone.

Persistence is one Codable harbor document in UserDefaults (and an atomic file projection) behind `HarborStore`. Schema version 1. Views observe `HarborWatch` and never touch UserDefaults.

## Wake-then-step

This is why someone picks Cresset. Logging writes minutes onto the moored isle's Wake. Pages equal minutes times pace. The token does not walk on log. When Wake holds at least ten pages, Step writes a TileMark, spends ten, and walks one tile. A sitting that leaves Wake under ten still saves. The first TileMark lights the lighthouse and unlocks the eight-tile ring.

The Step control sits on the board. A dedicated screen, **Wake then step**, walks the same mechanic. Analytics counts TileMarks and lamps.

## Design

Soft card daylight. Palette lives in `Assets.xcassets` and is reached only through `HarborInk.Palette`: background `#FAF7F5`, surface `#FEFEFD`, ink `#392818`, accent `#CC6D19`, muted `#816C5A`. Type is SF Pro via `Font.system` in a six-step Dynamic Type scale (`LampFace.Step`). Spacing unit 8 pt. Card radius 20 pt. Chip radius 12 pt. Elevation is one soft drop shadow. Primary controls are soft cards.

Navigation is Board-tab chrome: Board, Analytics, and Settings as sibling tabs. Place and session fuse as sheets on Board.

## Art

Style: Soft 3D clay icons.

Base prompt reused for every asset:

```
Soft 3D polymer clay, matte tactile surface, rounded miniature sculpture, gentle diffused studio light, shallow depth of field, isolated subjects with real cutout edges, no glass, no flat vector, no neon, no readable text.
```

| Image set | Prompt |
| --- | --- |
| `crs_AppIcon` | A clay lighthouse cresset on a tiny island, centred, filling the canvas edge to edge, no text, no transparency, no rounded mask. |
| `crs_Splash` | A tall clay seascape of distant islets with a calm uncluttered centre band and no text. |
| `crs_Onboarding1` | A pair of hands setting a clay bound volume onto a small genre islet. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_Onboarding2` | A clay token being stepped from one island tile onto the next, mid-gesture. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_Onboarding3` | A lit clay lighthouse beside an eight-tile ring on an island, meaning accumulated. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_EmptyHome` | A vacant clay mooring ring on empty water, waiting for the first volume, calm and inviting. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_EmptyList` | An unlit clay lamp with no TileMarks beside it, empty analytics. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_CardBackdrop` | Abstract low-contrast clay water and sand filling the canvas so text can sit on top. |
| `crs_ControlFace` | The face of a small clay walking token, the Step control. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_TwistHero` | A clay token mid-step with a wake pooled behind it, Wake-then-step emblem. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_SuccessMark` | A small lit clay cresset lamp, confirmation after a Step. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_HeaderDecor` | A wide low clay band of tiny islets, header ornament, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_TokenPawn` | Isolated clay walking token, cutout. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_CressetLamp` | Isolated clay lighthouse lamp, cutout. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `crs_VacantMooring` | Isolated empty clay mooring hoop, cutout. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |

Assets are generated by the factory `assets.generate` step. This tree ships empty imagesets named as above.

## How this is not a repeat

First `reading_board` in the portfolio. Home is an archipelago you walk by stepping tiles — not a quote shelf, not a drift map, not a streak-gated fork, and not pages versus a capacity. Logging only fills Wake; Step is the persisted walk. Family math stays testable: ten pages per tile, eight tiles, pages from minutes times pace, lamp on first TileMark. No slots, barcode, or Open Food Facts.

## Build

```bash
cd Cresset
xcodegen generate
xcodebuild -scheme Cresset -destination 'generic/platform=iOS Simulator' build-for-testing
```

Bundle identifier: `com.cresset.isle`. Contact: https://cresset-isle.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `crs.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
