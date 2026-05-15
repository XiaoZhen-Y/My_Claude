#!/usr/bin/env python3
"""
Binary-level file patcher for GBK-encoded source files.

Reads a file in binary mode (rb/wb), applies exact byte-string replacements,
preserving all bytes (including GBK Chinese) unchanged.

Usage:
    python binary_patch.py <file> <patch.json>

patch.json format:
[
    {
        "old": "exact bytes to find (can include \\r\\n)",
        "new": "replacement bytes"
    },
    ...
]

Or use --inline mode for a single replacement:
    python binary_patch.py <file> --old "text" --new "text"
"""

import json
import sys
import os


RN = b'\r\n'


def apply_patches(filepath, replacements):
    """Apply a list of (old_bytes, new_bytes) replacements to a file."""
    with open(filepath, 'rb') as f:
        original = f.read()

    data = original

    for i, (old, new) in enumerate(replacements):
        count = data.count(old)
        if count == 0:
            print(f"  [{i}] WARNING: pattern not found ({len(old)} bytes)")
            print(f"      first 60 bytes: {old[:60]}")
            return False
        elif count > 1:
            print(f"  [{i}] WARNING: pattern found {count} times ({len(old)} bytes)")
        data = data.replace(old, new)

    if data == original:
        print("  No changes made.")
        return False

    with open(filepath, 'wb') as f:
        f.write(data)

    print(f"  Patched: {filepath}")
    return True


def parse_inline_patches(args):
    """Parse --old/--new pairs from command line."""
    replacements = []
    i = 0
    while i < len(args):
        if args[i] == '--old' and i + 1 < len(args):
            old = args[i + 1].encode('utf-8')
            # Convert literal \r\n to actual CRLF
            old = old.replace(b'\\r\\n', RN).replace(b'\\n', RN)
            i += 2

            if i < len(args) and args[i] == '--new' and i + 1 < len(args):
                new = args[i + 1].encode('utf-8')
                new = new.replace(b'\\r\\n', RN).replace(b'\\n', RN)
                i += 2
                replacements.append((old, new))
            else:
                print("Error: --old must be followed by --new")
                sys.exit(1)
        else:
            i += 1
    return replacements


def main():
    args = sys.argv[1:]

    if len(args) < 1:
        print(__doc__)
        sys.exit(1)

    filepath = args[0]
    replacements = []

    # Check for inline mode
    if '--old' in args:
        replacements = parse_inline_patches(args[1:])
    elif len(args) >= 2:
        # JSON file mode
        json_path = args[1]
        with open(json_path, 'r', encoding='utf-8') as f:
            config = json.load(f)

        for item in config:
            old = item['old'].encode('utf-8')
            new = item['new'].encode('utf-8')
            # Convert literal \r\n to actual bytes
            old = old.replace(b'\\r\\n', RN).replace(b'\\n', RN)
            new = new.replace(b'\\r\\n', RN).replace(b'\\n', RN)
            replacements.append((old, new))
    else:
        print("Error: provide --old/--new or a JSON config file")
        sys.exit(1)

    if not replacements:
        print("Error: no replacements specified")
        sys.exit(1)

    if not os.path.exists(filepath):
        print(f"Error: file not found: {filepath}")
        sys.exit(1)

    print(f"Applying {len(replacements)} replacement(s) to {filepath}...")
    success = apply_patches(filepath, replacements)
    if not success:
        sys.exit(1)


if __name__ == '__main__':
    main()
