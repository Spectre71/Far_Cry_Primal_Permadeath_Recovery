import sys
import os

def patch_save_file(file_path):
    # The known offset for the "Is Dead" / "Lock File" flags in Far Cry Primal saves.
    # 01 01 01 = Dead/Locked (Permadeath active)
    # 00 00 00 = Alive/Playable
    # Resetting this does NOT remove Survivor/Expert mechanics, it just unlocks the file.
    OFFSET = 638
    
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        return

    try:
        with open(file_path, 'r+b') as f:
            # Check file size to avoid errors on invalid files
            f.seek(0, 2)
            file_size = f.tell()
            if file_size <= OFFSET + 3:
                print(f"Error: File '{file_path}' is too small to be a valid save file.")
                return

            # Read current values
            f.seek(OFFSET)
            current_bytes = f.read(3)
            
            print(f"Analyzing {file_path}...")
            print(f"Values at offset {OFFSET}: {current_bytes.hex()}")

            if current_bytes == b'\x00\x00\x00':
                print("Save file is already patched (flags are all 0). No changes needed.")
            else:
                # Overwrite with 00 00 00 to unlock the file
                f.seek(OFFSET)
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
