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
| `+70` … `+78` | nine operator settings, BCD — see below | the service menu steps an editor over them; the Shock operator sheet names them |
| `+79` … `+7B` | high score, BCD, **most-significant first** | compare loop walks it MSB-first against the score; shown on the P1 display in attract |
| `+7F` | credits, BCD | `LDA 407F / STA 408D` copies it to the display; counted coin by coin live |
| `+80` … `+8B` | P1–P4 scores, 3 BCD bytes each, **least-significant first** | `segMap` in the driver; Drakor's display `00 00 67` beside its HSTD `67 00 00` |
| `+8C` | ball in play | live |
| `+8D` / `+8F` | credits display / player count (swapped on the 1979-derived firmware) | live; the reset path refuses to resume with players ≥ 5 |
| `+8E` | match digit; cycles 0–9 during play | live |
| `+9E` | current player, **one bit per player** (1, 2, 4, 8; 0 in attract) — `+1E` on the 1979 board | live in four-player games on Drakor and Oba-Oba; every generation's code rotates it right until carry to get the number (Vortex `0x0445`, Drakor `0x05C9`, Shock/Oba-Oba `0x0CBE`). Declared `bits` with values 1–4. A reset-path resume gate (1981–85 only) |
| `+9F` bit 0 | game over | live; written by the reset path when it declines to resume |
| `+9F` bit 1 | tilt; set at the tilt, cleared when the next ball starts | live on all four families |

The 1979 board: display `+00`, ball `+0C`, players `+0D`, match `+0E`, credits display `+0F`,
flags `+1F`, settings `+F0`, high score `+F9`, credits `+FF`.

### The nine settings (Shock 1979 and Cosmic 1981 operator sheets; positions and defaults match every image)

| # | offset | label | allowed | default |
|---|---|---|---|---|
| 1 | `+70` | balls per game | 03–05 | 05 |
| 2 | `+71` | coinage code ("Fichas/Partida") — **coinage is here, not on DIPs**; the digits' meaning is not on either sheet | 11–14 | 11 |
| 3 | `+72` | maximum credits (credits are clamped to it at boot) | 01–09 | 06 |
| 4 | `+73` | incentive ("Incentivo") | 01, 11–14 on the sheets | **01** on the 1981+ firmware, **04** on the 1980 firmware (drakor, meteort, fireact, obaoba, obaobao) |
| 5 | `+74` | replay level 1, ×10,000 | 15–99 | per game: 17 (gemini1) to 50 (drakor) |
| 6 | `+75` | replay level 2 — annulled if equal to 5 | 15–99 | same as 5 |
| 7 | `+76` | **extra ball** score on the sheets — skipped if equal to **6**; what passing it does is per game, see below | 15–99 | same as 5 |
| 8 | `+77` | specials per game | 01–05 | 05 |
| 9 | `+78` | credits for beating the high score | 01–03 | **01** on the 1981+ sets and fireact, **02** on drakor, meteort, obaoba and shock |

Defaults are each set's own factory table, read from its ROM — the ten bytes at `0x1FF4` (`0x1BF4` on
the 1979-derived firmware) that the reset path copies in when a settings byte is not BCD; the
tenth is the high score's leading byte. A map declares a default only where all its sets agree.

The eight "Adjust" DIP switches (CH0–CH7 on the F6 page) are not settings: they are the BCD
keypad for entering a value in the service menu (CH0–3 = first digit 1/2/4/8, CH4–7 = second),
and left raised they select rule defaults — on Cosmic, CODE 5–7 pick the replay level from a fixed
table and the firmware writes it into settings 5–7 at every game start. Sources: the Shock and
Cosmic operator sheets in `backport/Manuals/` and the VPForums Taito ball-count procedure
(tutorial 89, saved beside them), which uses the same menu on every table in the roster.

**No checksum.** The integrity rule is BCD validity: at reset every settings byte goes through
`DAA`, and one non-BCD byte restores all nine from ROM. Write adjustments as BCD.

**Resume.** The firmware deliberately resumes a game in progress after a reset. Since 2026-10
PinMAME's `taito.c` marks the saved game over on load, so a table starts in attract; the maps
describe the image either way.

## Audits

`+50` … `+5F` holds eight 16-bit little-endian **binary** counters, which the firmware's statistics
display walks two bytes at a time (Vortex `0x08BB`). On Oba-Oba the counters continue past `+5F`. Identified from live captures on five games:

| offset | counter | evidence |
|---|---|---|
| `+52` | play time, in ~64 s ticks | ticks only during a game; the statistics display divides it by games played |
| `+54` | powered-on time, in ~64 s ticks | ticks in attract too (Vortex: 44, 108, 173, 237, 301 s) |
| `+56` | coins | one tick per coin, on the poll the credit rose |
| `+5C` | games played | ticks at game start; once per player — a four-player start on Oba-Oba ticked it four times as credits went 4 → 0 |
| `+5E` | credits awarded — **Oba-Oba, Drakor, Meteor, Fire Action** | one tick per credit the game gives: replay levels for whichever player is up (Oba-Oba, Meteor live), a won match (Drakor live), the credits for beating the high score (Oba-Oba live). The 1981–85 award routine uses a different address (Vortex `0x0F22` increments `+5A`; not measured), so not declared there |
| `+60` | replays awarded — **Oba-Oba, Drakor, Meteor, Fire Action** | in step with `+5E` for every replay-level award (nine on Oba-Oba, six on Meteor); did not move for the match credit on Drakor or the high-score credits on Oba-Oba |
| `+64` | high-score credits awarded — **Oba-Oba only** | 0 → 2 across a 605,893 game against a 580,000 high score (setting 09 = 2). One before/after observation |

Not measured on the 1979 window (Shock).

## Setting 7 is a per-game hook

The shared score-level routine (Vortex `0x0DBB`, Drakor `0x0E56`, Shock/Oba-Oba `0x0A5E`) treats
setting 7 as a third threshold: skipped when it equals replay level 2, otherwise once per player
per game it jumps through a vector (`0x1FCC`; `0x1BCC` on the 1979 code) into the game's own ROM.
Read from every set on file:

| hook | sets |
|---|---|
| returns immediately — the setting does nothing | vortex, heavymtl, cosmic, sharkt, stest, sureshot, gemini, gemini1, ladylukt, vegast, titan, titan1, zarza, zarza1, hawkman, hawkman1, lunelle, rally, snake, gork, voleybal, mrblack, mrblack1, fireactd, sshuttle, sshuttl1, polar |
| starts a sound and returns | drakor (live: 427,232 with the level at 180,000, no extra ball) |
| game-specific code | shock, obaoba, obaoba1, obaobao, meteort, fireact, cavnegro, cavnegr1, cavnegr2 |

Cosmic is in the first row even though its own sheet names the setting. What the third row's hooks
do has not been traced; an extra ball by score was seen on Oba-Oba.

## Not established

- What "Incentivo" means, and why the 1980 firmware's factory value (04) is outside the set the two sheets allow.
- Audits `+50`, `+58`, `+5A`: zero in every capture, including Oba-Oba sessions with coins through chutes 2 and 3, replays at both levels, an extra ball by score (200,000) and a beaten high score. `+62` and `+66` onward also stayed zero.
