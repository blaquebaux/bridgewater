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

## Research plan (Path A — not yet built)

- **Reconstruct All-Weather.** Risk-parity across SPY/IEF/TLT/GLD/DBC/DBA (+ `RPAR`, the listed Risk
  Parity ETF, as a direct proxy). Characterize it: Sharpe, drawdown, and the stock-bond-correlation
  regime that breaks it (2022) — feeding straight into [bonds](https://github.com/blaquebaux/bonds)'
  finding that the diversification is regime-conditional.
- **All-Weather vs the spine.** Does Bridgewater's flagship beat the family's own risk-parity spine,
  or is it the same idea? Honest either way — if it ties, that *validates* the spine.
- **Pure Alpha — the gap, stated.** Document why discretionary macro is unobservable from prices, and
  what (if anything) a liquid proxy could stand in for — likely nothing faithful.

Nothing above is implemented or validated. This is the map, not the territory.

## Status
**Concept.** Thesis and research plan only — no sketches run, no driver. All-Weather is testable (and
overlaps the spine); Pure Alpha is a documented data gap.

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
research/   the research plan (Path A) — sketches land here once run
live/       governed live drivers (once a sleeve graduates to paper A/B)
```

## License
[MIT](LICENSE). (c) 2026 Carter Warrens.
