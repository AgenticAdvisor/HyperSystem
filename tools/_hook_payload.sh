#!/usr/bin/env bash
# Shared JSON-payload helper sourced by hooks.
# Provides one function: extract_field <dotted.path> — reads JSON on stdin,
# returns the string value at the given path, or empty string on miss.
#
# Why this exists: hooks previously parsed payloads with grep+sed, which
# silently mangled values containing escaped quotes or newlines. This helper
# uses Python (already a hard dependency) for proper JSON parsing.
#
# Limits (callers should be aware):
#   - Non-string values (int, bool, null, array, object) also return empty.
#   - JSON keys containing literal "." are unreachable (dot is the path separator).
#   - Values containing literal newlines are returned with newlines intact;
#     bash $() strips trailing but preserves internal — caller may need to handle.

extract_field() {
    local field_path="$1"
    python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    parts = sys.argv[1].split(".")
    for p in parts:
        if isinstance(d, dict):
            d = d.get(p, "")
        else:
            d = ""
            break
    print(d if isinstance(d, str) else "")
except Exception:
    pass
' "$field_path"
}
