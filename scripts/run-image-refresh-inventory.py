#!/usr/bin/env python3
"""Roll out Deployments listed in image-refresh-inventory.json for a given app key."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: run-image-refresh-inventory.py <app-key>", file=sys.stderr)
        return 2

    app = sys.argv[1]
    inv_path = Path(__file__).resolve().parent / "image-refresh-inventory.json"
    data = json.loads(inv_path.read_text(encoding="utf-8"))

    if app not in data:
        print(f"error: unknown app key {app!r}; keys: {list(data)}", file=sys.stderr)
        return 1

    targets = data[app].get("targets") or []
    if not targets:
        print(f"warning: no targets for {app!r}", file=sys.stderr)
        return 0

    for t in targets:
        ns = t["namespace"]
        dep = t["deployment"]
        print(f"=== rollout restart deployment/{dep} -n {ns} ===", flush=True)
        subprocess.run(
            ["kubectl", "rollout", "restart", f"deployment/{dep}", "-n", ns],
            check=True,
        )
        subprocess.run(
            [
                "kubectl",
                "rollout",
                "status",
                f"deployment/{dep}",
                "-n",
                ns,
                "--timeout=180s",
            ],
            check=False,
        )

    print("done.", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
