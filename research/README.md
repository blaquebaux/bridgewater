# Blaque Baux Bridgewater — research

First-pass research on Bridgewater's two engines. **All-Weather** is public and replicable, so it's
fully testable — and it doubles as an external check on the Blaque Baux spine. **Pure Alpha** is
discretionary global macro, private and unobservable — a documented gap. All sketches read Alpaca SIP
daily bars, are read-only, and print their own results.

```bash
export $(grep -v '^#' ~/.config/blaquebaux/alpaca.env | xargs)   # or source it
python research/bridgewater_1_allweather.py         # reconstruct All-Weather (static / risk-parity / RPAR)
python research/bridgewater_2_vs_spine.py           # All-Weather vs the family's own spine
python research/bridgewater_3_regime_purealpha.py   # the 2022 failure + the Pure Alpha gap
```

## Scorecard

| # | Question | Result | Verdict |
|---|----------|--------|---------|
| 1 | What does All-Weather deliver? | inverse-vol All-Weather **+0.95 Sharpe** (2019–26), ~⅓ the market's vol, half the drawdown, but far lower return (+7% vs SPY +15%); RPAR (the listed ETF) is a poor implementation (**+0.35**, −30% in 2022) | ✅ a real low-vol risk-parity compounder — smoothness bought with return |
| 2 | Any different from the spine? | All-Weather RP **+0.84** vs the family **spine +0.97** (2016–26), **correlation +0.96** — same book, and the spine *wins* by omitting the long-bond TLT sleeve | ✅ **the spine is an in-house All-Weather — and beats it** |
| 3 | The failure mode? | 2022 (stocks + bonds fall together): long-bond-heavy **All-Seasons −19%** (≈ SPY −18%, no protection), balanced RP **−9%** | ⚠️ breaks in the **positive stock-bond-correlation** regime |

## The synthesis

**Bridgewater's flagship is a great idea the family already runs — and runs better.** The three sketches
line up cleanly:

1. **All-Weather is a genuine low-vol risk-parity compounder.** Balanced by *risk* across stocks, bonds,
   gold and commodities (not by dollars in stocks), the inverse-vol version delivers a **higher Sharpe
   than the market at a third of the volatility and half the drawdown** — it just gives up headline
   return for smoothness. Note the gap between the *idea* and the *product*: the listed **RPAR** ETF is
   a mediocre, leveraged implementation (+0.35 Sharpe, −30% in 2022), a reminder that the concept is
   only as good as the execution.
2. **It is the same idea as the Blaque Baux spine — which validates the spine, and then beats it.** The
   family's asset-class spine (SPY/IEF/GLD/DBC/DBA, inverse-vol) is **0.96 correlated** to All-Weather
   and posts a *better* Sharpe (**+0.97 vs +0.84**) with a shallower drawdown — because it **omits
   All-Weather's heavy long-bond (TLT) sleeve.** Bridgewater's flagship carries no secret sauce a
   disciplined in-house inverse-vol book lacks; the one real design choice is duration, and the spine's
   choice to hold *intermediate* rather than *long* bonds is exactly what spared it the 2022 rate shock.
3. **Its one true weakness is the regime the family already maps.** All-Weather's whole premise is that
   bonds diversify stocks; when the **stock-bond correlation turns positive (2022)** that premise breaks
   and the long-bond-heavy static version fell −19%, no better than the S&P. That is precisely the
   regime [bonds](https://github.com/blaquebaux/bonds) found is real and partly knowable a quarter
   ahead — so All-Weather (and the spine) are **best paired with the bonds regime read** for *when*
   duration actually diversifies.

**Pure Alpha stays a documented gap** — a discretionary, leveraged, entirely private global-macro fund
with no NAV, no ticker, and no faithful liquid proxy. Unobservable from prices, and we say so rather
than fake it. The through-line across this sleeve, the spine, and bonds is one honest sentence:
**diversification is regime-conditional.**

## Status
**Research: first pass complete.** All-Weather = a validated low-vol risk-parity idea that the family's
spine already embodies (corr 0.96) and mildly *improves* on (less duration → beats it +0.97 vs +0.84);
its failure mode is the positive stock-bond regime that [bonds](https://github.com/blaquebaux/bonds)
maps. Pure Alpha is a documented data gap. Not a new keeper — an external validation of the spine and a
clean read on the world's most famous risk-parity fund. No live driver; nothing new to validate.
