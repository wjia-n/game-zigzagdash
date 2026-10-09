# Zigzag Dash — Rules

The authoritative source of truth for Zigzag Dash (`com.gameswajiha.zigzagdash`).
If the implementation ever conflicts with this document, fix the implementation.

## 1. Objective
Keep the ball rolling on the endless zigzag track for as long as possible.
Every tile the ball crosses scores points; every star the ball touches scores
bonus points. One missed turn and the ball falls off the track, ending the run.

## 2. Setup
- Pick a mode: **Endless** (no timer) or **Score Attack** (60 seconds).
- Pick a difficulty: **Chill**, **Normal**, or **Extreme** (Pro unlock).
- The ball starts on the first tile of a freshly generated track, rolling
  down-left. The run begins in the READY phase — tap anywhere to start the
  countdown, then the run.

## 3. Turn order
Single-player game: there is no turn order and no opponents. The ball rolls
continuously forward; the only actor is the player's timing.

## 4. Legal moves
- **Tap anywhere on the screen** to flip the ball's direction between its two
  diagonals: down-left and down-right.
- A tap in the READY phase starts the countdown.
- A tap in the RUNNING phase flips the direction (with squash-and-stretch
  feedback and a turn sound).
- Taps are accepted anywhere: over the track, over the HUD, anywhere.

## 5. Illegal moves
There are no illegal moves. Taps during the countdown phase or after the run
ends produce a gentle "too early" feedback sound but never change state and
never cause an error.

## 6. Captures
Stars sit on tiles along the track. Rolling over a star captures it:
- +10 × combo points (combo = consecutive stars captured, capped at ×5).
- Combo 3+ triggers a "COMBO xN!" fanfare.
- Missing a star never breaks the combo — the combo only counts captured
  stars and never resets on a miss.

## 7. Special rules
- **Countdown:** tapping in READY starts a 1.5s countdown (3-2-1) before the
  ball starts rolling.
- **Level progression:** every 400 tiles the level rises; the ball gets faster
  and corners get tighter.
- **Corner markers:** tiles where the path changes direction carry a chevron —
  pure information, they do not change the rules.
- **Pause:** pausing freezes everything mid-roll (countdown included) and
  resumes exactly where it stopped. Backgrounding the app auto-pauses.
- **Score Attack timer:** the run also ends when the 60-second timer reaches
  zero, with a happy hop animation instead of a fall.

## 8. Scoring
- +1 point per tile crossed (distance in tiles == base points).
- Stars: +10 × current combo (combo capped at ×5).
- Best scores are tracked per (mode × difficulty) combination and persisted.

## 9. Winning conditions
There is no final win — it is an endless arcade runner. The victory is
beating your personal best score for the current mode + difficulty, which
triggers a fanfare and may prompt an in-app review.

## 10. Draw conditions
Not applicable — single-player.

## 11. AI strategy
Not applicable — single-player reflex game with no opponents or bots.

## 12. Edge cases
- The ball rolling off any track edge ends the run (fall animation, then
  game-over panel).
- If the app is backgrounded mid-run, the run auto-pauses and resumes on
  return.
- If the engine's main loop ever stalls (timer cancelled, throttled, or
  threw), the watchdog timer restarts it automatically — a run can never
  freeze with no legal forward action.
- Pause is ignored on the game-over panel; resume is a no-op when not paused.
- The engine clamps speed to a maximum of 9.6 tiles/sec so runs stay playable.
- Tile pruning keeps the path bounded: tiles far behind the ball are removed
  and never affect collision again.

## 13. Test cases
1. Fresh run starts in READY; the ball bobs; no score accrues.
2. Tap in READY → 1.5s countdown with 3-2-1 tick sounds → RUNNING.
3. Tap in RUNNING flips direction; squash animation + turn sound play.
4. Tap during countdown → gentle invalid sound; state unchanged.
5. Rolling off the track → fall animation → game-over panel with
   score / stars / distance / best.
6. Rolling over a star → +10×combo points, burst particles, star sound.
7. Three stars in a row → "COMBO x3!" text + combo sound.
8. Every 400 tiles → level rises, "LEVEL N!" text, level-up sound.
9. Score Attack: timer hits 0 → hop animation → game-over panel ("TIME'S UP!").
10. Pause mid-run → everything freezes; resume continues exactly.
11. Background the app mid-run → auto-pause; foreground → resume with music.
12. New best → "NEW BEST!" badge, record fanfare, in-app review request.
13. Restart ("DASH AGAIN") → fresh run, same mode + difficulty.
14. Kill the engine loop manually → watchdog restarts it within ~1s; no stuck
    state.
15. Extreme difficulty locked without Pro; all Pro themes/balls locked without
    Pro; free selections enforced even after restore of old data.
