#!/usr/bin/env bash
set -euo pipefail
# Auto-copy Far Cry Primal save files while the game runs.
# Uses inotifywait if present, otherwise falls back to polling via stat.
# USAGE WITH STEAM: bash -c 'path/to/FCP_save_copy.sh & exec "$@"' -- %command%
# cp 1.save "/media/spectre71/860 QVO/SteamLibrary/steamapps/compatdata/371660/pfx/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/savegames/7f4b6223-e119-4fc9-a564-d5fc2cb0f20f/2029" && cp 2.save "/media/spectre71/860 QVO/SteamLibrary/steamapps/compatdata/371660/pfx/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/savegames/7f4b6223-e119-4fc9-a564-d5fc2cb0f20f/2029"
SAVE_DIR="/media/spectre71/860 QVO/SteamLibrary/steamapps/compatdata/371660/pfx/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/savegames/7f4b6223-e119-4fc9-a564-d5fc2cb0f20f/2029"
PATTERN="*.save"
DEST_DIR="/home/spectre71/Custom_files/FCPSaves"
POLL_INTERVAL=10
# Set to 1 to append a timestamp to saved copies, or 0 to overwrite using original filename
ADD_TIMESTAMP=0

mkdir -p "$DEST_DIR"

timestamp() { date +"%Y%m%d-%H%M%S"; }

copy_file() {
	local src="${1:?}"
	local base
	base=$(basename -- "$src")
	local dest="$DEST_DIR/$base"
	local prev="$DEST_DIR/${base}.b1"

	# Rotate: move current dest to .b1 (previous), overwriting prev if needed
	if [[ -e "$dest" ]]; then
		mv -f -- "$dest" "$prev" || true
	fi

	# Copy new file as the current
	cp -af -- "$src" "$dest"

	# Also keep timestamped copy if enabled
	if [[ "$ADD_TIMESTAMP" -eq 1 ]]; then
		local name="${base%.*}"
		local ext="${base##*.}"
		cp -af -- "$src" "$DEST_DIR/${name}_$(timestamp).${ext}" || true
	fi
}

if command -v inotifywait >/dev/null 2>&1; then
	echo "Monitoring saves with inotifywait..."
	inotifywait -m -e close_write,create,modify,move --format '%w%f' -- "$SAVE_DIR" | while read -r filepath; do
		case "$filepath" in
			*.save)
				# Copy only the file that actually changed
				copy_file "$filepath" || true
				;;
		esac
	done
else
	echo "inotifywait not found; falling back to polling every ${POLL_INTERVAL}s"
	declare -A last_mtimes # Associative array to track last modification times
	shopt -s nullglob # Handle case where no files match pattern
	while true; do
		for f in "$SAVE_DIR"/$PATTERN; do
			mtime=$(stat -c %Y -- "$f" 2>/dev/null || echo 0) # Get modification time, default to 0 if file is inaccessible
			if [[ -z "${last_mtimes[$f]:-}" || "${last_mtimes[$f]}" != "$mtime" ]]; then
				last_mtimes[$f]=$mtime
				# Copy only this changed file
				copy_file "$f" || true
			fi
		done
		sleep "$POLL_INTERVAL"
	done
fi
