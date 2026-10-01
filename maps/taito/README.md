# Taito do Brasil

8080 CPU. PinMAME saves one 256-byte battery-backed window as the `.nv` file: at `0x4000` on the
1980–85 boards (platform `taito`), at `0x1000` on the 1979 board (platform `taito-1979`). The
display DMA and the command DMA sit **inside** that window, so the player scores, ball in play,
credits display and the firmware's flags are all in the image. Everything below was read from
the ROM code and checked against live NVRAM captures on an AtGames ALP4K running Visual Pinball
Standalone.

## Maps

| map | firmware | sets | strongest evidence |
|---|---|---|---|
| `vortex` | 1981–85 | 29 | live games on Vortex and Mr. Black; images of sharkt, cosmic, stest |
| `drakor` | 1980 | 3 | live game on Drakor; image of meteort |
| `obaoba` | 1979 code on 1980 hardware | 2 | live game on Oba-Oba |
| `shock` | 1979 | 2 | live game and three images of Shock |

Sets listed without an image are there because their ROM references every declared address the
same way as the measured set in their family: the ten-byte settings copy from ROM, the high-score
compare loop, the credits-to-display copy, the replay routine and the game-over write. Each map's
`_notes` says which sets are which. Not mapped: `football` (ROM lost).

## Layout (offsets into the window; the 1979 board moves the display and command areas to +00/+10)

| offset | holds | how it was established |
|---|---|---|
| `+70` … `+78` | nine operator settings, BCD; `+70` balls per game | the service menu steps an editor over them; ball-in-play is compared against `+70` |
| `+74` … `+76` | replay levels 1–3, one BCD byte each, ×10,000 | compared against the two most-significant score digits; a level equal to the previous one is skipped |
| `+79` … `+7B` | high score, BCD, **most-significant first** | compare loop walks it MSB-first against the score; shown on the P1 display in attract |
| `+7F` | credits, BCD | `LDA 407F / STA 408D` copies it to the display; counted coin by coin live |
| `+80` … `+8B` | P1–P4 scores, 3 BCD bytes each, **least-significant first** | `segMap` in the driver; Drakor's display `00 00 67` beside its HSTD `67 00 00` |
| `+8C` | ball in play | live |
| `+8D` / `+8F` | credits display / player count (swapped on the 1979-derived firmware) | live; the reset path refuses to resume with players ≥ 5 |
| `+8E` | match digit; cycles 0–9 during play | live |
| `+9E` | current player, 0 in attract | live; a reset-path resume gate (1981–85 only) |
| `+9F` bit 0 | game over | live; written by the reset path when it declines to resume |
| `+9F` bit 1 | tilt; set at the tilt, cleared when the next ball starts | live on all four families |

The 1979 board: display `+00`, ball `+0C`, players `+0D`, match `+0E`, credits display `+0F`,
flags `+1F`, settings `+F0`, high score `+F9`, credits `+FF`.

**No checksum.** The integrity rule is BCD validity: at reset every settings byte goes through
`DAA`, and one non-BCD byte restores all nine from ROM. Write adjustments as BCD.

**Resume.** The firmware deliberately resumes a game in progress after a reset. Since 2026-10
PinMAME's `taito.c` marks the saved game over on load, so a table starts in attract; the maps
describe the image either way.

## Not established

- The other six settings bytes (`11 06 01 … 05 01` on every set seen) — service-menu semantics.
- Audits: `+5C` is a games-started counter (live on three generations, declared); `+A0` … `+F3` holds others that move, none identified. `+F4` … `+FF` is the last game's final display.
- The 1979 firmware's current-player byte on the 1979 board itself (Oba-Oba's, at `+9E`, is live-verified).
- Coinage is on physical DIP switches, not in NVRAM.
