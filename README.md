# vkQuake Launcher

A native macOS campaign launcher for [vkQuake](https://github.com/Novum/vkQuake). It provides one-click campaign selection, official shareware detection, custom mod installation, loose BSP map launching, and clear diagnostics when engine or game data is missing.

Made by **Mihai Mateias** and released under the [MIT License](LICENSE).

## Requirements

- macOS 11 or newer
- Xcode Command Line Tools (`swiftc`)
- A lawful vkQuake installation and Quake game data

The launcher does **not** include vkQuake, Quake game data, campaign files, or Bethesda/MachineGames artwork.

## Expected installation layout

```text
Quake/
├── vkQuake Launcher.app
└── rerelease/
    ├── vkQuake.app
    ├── quakeex.kpf
    ├── id1/
    ├── hipnotic/
    ├── rogue/
    ├── dopa/
    └── mg1/
```

The launcher resolves this layout relative to its own location, so the complete `Quake` folder can be moved without breaking hard-coded paths.

## Build

```bash
./build-app.sh
```

The unsigned development build is written to `build/vkQuake Launcher.app` and then ad-hoc signed.

Campaign artwork is optional. To reproduce the illustrated local build, provide appropriately licensed JPEGs in `Resources/` named:

```text
base.jpg
hipnotic.jpg
rogue.jpg
dopa.jpg
mg1.jpg
mg3.jpg
```

An optional `Resources/vkquake.icns` supplies the application icon. Publisher artwork and game assets are intentionally excluded from this MIT-licensed repository.

## Safety behavior

- Missing engine and campaign files produce actionable warnings instead of crashes.
- An official shareware installation is detected when `id1/pak0.pak` exists without registered or enhanced data.
- Official campaign, engine, and custom-map directories cannot be overwritten by mod installation.
- Loose maps must have a Quake BSP29 or BSP2 header and a safe map name.
- Choosing an already-installed BSP launches it without deleting the source file.
- A second campaign is not launched while vkQuake is already running.
- Dawn of the Machine remains informational until lawful `mg3` data and a Dawn-capable vkQuake build are available and verified.

## Bug reports

Report bugs at <https://github.com/cefege/vkquake-launcher/issues>.

Include your macOS version, vkQuake version, selected campaign or custom content, and the exact warning shown by the launcher. Do not upload copyrighted game data.
