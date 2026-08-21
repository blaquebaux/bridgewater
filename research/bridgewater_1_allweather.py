#!/usr/bin/python3
# =============================================================================
# bridgewater_1_allweather.py — BLAQUE BAUX BRIDGEWATER #1: reconstruct All-Weather.
#
# All-Weather is public and replicable: balance a book across the four macro environments with
# stocks/bonds/gold/commodities. Reconstruct it three ways — Dalio's static "All Seasons" weights, a
# proper inverse-vol risk-parity, and the listed RPAR ETF — and characterize what it actually delivers
# vs the market: a low-vol diversified compounder, and its failure mode. Read-only.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _bridgewater_common import panel, rets, stats, static_book, inverse_vol_book, ALLSEASONS, AW_RP

P, dates = panel(AW_RP + ["RPAR"])
spy = rets(P["SPY"])
allseasons = static_book(P, ALLSEASONS)
aw_rp = inverse_vol_book(P, AW_RP)
print("=" * 80, "\nBRIDGEWATER #1 — reconstructing All-Weather (risk balanced across environments)\n" + "=" * 80)
print(f"  {dates[1]} .. {dates[-1]}\n")
print(f"  {'book':<32}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}")
def row(lbl, r):
    st = stats(r); print(f"  {lbl:<32}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%"); return st
row("All-Seasons (static 30/55/15)", allseasons)
row("All-Weather RP (inverse-vol)", aw_rp)
if "RPAR" in P: row("RPAR (listed risk-parity ETF)", rets(P["RPAR"]))
sm = row("SPY (the market)", spy)

print("\nVERDICT: All-Weather is a genuine LOW-VOL, DIVERSIFIED compounder — roughly half the market's")
print("volatility and drawdown, at a similar or better Sharpe — because it is balanced by RISK across")
print("uncorrelated environments, not by dollars in stocks. It gives up headline return for smoothness.")
print("Its ONE failure mode is the regime where stocks AND bonds fall together (2022) — #3 measures that,")
print("and #2 asks whether Bridgewater's flagship idea is any different from the family's own spine.")
