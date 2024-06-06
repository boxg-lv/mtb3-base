# MTB3 Demo

[![sampctl](https://img.shields.io/badge/sampctl-mtb3_demo-2f2f2f.svg?style=for-the-badge)](https://github.com/boxg-lv/mtb3-demo)

Showcase for SA-MP tournament base. Fully compatible with OpenMP. Contains various advanced features such as:
- Saves player progress after disconnect
- Saves player progress after server crash or shutdown
- Option to create checkpoint/race checkpoint/pickup race in mixed order and combined together
- Option to spawn a player in a vehicle and preserve entering speed and direction (even after disconnect and server crash)
- Saves player used vehicle and allows to create vehicle progressions
- Option to add vehicle locks to prevent players from randomly finding vehicles all over the map
- Single-player style mission objective text, tooltip box, position text box and finish text box
- Advanced spectating system for players that have finished the race
- Spectating system that follows the player and switches spectating mode based on player state
- Warmup mode before race start
- Spawning to previous checkpoint with option to override spawning checkpoint per player score
- Large skin selection
- Animated /kill sequence
- Prevents /kill when not standing on ground
- Option to make entering a checkpoint with a vehicle mandatory
- Per player pickups with progress saving
- Various sound effects on certain actions
- Debugging tools such as /setscore
- Much more

The demo contains advanced tournament features that are included in "mtb3-demo", but not included in "mtb3-base":
- Randomly generated "mine field" using explosive barrels and drunk level (also contains spawning behavior override)
- Randomly spawning "bomb field" that predicts player movement, even when drifting
- Pickup search using "signal" with sound and a progress bar
- Winner's lounge
- Easter egg locations with /poi
- Helpful tooltips on certain checkpoints

## Installation

Pull the project:
```bash
git clone https://github.com/boxg-lv/mtb3-demo.git
```

> :warning: Code does not contain the file scriptfiles/colandreas/ColAndreas.cadb! You need to generate your own file using the [ColAndreasWizard.exe](https://github.com/Pottus/ColAndreas/releases) and place the generated file in scriptfiles/colandreas/ColAndreas.cadb!


Use sampctl to build the code:
```bash
sampctl ensure
sampctl build
```

Start the server:
```bash
sampctl run
```

## Usage

In your server's console, set a RCON password (if not already set):
```bash
rcon_password <your_rcon_password>
```

In game, login with RCON:
```bash
/rcon login <your_rcon_password>
```

In game, start the tournament:
```bash
/start
```

Or you can restart the tournament (resets players score) when in game:
```bash
/restart
```

In game, read about more useful commands:
```bash
/info
```