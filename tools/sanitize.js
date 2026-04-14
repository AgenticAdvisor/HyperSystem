#!/usr/bin/env node
/**
 * sanitize.js — Node.js Security Gateway
 * ========================================
 * JavaScript wrapper for the Python content_security pipeline.
 * Provides the same API surface as secure_writer.py for Node.js pipelines.
 *
 * Architecture:
 *    Node.js pipeline (Daily Brief, Prospect Deck, Risk Bot)
 *            ↓
 *       sanitize.js  ← YOU ARE HERE
 *       (calls Python content_security → returns cleaned data)
 *            ↓
 *       docx/pptx builder consumes clean data
 *
 * Usage:
 *    const { sanitizeText, sanitizeDict, sanitizeItems } = require("./sanitize");
 *
 *    // Single string
 *    const { cleaned, report } = sanitizeText(dirtyString, "markdown");
 *
 *    // Object with string values (e.g., ProspectAnalysis JSON)
 *    const { cleaned, report } = sanitizeDict(dirtyObj, "general");
 *
 *    // Array of strings (e.g., news items, bullet points)
 *    const { cleaned, report } = sanitizeItems(dirtyArray, "general");
 *
 * All functions are synchronous (execSync) to match the existing pipeline patterns.
 * Threat detections are logged to tools/.security-log.jsonl by the Python layer.
 */

const { execSync } = require("child_process");
const path = require("path");
const fs = require("fs");
const os = require("os");

// Path to the Python security modules
const TOOLS_DIR = path.resolve(__dirname);
const PYTHON_BRIDGE = path.join(TOOLS_DIR, "_sanitize_bridge.py");
const PYTHON_CMD = process.env.SYSTEM_PYTHON || "python3";

/**
 * Call the Python bridge script and return parsed results.
 * @param {string} mode - "text", "dict", or "items"
 * @param {*} payload - The data to sanitize
 * @param {string} context - Sanitization context
 * @returns {{ cleaned: *, report: object }}
 */
function _callBridge(mode, payload, context) {
  // Write payload to a temp file to avoid shell escaping issues
  const tmpIn = path.join(os.tmpdir(), `sanitize-in-${process.pid}.json`);
  const tmpOut = path.join(os.tmpdir(), `sanitize-out-${process.pid}.json`);

  try {
    fs.writeFileSync(tmpIn, JSON.stringify({ mode, payload, context }), "utf8");

    execSync(`${PYTHON_CMD} "${PYTHON_BRIDGE}" "${tmpIn}" "${tmpOut}"`, {
      cwd: TOOLS_DIR,
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 30000,
    });

    const result = JSON.parse(fs.readFileSync(tmpOut, "utf8"));
    return result;
  } finally {
    // Clean up temp files
    try { fs.unlinkSync(tmpIn); } catch (_) {}
    try { fs.unlinkSync(tmpOut); } catch (_) {}
  }
}

/**
 * Sanitize a single text string.
 * @param {string} content - Untrusted text
 * @param {string} [context="general"] - "general", "markdown", "html", "diary"
 * @returns {{ cleaned: string, report: { threats_found: boolean, threat_count: number, detections: array } }}
 */
function sanitizeText(content, context = "general") {
  if (typeof content !== "string") {
    throw new TypeError(`sanitizeText expects a string, got ${typeof content}`);
  }
  return _callBridge("text", content, context);
}

/**
 * Sanitize all string values in an object (recursive).
 * @param {object} data - Object with potentially untrusted string values
 * @param {string} [context="general"]
 * @returns {{ cleaned: object, report: object }}
 */
function sanitizeDict(data, context = "general") {
  if (typeof data !== "object" || data === null) {
    throw new TypeError(`sanitizeDict expects an object, got ${typeof data}`);
  }
  return _callBridge("dict", data, context);
}

/**
 * Sanitize an array of strings.
 * @param {string[]} items - Array of untrusted strings
 * @param {string} [context="general"]
 * @returns {{ cleaned: string[], report: object }}
 */
function sanitizeItems(items, context = "general") {
  if (!Array.isArray(items)) {
    throw new TypeError(`sanitizeItems expects an array, got ${typeof items}`);
  }
  return _callBridge("items", items, context);
}

module.exports = { sanitizeText, sanitizeDict, sanitizeItems };
