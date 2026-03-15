import sys
import os

def patch_save_file(file_path):
    # The known offset for the "Is Dead" / "Lock File" flags in Far Cry Primal saves.
    # 01 01 01 = Dead/Locked (Permadeath active)
    # 00 00 00 = Alive/Playable
    # Resetting this does NOT remove Survivor/Expert mechanics, it just unlocks the file.
    OFFSET_FLAGS = 638
    
    # Validation Constants
    OFFSET_MARKER = 576
    EXPECTED_MARKER = b'primal_main'
    MAGIC_HEADER = b'\x24\x02'

    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        return

    try:
        with open(file_path, 'r+b') as f:
            # 1. Size Check
            f.seek(0, 2)
            file_size = f.tell()
            if file_size < OFFSET_FLAGS + 3:
                print(f"Error: File '{file_path}' is too small to be a valid Far Cry Primal save.")
                return

            # 2. Header Check (Magic Bytes)
            f.seek(0)
            header = f.read(2)
            if header != MAGIC_HEADER:
                print(f"Error: File '{file_path}' does not look like a Far Cry Primal save (Invalid Header).")
                print(f"Expected {MAGIC_HEADER.hex()}, found {header.hex()}. Aborting to prevent corruption.")
                return

            # 3. Game ID Check (primal_main)
            f.seek(OFFSET_MARKER)
            marker = f.read(len(EXPECTED_MARKER))
            if marker != EXPECTED_MARKER:
                print(f"Error: File '{file_path}' is missing the 'primal_main' marker.")
                print("This does not appear to be a valid save file for this game. Aborting.")
                return

            # 4. Patching
            f.seek(OFFSET_FLAGS)
            current_bytes = f.read(3)
            
            print(f"Verified valid save file: {file_path}")
            print(f"Values at offset {OFFSET_FLAGS}: {current_bytes.hex()}")

            if current_bytes == b'\x00\x00\x00':
                print("Save file is already unlocked (flags are 00 00 00). No changes needed.")
            else:
                # Overwrite with 00 00 00 to unlock the file
                f.seek(OFFSET_FLAGS)
                f.write(b'\x00\x00\x00')
                print("Success! Death flags have been reset.")
                print("Your save file is revived. Survivor/Permadeath mechanics remain active.")
                print("You can now copy this file back to your save game folder.")

    except IOError as e:
        print(f"An error occurred while processing the file: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 remove_permadeath.py <path_to_save_file>")
        print("Example: python3 remove_permadeath.py 1.save")
    else:
        patch_save_file(sys.argv[1])
