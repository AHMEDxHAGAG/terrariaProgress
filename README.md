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

Not included: `Worlds/*.wld.bak` and `*.wld.bak2` (the game's rollover copies of
the world — the canonical world is `SweetHome.wld`) and `ResourcePacks/`.

## Restore on another machine

Install Terraria first, then:

```bash
mkdir -p ~/.local/share/Terraria
cp -a "Terraria Progress/." ~/.local/share/Terraria/
```

Launch the game: `SweetHome` appears under Single Player → Worlds and `Hagag`
under Players. (On Linux the GOG build reads saves from `~/.local/share/Terraria`
— no cloud sync involved, so the copy above is the whole restore.)

## Updating this copy

The game rewrites the world on every save, so re-copy after a session you care
about:

```bash
cp -a ~/.local/share/Terraria/Worlds/*.wld ~/"Terraria Progress/Worlds/"
cp -a ~/.local/share/Terraria/Players/. ~/"Terraria Progress/Players/"
cp -a ~/.local/share/Terraria/{achievements.dat,config.json,favorites.json,"input profiles.json"} ~/"Terraria Progress/"
```

Or run `~/My-Configs/sync-from-live.sh` and copy the files from there, so both
copies stay identical.
