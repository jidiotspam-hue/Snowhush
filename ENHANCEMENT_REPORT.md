# Snowhush Enhanced: Behind-Windows Ledges, Blizzard Mode & Metal Upgrades

## Overview
This build enhances **Snowhush v0.5.6** with the requested architecture changes, snowfall capacity boosts tailored for Apple Silicon (M1 Max with 32-core GPU and 64 GB unified memory), and visual/performance enhancements.

---

## 1. Behind Windows Mode with Front Window Snow Accumulation
### The Architectural Challenge
Previously in Snowhush:
1. When `Behind Windows` was activated, `OverlayWindow` set its window level to `NSWindow.Level(CGWindowLevelForKey(.desktopWindow) + 1)`. Because all rendering (falling flakes, ground snow, and window ledge snow) was drawn in a single Metal view on this window, placing it behind desktop windows hid all window ledges behind the active application windows.
2. `ScreenSnow.swift` actively suppressed window polling whenever `behindWindows` was true:
   ```swift
   snowOnWindows() && !window.behindWindows ? tracker.poll(...) : nil
   ```
3. `AppDelegate.swift` disabled the "Snow on Windows" menu item and called `snow.dropWindowSnow()`.

### The Dual-Layer Overlay Solution
1. **`WindowOverlay.swift`**:
   - A dedicated overlay canvas (`OverlayWindow`) operating at `.statusBar` level (`frontLevel`), positioned in front of all application windows.
   - Hosts an offscreen-cleared `CAMetalLayer` with native display backing scale factor.
2. **`SnowSimulation.swift`**:
   - Added `var isWindow: Bool` to `PileLayer` (`layer !== ground && !layer.isDock`), allowing the renderer to discriminate between ground/dock drifts and window header piles.
3. **`Renderer.swift`**:
   - Decoupled rendering passes:
     - When `behindWindows == true`:
       - Background window (desktop level) renders ground snow + falling sprites (flakes, grains, motes).
       - Foreground `windowOverlay` (status bar level) renders window piles (`piles.filter(\.isWindow)`).
     - When `behindWindows == false`:
       - Main window stays in front and renders all snow.
       - `windowOverlay` is cleanly cleared to transparent `(0, 0, 0, 0)` and placed into an idle state with zero draw calls.
4. **`AppDelegate.swift` & `ScreenSnow.swift`**:
   - Unlocked `Snow on Windows` toggle so it stays enabled even when `Behind Windows` is checked.
   - Removed destructive `dropWindowSnow()` calls during mode switches.

---

## 2. Snowfall Capacity: Blizzard & Whiteout
Tailored for the Apple M1 Max host specs:
- **`Preferences.swift`**:
  - Expanded `Snowfall` enum with two high-volume stops:
    - **`.blizzard`**: 2,400 flakes/megapoint (~4,630 flakes on Retina XDR).
    - **`.whiteout`**: 6,000 flakes/megapoint (~11,600+ flakes on Retina XDR).
- **`SnowfallSlider.swift`**:
  - Automatically scales ticks and stops to 7 steps: `Off -> Light -> Steady -> Heavy -> Blizzard -> Whiteout -> Variable`.
- **Dynamic Capacity Allocation**:
  - Increased Metal vertex buffer reservation in `Renderer.reserve()` to `max(4096, sprites * 3 / 2)` and `max(1024, columns * 3 / 2)` to eliminate buffer reallocations during high-intensity flurries and window shake crumble events.

---

## 3. Visual & Performance Enhancements
1. **Liquid Retina XDR 2x High-DPI Rendering**:
   - Updated `Renderer.fitDrawable(of:screen:)` to multiply the layer drawable size by `screen.backingScaleFactor` (2.0 on Retina).
   - Metal point sizes and snow edge anti-aliasing compute at subpixel precision, rendering sharp crystalline structures across 3456x2234 resolution without blur.
2. **ProMotion 120 FPS Pacing**:
   - Dynamic frame pacing in `Renderer.draw(in:)`:
     - Under `PowerBudget.full` (AC power or unconstrained battery), `.lively` snowfall runs at the display's maximum refresh rate (`120 FPS`), taking full advantage of ProMotion.
     - Under `PowerBudget.saver`, gracefully drops to 60/30 FPS.
3. **Crystalline Hexagonal Metal Micro-Faceting**:
   - In `Shaders.swift`, regular flakes receive subtle 6-fold dendritic symmetry (`cos(6.0 * angle)`) and variable rotational spin based on vertex ID and elapsed time.
   - Enhanced chromatic refraction along outer flake borders.
   - Enhanced sparkle glints in `pileFragment` with multi-chromatic ice reflections.

---

## Deliverables & Paths

- **Source Code Repository**:
  [`/Users/alexisgrimmace/Documents/AI_Outputs/snowhush_enhanced`](file:///Users/alexisgrimmace/Documents/AI_Outputs/snowhush_enhanced)
- **Built Universal App Bundle (`.app`)**:
  [`/Users/alexisgrimmace/Documents/AI_Outputs/snowhush_enhanced/build/Snowhush.app`](file:///Users/alexisgrimmace/Documents/AI_Outputs/snowhush_enhanced/build/Snowhush.app)
- **Build Script**:
  [`/Users/alexisgrimmace/Documents/AI_Outputs/snowhush_enhanced/build.sh`](file:///Users/alexisgrimmace/Documents/AI_Outputs/snowhush_enhanced/build.sh)

---

## How to Run

Launch directly from the terminal or open in Finder:

```bash
open /Users/alexisgrimmace/Documents/AI_Outputs/snowhush_enhanced/build/Snowhush.app
```
