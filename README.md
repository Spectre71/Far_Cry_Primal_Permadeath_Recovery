# Far Cry Primal Save Reviver (Permadeath Fix)

This tool "revives" a **Far Cry Primal** save file that has been locked due to dying in Permadeath mode. 

Instead of removing the difficulty settings (Survivor Mode, Expert Difficulty, etc.), it simply resets the "Death Status" flags. **This means you keep your Permadeath/Survivor mechanics (stamina, no minimap, etc.) and potentially your achievement progress, but you are allowed to load the file again.**

## How It Works

When you die in Permadeath mode, the game writes specific flags to the save file to mark it as "Dead/Locked."
- **Location:** Offset `638` (decimal) / `0x27E` (hex).
- **Dead State:** `01 01 01` (Game locks the file).
- **Alive State:** `00 00 00` (Game allows loading).

This script resets these specific bytes to `00`, tricking the game into thinking the character is still alive.

## How to Use

### Prerequisites
- Python 3 installed on your system.

### Steps
1. **Backup your save file** before running this script.
2. Run the script from your terminal:

   ```bash
   python3 remove_permadeath.py 1.save
   ```

3. The script will confirm if it found and reset the death flags.
4. **Manually copy** the patched `.save` file back to your game's save directory.
5. Load the game. **Note:** If you die again, the game will likely re-lock the file. Simply run this script again to revive it.
