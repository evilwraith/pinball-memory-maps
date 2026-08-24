# Williams System 6

## HSTD display
At the end of the game, the machine alternates one of the player score
displays with the current High Score To Date (HSTD).  It backs that
player score up at 0x70.

I originally assumed it always shows the HSTD in the Player 1 position,
but during Visual Pinball testing with Algar, I witnessed it using
the Player 3 and Player 4 positions.

If attempting to read scores from memory during "game over", it will be
important to watch for the HSTD taking the place of an actual player's
score in any position.  We could encode this in the map somehow, using
the lamp matrix.  When bitmask 0x80 at address 0x17 is set, the game is
showing the HSTD.

Later eras of games display the HSTD in all player positions, which
makes it easier to detect.

Note: Firepower (and possibly other games) doesn't back up the tens
digit to 0x72, so the game always shows 00 for that player's score
during attract mode.
