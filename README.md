# Aim Trainer: Birds, Beasts & Brutes

A fast-paced shooting range / aim trainer built in **Godot 4.7**.

---

## 🎯 Gameplay & Features

1. **Target Archetypes:**
   - **Birds (250 pts base):** Fly across the upper sky in sinusoidal swooping patterns with flapping wings. Fast and small.
   - **Beasts (175 pts base):** Sprint horizontally across midground and ground paths with a galloping trot bounce.
   - **Brutes (120 pts base):** Heavy armored pop-up targets that emerge from behind barricades and sandbags. A shrinking visual countdown ring shows their dwell timer before they duck down.

2. **Distance Layers & Score Multipliers:**
   - **Far Layer:** Distant, smaller silhouette (0.48x scale), atmospheric haze, **2.4x score multiplier**.
   - **Mid Layer:** Standard size (0.78x scale), **1.5x score multiplier**.
   - **Near Layer:** Close up (1.15x scale), **1.0x score multiplier**.

3. **Subtractive Magazine & Miss Rules:**
   - Visual brass cartridge magazine at the bottom of the screen tracks remaining rounds before game over.
   - Pulling the trigger without hitting a target deducts **100 points** (down to a minimum of 0), flashes the score red, expends a round from the magazine, and triggers an escalating buzzer whose pitch rises with each consecutive miss.
   - Successfully hitting any target resets your consecutive miss counter and instantly reloads the magazine back to full capacity.
   - Depleting all rounds in the magazine ends the game:
     - **Easy:** 15 misses
     - **Medium:** 10 misses
     - **Hard:** 5 misses
     - **Custom:** 1–30 misses

4. **Streak Bonus & Escalating Audio:**
   - Landing consecutive hits builds a kill streak.
   - For every consecutive hit in a streak (streak $\ge 2$), a **1,000 pts per consecutive hit bonus** is awarded (e.g. 2nd hit = +2,000, 3rd hit = +3,000, 4th hit = +4,000).
   - Each streak bonus hit triggers a procedurally synthesized harmonic chime that climbs an ascending musical scale corresponding to the streak length.

5. **AFK Shot Countdown Timer:**
   - A shrinking progress bar directly above the bullet counter indicates remaining time to take a shot.
   - Depletes smoothly toward zero and shifts from vibrant green to warning yellow and flashing red.
   - Taking any shot (hit or miss) resets the timer back to full. Letting it hit `0.0s` ends the game.
   - Timer length scales by game mode:
     - **Easy:** 20.0s
     - **Medium:** 10.0s
     - **Hard:** 5.0s
     - **Custom:** Configurable (1.0s – 30.0s)

6. **Level Progression & Dynamic Sky:**
   - The game advances to the next difficulty level every **10 good shots (hits)**.
   - Each level increases target movement velocities, spawn frequency, and reduces brute dwell timers.
   - As speed accelerates, the shooting range sky and setting sun smoothly transition from a calm golden sunset into a fiery crimson and blood-red battle sky.

7. **Persistence & Stats:**
   - All-time high score and past match history (scores, accuracy %, hits, misses, timestamp, mode) are automatically saved to `user://scores.json`.
   - In-game viewable history log with match breakdown.

8. **Procedural Audio & Visual Polish:**
   - Built-in procedural sound synthesis (gunshot, distance-scaled target hit dings, crit chime, rising-pitch miss buzzer, pop-up cue, level up fanfare, game over cue) with zero external asset dependencies.
   - Dynamic custom crosshair with recoil kickback and hitmarkers.
   - Floating "+Points", "-100", streak, and level-up popups.
   - Recoil screen shake and smooth widescreen background overscan.

---

## 🕹 Controls

- **Left Mouse Click:** Shoot at cursor position (also resets AFK timer)
- **Escape (ESC):** Pause / Resume game or return to menu
- **F11 / Alt + Enter:** Toggle between Fullscreen and Windowed mode

---

## 🚀 How to Run

From your terminal:
```bash
cd ~/code/aimtrainer
godot
```
Or run the exported standalone release binary:
```bash
~/code/aimtrainer/build/AimTrainer.x86_64
```
