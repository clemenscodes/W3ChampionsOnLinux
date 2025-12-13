# Warcraft III – Keyboard-First Control System (Hyprland)

This setup exists because I got tired of fighting the interface.

Not the opponent.  
Not the game mechanics.  
The interface.

Warcraft III asks for a lot of micro and macro at the same time, and most of that effort usually goes into _moving your hands around_ and _aiming at UI elements_, not into actual decisions. I wanted to change that.

The core idea is very simple and never changes:

Every action follows the same internal flow:  
**select → act → commit**

If that flow is consistent, your hands stop thinking.  
And once your hands stop thinking, your head is finally free to play the game.

---

## Hand Position and Core Layout

My left hand never leaves its home position.

Fingers rest on **ASDF**, always.  
The **F key** is the physical anchor that tells me where my hand is without looking.

From that position, everything important is reachable without stretching, lifting, or repositioning the hand. This is not about speed in isolation. It’s about reliability under pressure.

The entire layout is built around a **3×4 grid**:

Q W E R  
A S D F  
Y X C V

This grid isn’t arbitrary. Warcraft III already uses grids everywhere:

- abilities and commands
- inventory
- unit cards
- autocasts

Instead of translating what I see on screen into some abstract keybind, I just mirror the position. If something is top-left on the screen, it’s top-left on the keyboard.

You don’t remember keybinds.  
You remember where things live.

---

## Modifiers and Layers

The setup uses very few modifiers, and each one has a clear purpose.

`$mod` is **Caps Lock**, remapped via xremap:

- Caps tapped → `ESC`
- Caps held → layer modifier

This lets me keep Escape exactly where I need it (for Vim muscle memory) while also gaining a very strong, easy-to-hit modifier.

The mental rules are simple:

- No modifier → select something
- `$mod` → operate on the current selection
- Shift → commit, toggle, or explicitly change state

This makes accidental inputs very unlikely, even when things get messy.

---

## Modes

There are two relevant modes.

From NORMAL mode, `Ctrl + W` enters WARCRAFT mode.  
From WARCRAFT mode, `Alt + W` exits back to NORMAL.

WARCRAFT mode contains everything game-related.  
NORMAL mode stays clean and predictable.

I don’t mix responsibilities between modes.

---

## Control Groups (Selection)

Control groups are selected like this:

| Key      | Group |
| -------- | ----- |
| 1        | 1     |
| 2        | 2     |
| 3        | 3     |
| 4        | 4     |
| 5        | 5     |
| $mod + 1 | 6     |
| $mod + 2 | 7     |
| $mod + 3 | 8     |
| $mod + 4 | 9     |
| $mod + 5 | 0     |

Groups 1–5 are combat-facing and high-frequency.  
Groups 6–0 are macro and infrastructure.

The important part is not the numbers themselves, but that the **meaning of each group never changes** during a game. Once learned, this mapping stays valid from minute one to the very end.

---

## Control Group Commit

Selecting a control group and _writing_ to a control group are two different actions on purpose.

| Key                 | Action                                 |
| ------------------- | -------------------------------------- |
| Shift + Mouse Extra | Commit current selection to last group |

I first select the group I want to work with.  
Then I select units.  
Only when I explicitly commit do I overwrite the group.

This prevents accidental group destruction in fights and makes control group management much more intentional.

---

## Camera Control

| Key                | Action              |
| ------------------ | ------------------- |
| Shift + Mouse Side | Camera back to base |

This replaces awkward keyboard reaches or minimap clicks.  
It’s fast, reliable, and easy to hit without thinking.

---

## Heroes

| Key      | Hero   |
| -------- | ------ |
| $mod + Q | Hero 1 |
| $mod + A | Hero 2 |
| $mod + Y | Hero 3 |

Heroes are some of the most frequently accessed units in the game.  
They live right next to the hand anchor, so selecting them never interrupts flow.

---

## Inventory (3×2 Grid)

The inventory follows the exact same spatial logic as abilities.

| Key      | Item   |
| -------- | ------ |
| $mod + W | Item 1 |
| $mod + E | Item 2 |
| $mod + S | Item 3 |
| $mod + D | Item 4 |
| $mod + X | Item 5 |
| $mod + C | Item 6 |

Again, this isn’t about remembering which item is where.  
It’s about knowing that “top right” is always the same gesture.

---

## Precision Unit Selection (SELECT Mode)

Sometimes you don’t want a whole group.  
You want _that one unit_.

A wounded Fiend.  
A Statue that needs to move.  
A Siege unit that must not die.

For that, I use a dedicated SELECT mode.

Pressing **Space** enters SELECT mode.  
Space is not a modifier; it’s a short-lived context.

| Key   | Action            |
| ----- | ----------------- |
| Space | Enter SELECT mode |

Any valid selection immediately exits SELECT mode again.

---

### Unit Selection Grid (2×6)

This maps directly to the in-game unit card.

Top row (units 1–6):

| Unit | Key         |
| ---- | ----------- |
| 1    | Q           |
| 2    | W           |
| 3    | E           |
| 4    | R           |
| 5    | T           |
| 6    | Mouse Extra |

Bottom row (units 7–12):

| Unit | Key        |
| ---- | ---------- |
| 7    | A          |
| 8    | S          |
| 9    | D          |
| 10   | F          |
| 11   | G          |
| 12   | Mouse Side |

The mouse does not have to move for this.

---

## Autocast / Toggle Abilities

Autocasts are mapped to **Shift** on the same 3×4 grid as abilities.

| Key       | Slot |
| --------- | ---- |
| Shift + Q | Q    |
| Shift + W | W    |
| Shift + E | E    |
| Shift + R | R    |
| Shift + A | A    |
| Shift + S | S    |
| Shift + D | D    |
| Shift + F | F    |
| Shift + Y | Y    |
| Shift + X | X    |
| Shift + C | C    |
| Shift + V | V    |

This keeps toggles consistent without polluting the main interaction layer.

---

## Chat

| Key   | Action    |
| ----- | --------- |
| Enter | Open chat |

In CHAT mode:

| Key   | Action       |
| ----- | ------------ |
| Enter | Send message |
| ESC   | Close chat   |

Chat is isolated so it never interferes with gameplay muscle memory.

---

## Control Group Roles

Control groups are semantic. They represent _roles_, not unit types.

- Group 1: main army
- Group 2: hero core
- Group 3: support and casters
- Group 4: ranged DPS
- Group 5: siege and specialists

Macro groups:

- Group 6: unit production buildings
- Group 7: town halls and economy
- Group 8: tech and upgrades
- Group 9: altar and hero production
- Group 0: workers, repairs, emergencies

---

## Why This Works in Practice

The biggest change this setup makes is replacing **spatial clicking** with **semantic selection**.

Instead of:

- looking for something
- moving the mouse
- clicking carefully

you address things by position in a known structure:

- Hero 1 is always `$mod + Q`
- Top-left action item is always `Q`
- Third unit in a selection is always `Space + E`

This enables sequences that are extremely hard to do reliably with the mouse alone.

For example, as Undead:

- `$mod + Q` selects the Death Knight
- `Q` activates Coil
- `Space + E` selects the third unit in the current selection

No camera movement.  
No mouse travel.  
No searching.

The mouse stays where it matters: movement, positioning, camera control.

---

## Final Note

This setup doesn’t play the game for you.  
It doesn’t reduce actions. In many cases, it actually increases them.

What it removes is _interface friction_.

Once the interface stops demanding attention, what’s left is Warcraft itself:  
strategy, timing, positioning, and experience.

That’s where the game is actually decided.
