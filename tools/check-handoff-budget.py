#!/usr/bin/env python3
"""Exit non-zero if HANDOFF.json last_session.summary exceeds the budget.

Called from /close skill Step 3.5 after HANDOFF.json is written.
The budget bounds next-session reader cost; sessions that legitimately
need more than BUDGET items usually need consolidation rather than slack.
"""
import json
import sys
from pathlib import Path

BUDGET = 6
HANDOFF = Path(__file__).resolve().parent.parent / "HANDOFF.json"


def main() -> int:
    data = json.loads(HANDOFF.read_text())
    summary = data.get("last_session", {}).get("summary", [])
    count = len(summary) if isinstance(summary, list) else 0

    if count <= BUDGET:
        print(f"OK: last_session.summary has {count}/{BUDGET} items")
        return 0

    print(f"BUDGET EXCEEDED: last_session.summary has {count} items (budget {BUDGET})")
    print("\nCurrent items (first 80 chars each):")
    for i, item in enumerate(summary, 1):
        preview = (item[:80] + "...") if len(item) > 80 else item
        print(f"  {i}. {preview}")
    print("\nConsolidate adjacent or related items, or merge minor items into related ones.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
