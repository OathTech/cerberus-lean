#!/usr/bin/env python3
"""Reproduce D2's Lean CPU comparison from the adjacent committed TSVs.

Ordinary 90-second repetitions supply both CPU means for the three inputs
censored only by HEAD's 15-second run. All other ratios use the lane data.
No sampled/profiling CPU time enters this table. Durations are GNU time's
0.01-second measurements; ratio digits do not imply additional accuracy.
"""
from collections import Counter
import csv
from pathlib import Path
from statistics import mean, median

ROOT = Path(__file__).resolve().parent


def read(name):
    with (ROOT / name).open() as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def write(name, fields, rows):
    with (ROOT / name).open("w", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(fields)
        writer.writerows(rows)


def derive():
    head_rows = read("head-before-15.tsv")
    pre_rows = read("pre-before-15-shard1.tsv") + read("pre-before-15-shard2.tsv")
    assert len(head_rows) == 3338 and len(pre_rows) == 1116
    for rows in [head_rows, pre_rows]:
        assert len({(r["input"], r["engine"]) for r in rows}) == len(rows)
    head = {r["input"]: r for r in head_rows if r["engine"] == "lean"}
    pre = {r["input"]: r for r in pre_rows if r["engine"] == "lean"}
    assert set(pre) == set(sorted(head)[:558])
    assert sum(n.startswith("sa_") for n in pre) == 470
    raised = {}
    pairs = []
    for subset in ["known", "419"]:
        h = {(r["repeat"], r["probe"]): r for r in read(f"head-{subset}-before-90.tsv")
             if r["engine"] == "lean-exh"}
        p = {(r["repeat"], r["probe"]): r for r in read(f"pre-{subset}-before-90.tsv")
             if r["engine"] == "lean-exh"}
        assert set(h) == set(p)
        for name in sorted({name for _, name in h}):
            assert {rep for rep, n in h if n == name} == {"1", "2"}
            for rep in ["1", "2"]:
                hr, pr = h[rep, name], p[rep, name]
                assert hr["exit"] == pr["exit"] == "0"
                assert hr["note"] == pr["note"] == "-"
                assert hr["verdict"] == pr["verdict"]
                a, b = float(pr["cpu_s"]), float(hr["cpu_s"])
                assert a > 0
                pairs.append((name + ".c", rep, pr["cpu_s"], hr["cpu_s"], f"{b/a:.6f}"))
            raised[name + ".c"] = (
                mean(float(p[rep, name]["cpu_s"]) for rep in ["1", "2"]),
                mean(float(h[rep, name]["cpu_s"]) for rep in ["1", "2"]))
    assert set(raised) == {"sa_csmith_369.c", "sa_csmith_371.c", "sa_csmith_419.c"}
    assert {n for n, r in pre.items() if r["exit"] == "0" and head[n]["exit"] != "0"} == set(raised)
    completed, excluded, ratios = [], [], []
    for name in sorted(pre):
        pr, hr = pre[name], head[name]
        if name in raised:
            a, b = raised[name]
            source = "mean_of_two_90s_repeats_on_each_binary"
        elif pr["exit"] == hr["exit"] == "0":
            a, b = float(pr["cpu_s"]), float(hr["cpu_s"])
            source = "15s_lane_observations"
        else:
            excluded.append((name, pr["status"], hr["status"], pr["exit"], hr["exit"],
                             "unexecuted_or_censored; no completed-CPU ratio"))
            continue
        assert a > 0 and b > 0
        ratio = b / a
        ratios.append(ratio)
        completed.append((name, f"{a:.3f}", f"{b:.3f}", f"{ratio:.6f}", source,
                          pr["status"], hr["status"]))
    assert len(completed) == 287 and len(excluded) == 271
    write("before-prearc-ratios.tsv",
          ["input", "cpu_pre", "cpu_head", "ratio", "cpu_source", "status_pre_15", "status_head_15"], completed)
    write("before-prearc-excluded.tsv",
          ["input", "status_pre_15", "status_head_15", "exit_pre_15", "exit_head_15", "reason"], excluded)
    write("known-before-ratios.tsv", ["input", "repeat", "cpu_pre", "cpu_head", "ratio"], sorted(pairs))
    print("D2 comparison integrity OK: 558 required inputs = 287 completed-CPU ratios + 271 explicitly excluded inputs.")
    print("Derived pre-arc joint-status tally:", dict(Counter(r["status"] for r in pre.values())))
    print("Derived ratio tally: above_1.10=" + str(sum(r > 1.10 for r in ratios))
          + "; at_or_below_1.10=" + str(sum(r <= 1.10 for r in ratios)))
    print(f"Derived ratio min={min(ratios):.6f} median={median(ratios):.6f} max={max(ratios):.6f}")
    print("Only the three censored HEAD inputs use raised-budget repeats; all remaining ratios are single lane observations.")
    print("No D4/post-remedy verdict: short-duration ratios have 0.01-second quantization, and deciding ratios must be repeated.")


if __name__ == "__main__":
    derive()
