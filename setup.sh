#!/usr/bin/env bash
# CachyOS / Arch GNOME debloat: remove preinstalled GNOME apps and background services you won't use.
# Run as your normal user, not root:  bash setup.sh   then reboot.
# Every removal is shown first and asked about once. Reinstall anything with: sudo pacman -S <name>
set -uo pipefail

if [[ $EUID -eq 0 ]]; then echo "Run as your normal user, not root." >&2; exit 1; fi
command -v pacman >/dev/null || { echo "pacman not found; this script is for Arch-based systems." >&2; exit 1; }
command -v gnome-shell >/dev/null || { echo "gnome-shell not found; this script is for GNOME." >&2; exit 1; }

# Optional groups (set to 0 to keep)
REMOVE_GAMES=1        # gnome-mines, sudoku, chess, etc.
REMOVE_MEDIA=1        # totem, rhythmbox, shotwell, simple-scan
REMOVE_MAIL_WEB=1     # thunderbird, epiphany (GNOME Web)
REMOVE_PRINTING=1     # cups and printer tools
REMOVE_BLUETOOTH=0    # keep on: Bluetooth input and headphones need it (Surface default: keep)
REMOVE_REMOTE=1       # gnome-remote-desktop (screen sharing server)
REMOVE_EXTRAS=1       # maps, weather, music, contacts, clocks, tour, first-run setup, docs

# Package groups. Only installed packages are removed.
GAMES=(gnome-mines gnome-chess gnome-sudoku gnome-mahjongg aisleriot gnome-klotski gnome-taquin
       gnome-nibbles gnome-robots gnome-tetravex gnome-2048 quadrapassel iagno lightsoff swell-foop)
MEDIA=(totem rhythmbox shotwell simple-scan)
MAIL_WEB=(thunderbird epiphany)
PRINTING=(cups cups-pk-helper system-config-printer)
BLUETOOTH=(bluez bluez-utils)
REMOTE=(gnome-remote-desktop)
EXTRAS=(gnome-maps gnome-weather gnome-music gnome-contacts gnome-clocks gnome-tour
        gnome-initial-setup yelp gnome-user-docs gnome-software packagekit)

TO_REMOVE=()
add_group() { local flag=$1; shift; ((flag)) && TO_REMOVE+=("$@"); return 0; }
add_group "$REMOVE_GAMES"     "${GAMES[@]}"
add_group "$REMOVE_MEDIA"     "${MEDIA[@]}"
add_group "$REMOVE_MAIL_WEB"  "${MAIL_WEB[@]}"
add_group "$REMOVE_PRINTING"  "${PRINTING[@]}"
add_group "$REMOVE_BLUETOOTH" "${BLUETOOTH[@]}"
add_group "$REMOVE_REMOTE"    "${REMOTE[@]}"
add_group "$REMOVE_EXTRAS"    "${EXTRAS[@]}"

PRESENT=()
for p in "${TO_REMOVE[@]}"; do pacman -Qq "$p" &>/dev/null && PRESENT+=("$p"); done

echo "== 1/3 Remove installed packages =="
if ((${#PRESENT[@]})); then
  echo "Will remove: ${PRESENT[*]}"
  read -rp "Proceed? [y/N] " ans
  if [[ $ans =~ ^[Yy]$ ]]; then
    # -Rns also drops their unneeded dependencies. pacman stops on any package other apps need.
    sudo pacman -Rns "${PRESENT[@]}" || echo "pacman refused some removals (other packages depend on them). Nothing was half-removed."
  else
    echo "Skipped package removal."
  fi
else
  echo "Nothing from the list is installed."
fi

echo "== 2/3 Disable background services and indexers =="
# Desktop search indexer (heavy on first boot and on battery)
systemctl --user mask localsearch-3.service localsearch-control-3.service localsearch-writeback-3.service \
  tracker-miner-fs-3.service tracker-extract-3.service 2>/dev/null
# Software-update daemon used only by GNOME Software (removed above if in EXTRAS)
sudo systemctl disable --now packagekit.service 2>/dev/null
# Avahi (network service discovery) is not needed for a single-user desktop
sudo systemctl disable --now avahi-daemon.service avahi-daemon.socket 2>/dev/null
((REMOVE_PRINTING)) && sudo systemctl disable --now cups.service cups.socket cups.path 2>/dev/null
((REMOVE_REMOTE))   && systemctl --user mask gnome-remote-desktop.service 2>/dev/null
# Sleep, lock, and power settings are deliberately NOT touched: this is a laptop/tablet.

echo "== 3/3 Clean up orphans (review the list before accepting) =="
mapfile -t orphans < <(pacman -Qdtq 2>/dev/null)
if ((${#orphans[@]})); then
  echo "Orphaned packages (some may be ones you installed by hand):"; printf '  %s\n' "${orphans[@]}"
  read -rp "Remove these orphans? [y/N] " ans
  [[ $ans =~ ^[Yy]$ ]] && sudo pacman -Rns "${orphans[@]}"
else
  echo "No orphans."
fi

echo
echo "Done. Reboot, then check:  systemctl --user --failed   and   free -h"
