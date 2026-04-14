#!/usr/bin/env python3
"""
Sanitize Bridge — Python subprocess called by sanitize.js
==========================================================
Reads a JSON request from a temp file, runs content_security sanitization,
and writes the result to an output temp file.

This is NOT a public API — it's the plumbing between sanitize.js and
content_security.py. Do not call directly; use sanitize.js from Node.js
or secure_writer.py from Python.

Input JSON schema:
    { "mode": "text"|"dict"|"items", "payload": ..., "context": "general"|... }

Output JSON schema:
    { "cleaned": ..., "report": { "threats_found": bool, "threat_count": int, "detections": [...] } }
"""

import json
import sys
from pathlib import Path

# Resolve tools/ for content_security import
_tools_dir = Path(__file__).parent.resolve()
if str(_tools_dir) not in sys.path:
    sys.path.insert(0, str(_tools_dir))

from content_security import sanitize_content, sanitize_dict_values


def _report_to_dict(report):
    """Convert ContentSecurityReport to a JSON-serializable dict."""
    return {
        "threats_found": report.threats_found,
        "threat_count": len(report.detections),
        "original_length": report.original_length,
        "cleaned_length": report.cleaned_length,
        "detections": [
            {
                "category": d.category,
                "vector": d.vector,
                "severity": d.severity,
                "action": d.action,
            }
            for d in report.detections
        ],
    }


def _log_event(context, report, action):
    """Log threat detections (mirrors secure_writer._log_event)."""
    if not report.threats_found:
        return
    from datetime import datetime, timezone

    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "destination": "(js-bridge)",
        "context": context,
        "action": action,
        "original_length": report.original_length,
        "cleaned_length": report.cleaned_length,
        "threats_found": report.threats_found,
        "threat_count": len(report.detections),
        "detections": [
            {"category": d.category, "vector": d.vector, "severity": d.severity, "action": d.action}
            for d in report.detections
        ],
    }
    log_path = _tools_dir / ".security-log.jsonl"
    try:
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except OSError:
        pass


def main():
    if len(sys.argv) != 3:
        print("Usage: _sanitize_bridge.py <input.json> <output.json>", file=sys.stderr)
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    with open(input_path, "r", encoding="utf-8") as f:
        request = json.load(f)

    mode = request["mode"]
    payload = request["payload"]
    context = request.get("context", "general")

    if mode == "text":
        cleaned, report = sanitize_content(payload, context=context)
        _log_event(context, report, "js_sanitize_text")
        result = {"cleaned": cleaned, "report": _report_to_dict(report)}

    elif mode == "dict":
        cleaned, report = sanitize_dict_values(payload, context=context)
        _log_event(context, report, "js_sanitize_dict")
        result = {"cleaned": cleaned, "report": _report_to_dict(report)}

    elif mode == "items":
        from content_security import ContentSecurityReport
        combined = ContentSecurityReport()
        cleaned_items = []
        for item in payload:
            c, r = sanitize_content(item, context=context)
            combined.detections.extend(r.detections)
            cleaned_items.append(c)
        combined.original_length = sum(len(i) for i in payload)
        combined.cleaned_length = sum(len(i) for i in cleaned_items)
        _log_event(context, combined, "js_sanitize_items")
        result = {"cleaned": cleaned_items, "report": _report_to_dict(combined)}

    else:
        result = {"error": f"Unknown mode: {mode}"}

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False)


if __name__ == "__main__":
    main()
