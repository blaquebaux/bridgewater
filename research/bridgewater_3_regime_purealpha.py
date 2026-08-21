#!/usr/bin/python3
# =============================================================================
# bridgewater_3_regime_purealpha.py — BLAQUE BAUX BRIDGEWATER #3: the 2022 failure & the Pure Alpha gap.
#
# All-Weather's whole premise is that bonds diversify stocks. When the stock-bond correlation flips
# POSITIVE (2022), that premise breaks and the book takes its worst drawdown — the exact regime the
# family's bonds sleeve found is real and (partly) knowable. Quantify the 2022 stress, then state the
# honest gap: Pure Alpha (discretionary global macro) is private and unobservable. Read-only.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _bridgewater_common import panel, rets, stats, static_book, inverse_vol_book, ALLSEASONS, AW_RP

P, dates = panel(AW_RP); d = dates[1:]
aw = inverse_vol_book(P, AW_RP); allseasons = static_book(P, ALLSEASONS)
spy = rets(P["SPY"]); ief = rets(P["IEF"])
# align spy/ief to the AW inverse-vol series length (it starts after the vol warmup)
off = len(spy) - len(aw); spy_a = spy[off:]; ief_a = ief[off:]; d_a = d[off:]
def win(a, b, dd):
    lo = next((i for i,x in enumerate(dd) if x >= a), 0); hi = next((i for i,x in enumerate(dd) if x >= b), len(dd))
    return slice(lo, hi)

print("=" * 80, "\nBRIDGEWATER #3 — the 2022 failure (stocks + bonds together) & the Pure Alpha gap\n" + "=" * 80)
# rolling 63d stock-bond correlation to show the regime flip
w = 63; sbc = np.full(len(spy_a), np.nan)
for i in range(w, len(spy_a)):
    a, b = spy_a[i-w:i], ief_a[i-w:i]
    if a.std() > 0 and b.std() > 0: sbc[i] = np.corrcoef(a, b)[0,1]
s22 = win("2022-01-01", "2023-01-01", d_a)
print(f"\n  2022 (the rate shock): stock-bond corr avg {np.nanmean(sbc[s22]):+.2f} (POSITIVE — the hedge failed)")
print(f"  {'book':<32}{'2022 return':>13}{'2022 maxDD':>12}")
for lbl, r in [("All-Weather RP", aw[s22]), ("All-Seasons (long-bond heavy)", allseasons[len(allseasons)-len(aw)+s22.start:len(allseasons)-len(aw)+s22.stop]), ("SPY", spy_a[s22])]:
    cum = np.cumprod(1+r); dd = (cum/np.maximum.accumulate(cum)-1).min()
    print(f"  {lbl:<32}{(cum[-1]-1)*100:>+12.0f}%{dd*100:>+11.0f}%")

print("\n  Pure Alpha — THE GAP (stated, not faked):")
print("    Pure Alpha is a DISCRETIONARY global-macro fund: leveraged, actively traded across ~dozens of")
print("    markets, and ENTIRELY PRIVATE — no public NAV, no ticker, no replicable rulebook. It cannot be")
print("    reconstructed from price bars, and no liquid instrument stands in for it faithfully. Unobservable.")

print("\nVERDICT: All-Weather's one true weakness is the positive stock-bond-correlation regime — 2022 hit")
print("it hard (the long-bond-heavy static version worst), exactly the regime the family's BONDS sleeve")
print("maps. So the honest, useful synthesis: All-Weather = a great low-vol risk-parity compounder that")
print("shares the family's own vulnerability, best paired with the bonds regime read for WHEN duration")
print("diversifies. Pure Alpha stays a documented gap. Diversification is regime-conditional — the through-line.")
