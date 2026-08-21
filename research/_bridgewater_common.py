#!/usr/bin/python3
# =============================================================================
# _bridgewater_common.py — shared helpers for the Blaque Baux Bridgewater sketches.
# Alpaca SIP daily bars; reads ALPACA_KEY_ID / ALPACA_SECRET_KEY from env. Read-only.
#
# All-Weather is a PUBLIC, replicable idea — balance a book by risk across the macro environments using
# stocks/bonds/gold/commodities. We reconstruct it two ways and compare it to the family's own spine
# (which is the same risk-parity idea):
#   All-Seasons (Dalio's public static): 30% SPY / 15% IEF / 40% TLT / 7.5% GLD / 7.5% DBC
#   All-Weather RP (inverse-vol):        SPY IEF TLT GLD DBC DBA
#   the family spine (inverse-vol):      SPY IEF GLD DBC DBA   (no long-bond TLT)
#   direct proxy: RPAR (the listed Risk Parity ETF, 2019+)
# Pure Alpha (discretionary global macro) is private/unobservable — a documented data gap, not faked.
# =============================================================================
import os, json, urllib.request, math
import numpy as np

H = {"APCA-API-KEY-ID": os.environ["ALPACA_KEY_ID"], "APCA-API-SECRET-KEY": os.environ["ALPACA_SECRET_KEY"]}
START, END = "2016-01-01", "2026-08-01"
_cache = {}
ASSETS = ["SPY", "IEF", "TLT", "GLD", "DBC", "DBA"]
ALLSEASONS = {"SPY": 0.30, "IEF": 0.15, "TLT": 0.40, "GLD": 0.075, "DBC": 0.075}   # static public weights
AW_RP   = ["SPY", "IEF", "TLT", "GLD", "DBC", "DBA"]                                # All-Weather risk-parity set
SPINE   = ["SPY", "IEF", "GLD", "DBC", "DBA"]                                       # the family's asset-class spine

def bars(s):
    if s in _cache: return _cache[s]
    u = (f"https://data.alpaca.markets/v2/stocks/bars?symbols={s}&timeframe=1Day"
         f"&start={START}&end={END}&adjustment=all&feed=sip&limit=10000")
    try:
        d = json.load(urllib.request.urlopen(urllib.request.Request(u, headers=H), timeout=40))
        _cache[s] = {b["t"][:10]: b for b in d.get("bars", {}).get(s, [])}
    except Exception:
        _cache[s] = {}
    return _cache[s]

def panel(syms):
    D = {s: bars(s) for s in syms}; D = {s: v for s, v in D.items() if len(v) > 250}
    u = list(D); dates = sorted(set.intersection(*[set(D[s]) for s in u]))
    M = np.array([[D[s][d]["c"] for s in u] for d in dates], float)
    return {s: M[:, i] for i, s in enumerate(u)}, dates

def rets(px): return px[1:] / px[:-1] - 1
def stats(r):
    r = np.asarray(r, float); r = r[np.isfinite(r)]
    if len(r) < 30 or r.std() == 0: return dict(sh=float('nan'), cagr=float('nan'), dd=float('nan'), vol=float('nan'))
    cum = np.cumprod(1 + r)
    return dict(sh=r.mean()/r.std()*math.sqrt(252), cagr=cum[-1]**(252/len(r))-1,
                dd=(cum/np.maximum.accumulate(cum)-1).min(), vol=r.std()*math.sqrt(252))
def corr(y, x):
    y = np.asarray(y, float); x = np.asarray(x, float); m = np.isfinite(y) & np.isfinite(x)
    return np.corrcoef(y[m], x[m])[0,1]

def inverse_vol_book(P, syms, vw=60, reb=21, cost_bps=5):
    """Causal inverse-vol (risk-parity) daily returns over syms; monthly rebalance, net of cost."""
    R = {s: rets(P[s]) for s in syms}; T = min(len(R[s]) for s in syms)
    Rm = np.vstack([R[s][-T:] for s in syms])                    # nsym x T
    out = []; w = np.ones(len(syms))/len(syms); wp = w.copy(); c = cost_bps/1e4
    for t in range(vw, T):
        if (t - vw) % reb == 0:
            iv = 1.0 / np.array([Rm[i, t-vw:t].std() for i in range(len(syms))])
            w = iv / iv.sum()
        r = float(np.dot(w, Rm[:, t]))
        if (t - vw) % reb == 0: r -= np.abs(w - wp).sum() * c; wp = w.copy()
        out.append(r)
    return np.array(out)

def static_book(P, weights, reb=21, cost_bps=5):
    syms = list(weights); R = {s: rets(P[s]) for s in syms}; T = min(len(R[s]) for s in syms)
    Rm = np.vstack([R[s][-T:] for s in syms]); w = np.array([weights[s] for s in syms])
    return np.array([float(np.dot(w, Rm[:, t])) for t in range(T)])
