#!/usr/bin/env python3
"""Move every drifted window back to the workspace AeroSpace intends for it.

The mapping is read from aerospace.toml itself: the `[[on-window-detected]]`
callbacks are the single source of truth for "app X belongs on workspace Y".
Rules are applied in order, first match wins (unless the rule sets
`check-further-callbacks = true`), mirroring AeroSpace semantics.

Supported `if` conditions:
  if.app-id                    exact bundle id match
  if.app-name-regex-substring  regex searched in the app name

Rules with any other condition are skipped (reported with --verbose), because
this script cannot evaluate them.

Usage:
  restore-workspaces.py [--dry-run] [--verbose]

Runs on the stock macOS python3 (3.9), so it parses the small subset of TOML it
needs instead of importing tomllib.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

CONFIG_PATH = os.path.expanduser("~/.config/aerospace/aerospace.toml")
MOVE_CMD = "move-node-to-workspace"
SUPPORTED_CONDITIONS = ("app-id", "app-name-regex-substring")
# AeroSpace runs bindings with a bare PATH, so look in the usual install spots.
AEROSPACE_CANDIDATES = (
    "/opt/homebrew/bin/aerospace",
    "/usr/local/bin/aerospace",
    "/run/current-system/sw/bin/aerospace",
)


def aerospace_bin():
    found = shutil.which("aerospace")
    if found:
        return found
    for candidate in AEROSPACE_CANDIDATES:
        if os.access(candidate, os.X_OK):
            return candidate
    sys.exit("restore-workspaces: cannot find the aerospace CLI")


AEROSPACE = aerospace_bin()

STRING_RE = r'"((?:[^"\\]|\\.)*)"|\'((?:[^\'\\]|\\.)*)\''
KV_RE = re.compile(r"^\s*([A-Za-z0-9_.-]+)\s*=\s*(.+?)\s*$")
STRING_VALUE_RE = re.compile(r"^" + STRING_RE + r"$")
BOOL_RE = re.compile(r"^(true|false)$")


def unescape(value):
    return value.replace('\\"', '"').replace("\\'", "'").replace("\\\\", "\\")


def parse_string(token):
    match = STRING_VALUE_RE.match(token.strip())
    if not match:
        return None
    return unescape(match.group(1) if match.group(1) is not None else match.group(2))


def split_array(body):
    """Split a TOML array body into raw element tokens (strings/bools only)."""
    items, current, quote, escaped = [], [], None, False
    for char in body:
        if quote:
            current.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in "\"'":
            quote = char
            current.append(char)
        elif char == ",":
            items.append("".join(current).strip())
            current = []
        else:
            current.append(char)
    tail = "".join(current).strip()
    if tail:
        items.append(tail)
    return [item for item in items if item]


def parse_value(token):
    """Return the TOML value for a raw token, or the raw string if unknown."""
    token = token.split(" #", 1)[0].strip() if not token.startswith(("'", '"')) else token
    text = parse_string(token)
    if text is not None:
        return text
    match = BOOL_RE.match(token)
    if match:
        return match.group(1) == "true"
    if token.startswith("[") and token.endswith("]"):
        values = []
        for item in split_array(token[1:-1]):
            text = parse_string(item)
            values.append(text if text is not None else item)
        return values
    return token


def read_rules(path):
    """Parse [[on-window-detected]] blocks from the config file."""
    try:
        with open(path, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
    except OSError as error:
        sys.exit("restore-workspaces: cannot read %s: %s" % (path, error))

    rules, block = [], None
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("["):
            if line.replace(" ", "") == "[[on-window-detected]]":
                block = {"if": {}, "run": [], "check-further-callbacks": False}
                rules.append(block)
            else:
                block = None
            continue
        if block is None:
            continue
        match = KV_RE.match(raw)
        if not match:
            continue
        key, value = match.group(1), parse_value(match.group(2))
        if key.startswith("if."):
            block["if"][key[len("if."):]] = value
        elif key == "run":
            block["run"] = [value] if isinstance(value, str) else list(value)
        elif key == "check-further-callbacks":
            block["check-further-callbacks"] = bool(value)
    return rules


def target_workspace(rule):
    """Extract the workspace argument of move-node-to-workspace from a run list."""
    for command in rule["run"]:
        if not isinstance(command, str):
            continue
        tokens = command.split()
        if not tokens or tokens[0] != MOVE_CMD:
            continue
        args = [token for token in tokens[1:] if not token.startswith("-")]
        if args:
            return args[-1]
    return None


def rule_matches(rule, window):
    """Return True/False, or None when the rule uses conditions we cannot evaluate."""
    conditions = rule["if"]
    if not conditions:
        return None
    unknown = [key for key in conditions if key not in SUPPORTED_CONDITIONS]
    if unknown:
        return None
    app_id = conditions.get("app-id")
    if app_id is not None and window["app-bundle-id"] != app_id:
        return False
    pattern = conditions.get("app-name-regex-substring")
    if pattern is not None and not re.search(str(pattern), window["app-name"]):
        return False
    return True


def list_windows():
    output = subprocess.run(
        [
            AEROSPACE,
            "list-windows",
            "--all",
            "--format",
            "%{window-id}\t%{app-bundle-id}\t%{app-name}\t%{workspace}",
        ],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    windows = []
    for line in output.splitlines():
        parts = line.split("\t")
        if len(parts) != 4:
            continue
        windows.append(
            {
                "window-id": parts[0],
                "app-bundle-id": parts[1],
                "app-name": parts[2],
                "workspace": parts[3],
            }
        )
    return windows


def intended_workspace(rules, window, verbose):
    for rule in rules:
        matched = rule_matches(rule, window)
        if matched is None:
            if verbose:
                unknown = sorted(set(rule["if"]) - set(SUPPORTED_CONDITIONS))
                if unknown:
                    print(
                        "skip rule for %s: unsupported conditions %s"
                        % (window["app-name"], ", ".join(unknown)),
                        file=sys.stderr,
                    )
            continue
        if not matched:
            continue
        workspace = target_workspace(rule)
        if workspace is not None or not rule["check-further-callbacks"]:
            return workspace
    return None


def notify(message):
    script = "display notification %s with title %s" % (
        json.dumps(message),
        json.dumps("AeroSpace"),
    )
    try:
        subprocess.run(["osascript", "-e", script], check=True, capture_output=True)
    except (OSError, subprocess.CalledProcessError):
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--dry-run", action="store_true", help="report what would move, change nothing"
    )
    parser.add_argument(
        "--verbose", action="store_true", help="explain skipped rules and windows"
    )
    args = parser.parse_args()

    rules = read_rules(CONFIG_PATH)
    moved = []
    for window in list_windows():
        workspace = intended_workspace(rules, window, args.verbose)
        if workspace is None:
            if args.verbose:
                print(
                    "no rule for %s (%s), leaving on %s"
                    % (window["app-name"], window["app-bundle-id"], window["workspace"]),
                    file=sys.stderr,
                )
            continue
        if workspace == window["workspace"]:
            continue
        moved.append((window, workspace))
        if args.dry_run:
            print(
                "%s: %s -> %s"
                % (window["app-name"], window["workspace"], workspace)
            )
            continue
        subprocess.run(
            [AEROSPACE, MOVE_CMD, "--window-id", window["window-id"], workspace],
            check=True,
        )

    if args.dry_run:
        return 0
    if moved:
        notify(
            "%d window%s restored: %s"
            % (
                len(moved),
                "" if len(moved) == 1 else "s",
                ", ".join(
                    "%s->%s" % (window["app-name"], workspace)
                    for window, workspace in moved
                ),
            )
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
