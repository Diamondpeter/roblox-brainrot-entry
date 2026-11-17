# Brainrot Bazaar: Noodle Nebula

![make.fun bounty](https://make.fun/badge/roblox-brainrot-01.svg)
![rank](https://make.fun/badge/roblox-brainrot-01/Diamondpeter/roblox-brainrot-entry/rank.svg)
![reward](https://make.fun/badge/roblox-brainrot-01/Diamondpeter/roblox-brainrot-entry/reward.svg)

An entry for make.fun's [Make the best AI Roblox brainrot game](https://make.fun/bounty/roblox-brainrot-01) bounty (`roblox-brainrot-01`).

A 3D Roblox brainrot game with an original cast and world. You are a bazaar keeper in the Noodle Nebula:

- **Catch** wandering brainrots in the Wild Meadow — Sock Gremlins, Puddle Ducks, Banana Wizards — each built from 3D parts with a floating name, rarity and $/s label.
- **Buy** off the plaza conveyor or **roll the Gacha Noodle Pot** ($150) for a rarity and mutation roll: Common to Nebula, Normal to Golden, Rainbow and Void.
- **Carry it home** on your head to one of eight ring bases, step on a pedestal, and it earns NoodleBucks per second, ticking live into your HUD.
- **Defend it**: visitors can steal from an unlocked base, so hit your lock pad — and when the **Soup Tsunami** warning sounds, dash home or the wave washes your carried find away.
- **Rebirth** up to five times, each wiping your cash for a permanent +50% income on everything you place.

## The cast (all original)

Sock Gremlin, Toast Goblin, Puddle Duck, Banana Wizard, Chair Shark, Fridge Yeti, Disco Cactus, Traffic Cone Gnome, Moon Noodle Dragon, Grandma Roomba, Captain Washing Machine and Emperor Spatula — twelve characters on a five-step rarity ladder (Common, Rare, Epic, Legendary, Nebula) with three mutations (Golden x2, Rainbow x5, Void x10).

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the binary place Rojo builds from `src/` and `default.project.json` (`rojo build default.project.json --output game.rbxl`): a 3D world with a plaza, shop stall, conveyor belt, gacha pot, wild meadow and eight bases with six pedestals each.
- `src/shared/` — `BrainrotData` (the cast, rarities, mutations, income maths) and `GameConfig` (every tuning number), read by both sides.
- `src/server/` — the server entry point plus `EconomyService` (wallets, buying, placing, stealing, locks, rebirths, the per-second income tick), `WorldBuilder` (bases, conveyor stock, wild wanderers, the wave), `CharacterFactory` (builds each character model from parts) and `WaveService` (the Soup Tsunami).
- `src/client/` — `Hud` (the ScreenGui: wallet, carried card, collection, Noodle Pot / Lock / Rebirth buttons, tsunami banner) and `Effects` (carried bounce, Nebula shimmer, tsunami screen shake).
- `screenshots/` — four 1280x720 pictures of this game's world and characters; the first, `1-cover.png`, is the cover and the game's Roblox thumbnail.
- `PLAY.json` names the published place (filled in by the entrant at publish time).

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

## License

MIT — see `LICENSE`.
