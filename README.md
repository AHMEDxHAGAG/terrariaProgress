# Terraria Progress

Terraria (GOG build) save data for the `SweetHome` world and the `Hagag`
character — everything needed to continue the same playthrough on another
machine. Same files as `~/My-Configs/.local/share/Terraria/`.

## What's here

| File | What it is |
|---|---|
| `Worlds/SweetHome.wld` | The world — all terrain, chests, NPCs, bosses killed |
| `Players/Hagag.plr` | The character — inventory, stats, equipment, bank |
| `Players/Hagag.plr.bak` | The game's own previous character save (4 KB safety net) |
| `Players/Hagag/<uuid>.map` | Explored-map data for that character |
| `achievements.dat` | Achievements + angler/fishing progress |
| `favorites.json` | Favourited items / characters |
| `config.json` | Game settings (resolution, keybinds, autosave, etc.) |
| `input profiles.json` | Input/keybind profiles |
| `sync-terraria.sh` | One-shot sync script: pull → copy live save in → commit → push |

Not included: `Worlds/*.wld.bak` and `*.wld.bak2` (the game's rollover copies of
the world — the canonical world is `SweetHome.wld`) and `ResourcePacks/`.

## Sync after a session

Quit the game, then run the script that lives in this folder:

```bash
cd ~/"Terraria Progress"
./sync-terraria.sh            # pull → copy this machine's save in → commit → push
./sync-terraria.sh --restore  # pull → back up the live save → load this repo's save
```

It does the whole round trip, and refuses to guess:

- **Terraria running** → it stops; the game rewrites the world on exit.
- **The repo has progress newer than your local save** (another device pushed
  it) → it stops and tells you to use `--restore` (load it here) or `--force`
  (keep this machine's save and overwrite the repo).
- `--restore` first copies the current `~/.local/share/Terraria` to
  `~/.local/share/Terraria.before-restore-<timestamp>`, so nothing is lost.

The identical script is in `~/My-Configs/sync-terraria.sh`; there it writes to
`.local/share/Terraria/` instead of this folder's root. Either one produces the
same commit, so use whichever you're closer to.

## Restore on another machine

```bash
git clone https://github.com/AHMEDxHAGAG/terrariaProgress.git ~/"Terraria Progress"
~/"Terraria Progress"/sync-terraria.sh --restore
```

That puts the world and character into `~/.local/share/Terraria` and runs.
Manual equivalent, if you prefer plain `cp`:

```bash
mkdir -p ~/.local/share/Terraria
cp -a "Terraria Progress"/{Worlds,Players,achievements.dat,config.json,favorites.json,"input profiles.json"} ~/.local/share/Terraria/
```

Launch the game: `SweetHome` appears under Single Player → Worlds and `Hagag`
under Players. (On Linux the GOG build reads saves from `~/.local/share/Terraria`
— no cloud sync involved, so the copy above is the whole restore.)
