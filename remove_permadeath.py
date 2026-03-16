import sys
import os

def patch_save_file(file_path):
    # Observed from user-provided save timelines:
    # - Dead-state candidates: 01 01 01 at offset 638
    # - Older/alive candidates: 00 01 01 at offset 638
    # So we only clear the first flag byte, preserving the remaining bytes.
    OFFSET_FLAGS = 638
    DEAD_PATTERN = b'\x01\x01\x01'
    ALIVE_PATTERN = b'\x00\x01\x01'
    
    # Validation Constants
    OFFSET_MARKER = 576
    EXPECTED_MARKER = b'primal_main'
    MAGIC_HEADER = b'\x24\x02'

    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        return

    try:
        with open(file_path, 'r+b') as f:
            # 1. Basic Header Check
            f.seek(0)
            if f.read(2) != MAGIC_HEADER:
                print(f"Error: {file_path} is not a valid Far Cry Primal save.")
                return

            # 2. Game ID Check
            f.seek(OFFSET_MARKER)
            if f.read(len(EXPECTED_MARKER)) != EXPECTED_MARKER:
                print(f"Error: {file_path} is missing the 'primal_main' marker.")
                return

            # 3. Surgical Patch
            f.seek(OFFSET_FLAGS)
            current_bytes = f.read(3)
            
            print(f"Verified valid save file: {file_path}")
            print(f"Current values at offset {OFFSET_FLAGS}: {current_bytes.hex()}")

            if current_bytes == DEAD_PATTERN:
                f.seek(OFFSET_FLAGS)
                f.write(ALIVE_PATTERN)
                print(f"Success! Patched death flag (01 01 01 -> 00 01 01) at offset {OFFSET_FLAGS}.")
                print("Your save file is revived. Try copying it back to the game folder.")
            elif current_bytes == ALIVE_PATTERN:
                print("The file already looks alive (00 01 01 at this offset). No changes needed.")
            else:
                print(f"Warning: Found unexpected bytes {current_bytes.hex()} at offset {OFFSET_FLAGS}.")
                print("This specific file might have shifted data. Not patching to avoid corruption.")

    except IOError as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 remove_permadeath.py <path_to_save_file>")
        print("Example: python3 remove_permadeath.py 1.save")
    else:
        patch_save_file(sys.argv[1])
