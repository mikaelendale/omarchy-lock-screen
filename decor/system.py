#!/usr/bin/env python3
"""This machine at a glance, for the lock screen, as one JSON line:

  {"cpu": 0-100, "memory": 0-100, "temp": °C or null, "uptime": seconds}

cpu is how busy the processors were over a quarter of a second; memory is
the share in use (not counting what the kernel can hand back); temp is the
hottest CPU sensor that reports one. Nothing here is personal.
"""

import glob
import json
import os
import time


def cpu_times():
    with open("/proc/stat", encoding="ascii") as f:
        parts = f.readline().split()[1:]
    values = [int(v) for v in parts]
    idle = values[3] + (values[4] if len(values) > 4 else 0)
    return idle, sum(values)


def cpu_percent():
    try:
        idle1, total1 = cpu_times()
        time.sleep(0.25)
        idle2, total2 = cpu_times()
    except (OSError, ValueError, IndexError):
        return None
    total = total2 - total1
    if total <= 0:
        return None
    return round(100 * (1 - (idle2 - idle1) / total))


def memory_percent():
    info = {}
    try:
        with open("/proc/meminfo", encoding="ascii") as f:
            for line in f:
                key, _, rest = line.partition(":")
                info[key] = int(rest.split()[0])
    except (OSError, ValueError, IndexError):
        return None
    total = info.get("MemTotal", 0)
    available = info.get("MemAvailable", 0)
    if total <= 0:
        return None
    return round(100 * (1 - available / total))


def temperature():
    # CPU sensors by driver name: AMD (k10temp, zenpower), Intel (coretemp),
    # and the generic ACPI zone as a last resort.
    best = None
    for hwmon in glob.glob("/sys/class/hwmon/hwmon*"):
        try:
            with open(os.path.join(hwmon, "name"), encoding="ascii") as f:
                name = f.read().strip()
        except OSError:
            continue
        if name not in ("k10temp", "zenpower", "coretemp", "cpu_thermal", "acpitz"):
            continue
        for path in glob.glob(os.path.join(hwmon, "temp*_input")):
            try:
                with open(path, encoding="ascii") as f:
                    value = int(f.read().strip()) / 1000
            except (OSError, ValueError):
                continue
            if 0 < value < 130 and (best is None or value > best):
                best = value
        if best is not None and name != "acpitz":
            break
    return round(best) if best is not None else None


def uptime():
    try:
        with open("/proc/uptime", encoding="ascii") as f:
            return int(float(f.read().split()[0]))
    except (OSError, ValueError, IndexError):
        return None


print(json.dumps({"cpu": cpu_percent(), "memory": memory_percent(), "temp": temperature(), "uptime": uptime()}), flush=True)
