#!/usr/bin/env python3
"""Collect client sources sequentially without publishing runtime datasets."""

import argparse
import fcntl
import json
import os
import re
import signal
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSIONS = ("forever", "era", "tbc", "wrath", "cata", "mop", "retail")
DEFAULTS = ("forever", "era", "tbc", "wrath", "cata", "mop")


def seed_paths(version):
    paths = [ROOT / "data/seeds" / (version + ".json"), ROOT / "data/seeds/legacy.json"]
    supplement = ROOT / "data/seeds" / (version + "-generic.json")
    if supplement.exists():
        paths.append(supplement)
    return paths


def write_status(state):
    state["updatedAt"] = datetime.now(timezone.utc).isoformat()
    path = ROOT / ".cache/wowhead/collection.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")
    temporary.replace(path)


def run_import(command):
    path = ROOT / ".cache/wowhead/collection.log"
    with path.open("a") as log:
        child = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, text=True, start_new_session=True)
        try:
            for line in child.stdout:
                print(line, end="", flush=True)
                log.write(line)
                log.flush()
            return child.wait()
        except KeyboardInterrupt:
            # Let the importer preserve successful responses and its snapshot.
            if child.poll() is None:
                child.send_signal(signal.SIGINT)
            child.wait()
            raise
        finally:
            child.stdout.close()


def collect_profiles(versions, interval):
    state = {"state": "running", "pid": os.getpid(), "profiles": {
        version: {"state": "queued"} for version in versions}}
    write_status(state)
    try:
        for version in versions:
            state["current"] = version
            state["profiles"][version] = {"state": "running"}
            write_status(state)
            command = [sys.executable, str(ROOT / "tools/import_wowhead.py"), version,
                       "--interval", str(interval)]
            for path in seed_paths(version):
                command.extend(["--seed", str(path)])
            print(f"Collecting {version}; published runtime data remains unchanged", flush=True)
            result = run_import(command)
            if result:
                state["profiles"][version] = {"state": "error", "exitCode": result}
                state["state"] = "error"
                write_status(state)
                return 1
            report = json.loads((ROOT / "data/reports" / (version + ".json")).read_text())
            denied = any(re.search(r"HTTP\s+(?:403|429)\b|source denied", str(error), re.I)
                         for error in report["failures"].values())
            state["profiles"][version] = {
                "state": "blocked" if denied else ("incomplete" if report["failures"] else "collected"),
                "fetched": report["fetched"], "included": report["included"],
                "failed": len(report["failures"]), "unresolved": len(report["unresolved"]),
                "unavailable": len(report["unavailable"]),
            }
            if denied:
                state["state"] = "blocked"
                write_status(state)
                print("Source denied access; the entire queue stopped. No automatic retry.", flush=True)
                return 2
            write_status(state)
        state["state"] = "collected" if all(
            profile["state"] == "collected" for profile in state["profiles"].values()) else "incomplete"
        state.pop("current", None)
        write_status(state)
        print("Collection finished. Review reports and validate each client before activation.", flush=True)
        return 0 if state["state"] == "collected" else 1
    except KeyboardInterrupt:
        state["state"] = "interrupted"
        if state.get("current"):
            state["profiles"][state["current"]]["state"] = "interrupted"
        write_status(state)
        return 130
    except Exception as error:
        state["state"], state["error"] = "error", str(error)
        write_status(state)
        raise


def show_status():
    path = ROOT / ".cache/wowhead/collection.json"
    state = json.loads(path.read_text()) if path.exists() else {"state": "not-started", "profiles": {}}
    if state["state"] == "running":
        try:
            os.kill(state["pid"], 0)
        except ProcessLookupError:
            state["state"] = "interrupted"
    for version, profile in state["profiles"].items():
        # Parser improvements may rebuild a completed profile while another
        # client is still fetching. Show the current report, not old counts
        # captured by the long-running queue process.
        report_path = ROOT / "data/reports" / (version + ".json")
        if profile["state"] in ("collected", "incomplete", "blocked") and report_path.exists():
            report = json.loads(report_path.read_text())
            profile.update({"fetched": report["fetched"], "included": report["included"],
                            "failed": len(report["failures"]), "unresolved": len(report["unresolved"]),
                            "unavailable": len(report["unavailable"]),
                            "runtimeRequired": len(report.get("runtimeRestorationRequired", {})),
                            "runtimePreferred": len(report.get("runtimeRestorationPreferred", []))})
        published = ROOT / "data/published" / (version + ".json")
        profile["enabled"] = published.exists() and bool(
            json.loads(published.read_text()).get("activation", {}).get("enabled"))
        ids = set()
        for seed in seed_paths(version):
            ids.update(json.loads(seed.read_text())["ids"])
        profile["candidates"] = len(ids)
        profile["cachedResponses"] = sum(
            (ROOT / ".cache/wowhead" / version / (str(item_id) + ".xml")).exists() for item_id in ids)
    print(json.dumps(state, indent=2, sort_keys=True))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("versions", nargs="*", help="Client profiles; default: forever era tbc wrath cata mop (Retail is deferred)")
    parser.add_argument("--interval", type=float, default=2)
    parser.add_argument("--status", action="store_true", help="Show queue state and live HTTP cache counts")
    args = parser.parse_args()
    if args.status:
        show_status()
        return 0
    versions = list(dict.fromkeys(args.versions or DEFAULTS))
    if args.interval < 0.5:
        parser.error("Use an interval of at least 0.5 seconds")
    for version in versions:
        if version not in VERSIONS:
            parser.error("Unknown client profile: " + version)
        for path in seed_paths(version):
            if not path.is_file():
                parser.error("Missing seed: " + str(path))
    path = ROOT / ".cache/wowhead/collection.lock"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a+") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error("Another collection queue is already running")
        # Terminal interruption and normal process termination both allow a
        # checkpoint; SIGKILL and power loss still preserve atomic XML files.
        def terminate(_signum, _frame):
            raise KeyboardInterrupt
        signal.signal(signal.SIGTERM, terminate)
        return collect_profiles(versions, args.interval)


if __name__ == "__main__":
    sys.exit(main())
