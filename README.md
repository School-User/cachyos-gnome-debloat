# cachyos-gnome-debloat

Removes preinstalled GNOME apps and background services on CachyOS (or any Arch-based GNOME install).

- Removes games, media apps, GNOME Web/Thunderbird, printing, tour and first-run setup, maps/weather/music/contacts/clocks
- Disables the file indexer (localsearch/tracker), Avahi, and the PackageKit daemon
- Asks once before removing anything, and once more before removing orphaned packages
- Leaves sleep, lock, and power settings alone, and keeps Bluetooth on by default

```
curl -fsSL https://raw.githubusercontent.com/School-User/cachyos-gnome-debloat/main/setup.sh -o setup.sh
bash setup.sh
```

Reboot afterwards. To change what gets removed, edit the `REMOVE_*` flags at the top of `setup.sh`.
To reinstall an app, use `sudo pacman -S <name>`.

Not tested on every CachyOS release. Check the package list before accepting it.
