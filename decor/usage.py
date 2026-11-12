#!/usr/bin/env python3
"""Coding agents' plan limits and today's activity, as one JSON line.

Reads the records Omarchy's agents panel keeps current in
~/.local/state/omarchy/agents/usage/<agent>.json and prints:

  {"agents": [{"id", "name", "tier", "limits": [{"label", "percent", "resetsAt"}]}...],
   "today":  {"prompts", "tokens", "sessions"}}

agents are the ones signed in with limits to show; today adds up every
agent's prompts, tokens and sessions so far today.

Claude first, then by name. Limit names are shortened to plain words:
"Session (5-hour)" and "5h window" become "5-hour", "Weekly (7-day)" becomes
"Weekly", a model's own weekly allowance keeps its model's name.
"""

import json
import os
import re

USAGE = os.path.join(os.path.expanduser("~"), ".local/state/omarchy/agents/usage")


def short_label(limit):
    label = str(limit.get("title") or limit.get("label") or "").strip()
    low = label.lower()
    if "5-hour" in low or "5h" in low or "5 hour" in low or low.startswith("session"):
        return "5-hour"
    if low.startswith("weekly") or low.startswith("week"):
        return "Weekly"
    m = re.match(r"^(.*?)\s+weekly$", label, re.I)
    if m:
        return m.group(1) + " weekly"
    return label[:18]


def main():
    out = []
    today = {"prompts": 0, "tokens": 0, "sessions": 0}
    try:
        names = sorted(os.listdir(USAGE))
    except OSError:
        names = []
    for name in names:
        if not name.endswith(".json"):
            continue
        try:
            with open(os.path.join(USAGE, name), encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, ValueError):
            continue
        if not isinstance(data, dict):
            continue
        for key, field in (("prompts", "todayPrompts"), ("tokens", "todayTotalTokens"), ("sessions", "todaySessions")):
            try:
                today[key] += max(0, int(data.get(field) or 0))
            except (TypeError, ValueError):
                pass
        # A note (a lapsed sign-in, the usage endpoint rate limiting) leaves
        # the last known limits in place, so show those rather than nothing.
        if not data.get("ready"):
            continue
        limits = []
        for limit in data.get("limits") or []:
            if not isinstance(limit, dict):
                continue
            try:
                percent = float(limit.get("percent"))
            except (TypeError, ValueError):
                continue
            limits.append({
                "label": short_label(limit),
                "percent": max(0.0, min(1.0, percent)),
                "resetsAt": str(limit.get("resetsAt") or ""),
            })
        if not limits:
            continue
        out.append({
            "id": str(data.get("id") or name[:-5]),
            "name": str(data.get("name") or name[:-5]),
            "tier": str(data.get("tierLabel") or ""),
            "limits": limits[:3],
        })
    out.sort(key=lambda a: (a["id"] != "claude", a["name"].lower()))
    print(json.dumps({"agents": out, "today": today}), flush=True)


if __name__ == "__main__":
    main()
