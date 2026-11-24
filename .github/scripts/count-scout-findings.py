"""Summarize a Docker Scout high/critical SARIF report for GitHub Actions."""

import json
import sys


def counts(report):
    runs = report["runs"]
    if not isinstance(runs, list) or not runs:
        raise ValueError("Expected at least one SARIF run")
    totals = {"critical": 0, "high": 0}
    for run in runs:
        results = run["results"]
        if not isinstance(results, list):
            raise ValueError("Expected a SARIF results array")
        rules = run["tool"]["driver"].get("rules", [])
        by_id = {rule["id"]: rule for rule in rules}
        for result in results:
            rule = by_id[result["ruleId"]]
            severity = rule["properties"]["cvssV3_severity"].lower()
            totals[severity] += 1
    return totals


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as source:
        totals = counts(json.load(source))
    total = sum(totals.values())
    print(f"critical_count={totals['critical']}")
    print(f"high_count={totals['high']}")
    print(f"post_build_vulns={total}")
    print("scan_status=" + ("vulnerabilities_found" if total else "clean"))
