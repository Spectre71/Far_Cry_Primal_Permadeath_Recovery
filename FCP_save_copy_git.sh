#!/usr/bin/env bash
set -euo pipefail
# Auto-copy Far Cry Primal save files while the game runs.
# Uses inotifywait if present, otherwise falls back to polling via stat.
# USAGE WITH STEAM: bash -c 'path/to/FCP_save_copy.sh & exec "$@"' -- %command%
# cp 1.save "path/to/steamapps/compatdata/371660/pfx/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/savegames/UID/2029" && cp 2.save "path/to/steamapps/compatdata/371660/pfx/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/savegames/UID/2029"
SAVE_DIR="path/to/steamapps/compatdata/371660/pfx/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/savegames/UID/2029"
PATTERN="*.save"
DEST_DIR="path/to/CustomFCPSaves"
POLL_INTERVAL=10
# Set to 1 to append a timestamp to saved copies, or 0 to overwrite using original filename
ADD_TIMESTAMP=0
# Death-state guard (derived from save reverse-engineering)
DEAD_FLAG_OFFSET=638
DEAD_PATTERN_HEX="010101"
# Regex used to detect that game/launcher is still running; adjust if your process names differ.
GAME_PROCESS_REGEX="FCPrimal|FarCryPrimal|371660|Ubisoft|upc"
WAIT_INTERVAL=3

mkdir -p "$DEST_DIR"

timestamp() { date +"%Y%m%d-%H%M%S"; }

get_flag_hex() {
	local src="${1:?}"
	dd if="$src" bs=1 skip="$DEAD_FLAG_OFFSET" count=3 2>/dev/null | xxd -p
}

is_dead_save() {
	local src="${1:?}"
	local flag_hex
	flag_hex=$(get_flag_hex "$src")
	[[ "$flag_hex" == "$DEAD_PATTERN_HEX" ]]
}

game_is_running() {
	pgrep -f "$GAME_PROCESS_REGEX" >/dev/null 2>&1
}

wait_for_game_exit() {
	echo "Dead-state save detected; pausing backup until game process exits..."
	while game_is_running; do
		sleep "$WAIT_INTERVAL"
	done
	echo "Game process ended. Save backup monitoring resumed."
}

copy_file() {
	local src="${1:?}"

	if is_dead_save "$src"; then
		wait_for_game_exit
		return 2
	fi

	local base
	base=$(basename -- "$src")
	local dest="$DEST_DIR/$base"
	local prev1="$DEST_DIR/${base}.b1"
	local prev2="$DEST_DIR/${base}.b2"

	# Rotate backups: move b1 -> b2, dest -> b1 (preserve two previous versions)
	if [[ -e "$prev1" ]]; then
		mv -f -- "$prev1" "$prev2" || true
	fi
	if [[ -e "$dest" ]]; then
		mv -f -- "$dest" "$prev1" || true
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
