#!/usr/bin/env python3
"""Read kubectl pod JSON from stdin; write POD_INVENTORY_BY_NAMESPACE.md."""
import json
import os
import sys
from collections import defaultdict


def main() -> None:
    data = json.load(sys.stdin)
    items = data.get("items", [])

    by_ns: dict[str, list[dict]] = defaultdict(list)
    for it in items:
        md = it.get("metadata", {})
        ns = md.get("namespace", "?")
        name = md.get("name", "?")
        labels = md.get("labels") or {}
        status = (it.get("status") or {}).get("phase", "?")
        app = (
            labels.get("app")
            or labels.get("app.kubernetes.io/name")
            or labels.get("k8s-app")
            or labels.get("name")
            or "-"
        )
        component = labels.get("app.kubernetes.io/component") or labels.get("component") or ""
        owner = ""
        for ref in md.get("ownerReferences") or []:
            if ref.get("controller"):
                k = ref.get("kind", "")
                n = ref.get("name", "")
                owner = f"{k}/{n}"
                break
        by_ns[ns].append(
            {
                "name": name,
                "status": status,
                "app": app,
                "component": component,
                "owner": owner,
            }
        )

    counts = {ns: len(pods) for ns, pods in by_ns.items()}
    total = sum(counts.values())
    phase_totals: dict[str, int] = defaultdict(int)
    for plist in by_ns.values():
        for p in plist:
            phase_totals[p["status"]] += 1

    lines: list[str] = []
    lines.append("# Cluster pod inventory")
    lines.append("")
    lines.append("Generated from `kubectl get pods -A -o json` (current cluster context).")
    lines.append("")
    lines.append("Re-run after changes:")
    lines.append("")
    lines.append("```bash")
    lines.append("kubectl get pods -A -o json | python3 k8s_nas/scripts/generate_pod_inventory_md.py")
    lines.append("```")
    lines.append("")
    lines.append("## Summary: all pods by phase")
    lines.append("")
    lines.append("| Phase | Count |")
    lines.append("|-------|------:|")
    for ph in sorted(phase_totals.keys(), key=lambda x: (-phase_totals[x], x)):
        lines.append(f"| {ph} | {phase_totals[ph]} |")
    lines.append(f"| **Total** | **{total}** |")
    lines.append("")
    lines.append("## Summary: pod count by namespace")
    lines.append("")
    lines.append("| Namespace | Pods |")
    lines.append("|-----------|-----:|")
    for ns in sorted(counts.keys(), key=lambda n: (-counts[n], n)):
        lines.append(f"| `{ns}` | {counts[ns]} |")
    lines.append(f"| **Total** | **{total}** |")
    lines.append("")

    for ns in sorted(by_ns.keys(), key=lambda n: (-len(by_ns[n]), n)):
        pods = sorted(by_ns[ns], key=lambda p: (p["app"], p["name"]))
        lines.append(f"## `{ns}` ({len(pods)} pods)")
        lines.append("")
        lines.append("| Pod | Phase | app / name label | component | controller owner |")
        lines.append("|-----|-------|-------------------|-----------|------------------|")
        for p in pods:
            comp = p["component"] or "-"
            own = p["owner"] or "-"
            app_esc = str(p["app"]).replace("|", "\\|")
            lines.append(
                f"| `{p['name']}` | {p['status']} | {app_esc} | {comp} | `{own}` |"
            )
        lines.append("")

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = os.path.join(root, "docs", "POD_INVENTORY_BY_NAMESPACE.md")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(path, file=sys.stderr)


if __name__ == "__main__":
    main()
