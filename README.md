# Blaque Baux Bridgewater

**Bridgewater's two engines — All-Weather (replicable) and Pure Alpha (a data gap) — examined honestly.**

Bridgewater is a member of the Blaque Baux family. The [core repo](https://github.com/blaquebaux/base)
is the **engine and blueprint** — a governed, systematic platform (Julia) with a venue-agnostic
execution controller and a Layer-3 live-money safety gate. Bridgewater points that engine at the
world's largest hedge fund's two signature strategies and inherits the governance wholesale.

> **Not investment advice.** Educational/research software. Nothing here is validated. See [LICENSE](LICENSE).

```bash
git clone --recursive https://github.com/blaquebaux/bridgewater.git
julia --project=engine -e 'using Pkg; Pkg.instantiate()'   # one-time engine setup
```

## The thesis

Bridgewater runs two very different engines, and they sit on opposite sides of what a price feed can
see:

- **All-Weather** is a *public, replicable idea*: balance a portfolio by **risk contribution** across
  the four macro environments (growth up/down × inflation up/down) using stocks, bonds, gold, and
  commodities, so no single environment dominates. It is essentially **risk parity** — and, notably,
  it is close to what the Blaque Baux **spine already does** (inverse-vol / equal-risk-contribution
  across SPY/IEF/GLD/DBC/DBA). That makes it fully testable, and the honest question is what it *is*:
  a low-vol diversified compounder, its real failure mode (2022, when stocks *and* bonds fell
  together), and whether it beats the family's own spine.
- **Pure Alpha** is a *discretionary global-macro fund* — leveraged, uncorrelated-to-markets, and
  **entirely private**: no public NAV, no ticker, no replicable rulebook. It cannot be reconstructed
  from price bars. We say so plainly rather than fake it (the same honesty as
  [basket](https://github.com/blaquebaux/basket)'s private funds).

## Research plan (Path A)

- **Reconstruct All-Weather.** Risk-parity across SPY/IEF/TLT/GLD/DBC/DBA (+ `RPAR`, the listed Risk
  Parity ETF, as a direct proxy). Characterize it: Sharpe, drawdown, and the stock-bond-correlation
  regime that breaks it (2022) — feeding straight into [bonds](https://github.com/blaquebaux/bonds)'
  finding that the diversification is regime-conditional.
- **All-Weather vs the spine.** Does Bridgewater's flagship beat the family's own risk-parity spine,
  or is it the same idea? Honest either way — if it ties, that *validates* the spine.
- **Pure Alpha — the gap, stated.** Document why discretionary macro is unobservable from prices, and
  what (if anything) a liquid proxy could stand in for — likely nothing faithful.

## Research — first pass done

Full detail in [`research/README.md`](research/README.md). The scorecard (Alpaca SIP, 2016–2026):

| # | Question | Verdict |
|---|----------|---------|
| 1 | What does All-Weather deliver? | ✅ a real **low-vol risk-parity compounder** — inverse-vol +0.95 Sharpe, ~⅓ the market's vol / half the DD, but +7% vs SPY +15% return; RPAR (the listed ETF) is a poor leveraged implementation (+0.35, −30% in 2022) |
| 2 | Any different from the family's spine? | ✅ **no — and the spine beats it**: correlation **+0.96**; spine +0.97 vs All-Weather +0.84, because the spine omits the long-bond TLT sleeve |
| 3 | The failure mode? | ⚠️ the **positive stock-bond regime** (2022): long-bond-heavy All-Seasons −19% (≈ SPY −18%, no protection) — exactly what [bonds](https://github.com/blaquebaux/bonds) maps |

**The synthesis:** Bridgewater's flagship is a great idea the family already runs — and runs *better*.
All-Weather is a genuine low-vol risk-parity compounder (higher Sharpe than the market at a third of the
vol), but it's **the same book as the Blaque Baux spine** (0.96 correlated), and the spine posts a
higher Sharpe (**+0.97 vs +0.84**) by holding *intermediate* rather than *long* bonds — the exact choice
that spared it the 2022 rate shock. There's no secret sauce a disciplined in-house inverse-vol book
lacks (and the listed **RPAR** ETF proves the concept is only as good as the execution). All-Weather's
one weakness is the positive stock-bond-correlation regime that breaks the "bonds diversify stocks"
premise — the regime [bonds](https://github.com/blaquebaux/bonds) found is partly knowable a quarter
ahead, so it's **best paired with the bonds regime read**. **Pure Alpha** stays a documented gap
(discretionary, private, unobservable). The through-line: *diversification is regime-conditional.*

## Live — a governed All-Weather book (and an overlay that, honestly, doesn't earn its place)

The static book is a legitimate, distinct sleeve even though the spine beats it: the recognizable public
Dalio **All-Seasons** allocation — **30% SPY / 15% IEF / 40% TLT / 7.5% GLD / 7.5% DBC** — run on the
same engine + Layer-3 safety gate as the spine. It is the family's *no-forecast, maximally-diversified,
low-vol* beta sleeve: +0.77 Sharpe at **8.9% vol and −23% maxDD** (vs SPY's 18% / −34%). [`live/bridgewater_live.jl`](live/bridgewater_live.jl).

The interesting part is what it teaches about wiring. All-Weather's one known failure is the positive
stock-bond regime (2022) — and the sibling [bonds](https://github.com/blaquebaux/bonds) sleeve publishes
*exactly* that (63d SPY-IEF correlation). So this is the **right signal for the book's actual weakness**.
Yet [`live/bridgewater_bonds_regime_validation.jl`](live/bridgewater_bonds_regime_validation.jl) FAILS the
family bar, and the overlay ships **OFF**:

| All-Seasons book (full 2016–2026 SIP, net 5bps) | Sharpe | CAGR | vol | maxDD |
|---|---|---|---|---|
| **FULL static (shipped)** | **+0.77** | 6.7% | 8.9% | −23% |
| + bonds-regime overlay | +0.74 | 5.2% | 7.3% | **−19%** |
| SPY (reference) | +0.88 | 15.3% | 18.0% | −34% |

The overlay cuts drawdown (−23% → −19%, a 20% cut) but **costs Sharpe (+0.77 → +0.74) and ~22% of
return** — so it fails "not worse on Sharpe" and "retains ≥80% of return." Why, when it's the *right*
signal? The 63d correlation flags "hedge dead" on ~**33% of days**, while All-Weather only truly *breaks*
in the acute 2022-type episodes; de-risking the other pos-corr stretches costs more return than it saves.
This is [benchmark #4](https://github.com/blaquebaux/benchmark)'s monotonic law from the other side:
All-Weather **already self-manages risk** (risk-parity across five asset classes, only −23% maxDD), so a
blunt de-risking overlay can't earn its keep — the **mirror image of [blackstone](https://github.com/blaquebaux/blackstone)**,
a naive high-beta book with *no* risk control, where the market_regime overlay earned a full Sharpe point.
Right signal, wrong book. Opt in with `BB_BONDS_OVERLAY=1` if you specifically want the ~20% drawdown cut.

```bash
BB_DRYRUN=1 bash live/run_bridgewater_daily.sh   # dry-run: logs the target, places nothing
```

Dry-run by default; graduates to paper once `~/.config/blaquebaux/alpaca_bridgewater.env` exists. Real
money additionally requires `BB_LIVE_CONFIRM`. Kill switch: `~/.config/blaquebaux/HALT`.

## Status
**Live driver built — a governed All-Weather book; the regime overlay tested and *declined*.** All-Weather
validates the family's own spine (corr 0.96) and is mildly *beaten* by it (less duration). The driver ships
the recognizable static All-Seasons allocation as a distinct low-vol/low-drawdown diversification sleeve,
but the bonds-regime overlay — the *right* signal for its 2022 weakness — fails the family bar (cuts DD 20%
but costs Sharpe and return) because the book already self-diversifies, so it ships OFF (opt-in). Pure Alpha
stays a documented data gap. Ships dry-run/paper; not yet run as real money.

## About Blaque Baux

**Blaque Baux** is a quantitative research initiative and a subsidiary of **[Carter Warrens](https://carterwarrens.com)**.
[**BlaqueBaux.com**](https://blaquebaux.com) is the home for the work; the code lives here on GitHub — open to
study, test, and build bespoke strategies on top of.

Anyone can point an AI at a market. The edge is **understanding what the data actually says — and turning it
into something you can act on.** We test relentlessly and put most of it *on the record as rejected, with the
reason*; what survives is built, governed, and validated before it is ever called real. That combination —
honest research, reproducible evidence, and execution you can trust — is why Carter Warrens leads on
**strategy and implementation**, not merely uses the tools everyone now has.

## The Blaque Baux family
This repo is one sleeve of the **Blaque Baux** family — a single governed engine steered in
many directions. The [core repo](https://github.com/blaquebaux/base) is the
base/blueprint and holds the [full family roster](https://github.com/blaquebaux/base#the-blaquebaux-family).

## Layout
```
engine/     the Blaque Baux platform (git submodule -> blaquebaux/base)
research/   three sketches (reconstruct All-Weather, vs the spine, 2022 failure + Pure Alpha gap) + scorecard
live/       bridgewater_live.jl (governed All-Weather book) + bonds-regime validation (declined) + wrapper/plist
```

## License
[MIT](LICENSE). (c) 2026 Carter Warrens.
