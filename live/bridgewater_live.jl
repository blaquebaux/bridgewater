#!/usr/bin/env julia
# ============================================================================
# bridgewater_live.jl — BLAQUE BAUX BRIDGEWATER live driver (All-Weather, bonds-regime gated).
#
# Runs on the Blaque Baux ENGINE (engine/ submodule) — same governed order path + Layer-3 safety gate
# as the spine.  data(5 asset-class ETFs) -> All-Seasons static book -> bonds-regime gross -> [ GATE ] -> orders.
#
# WHAT THIS IS (honest): the canonical, public Dalio "All-Weather / All-Seasons" allocation — balance a
# book across the macro environments by holding stocks, bonds (a lot of long duration), gold and
# commodities: 30% SPY / 15% IEF / 40% TLT / 7.5% GLD / 7.5% DBC.  Research found this is a genuine
# low-vol risk-parity idea (the inverse-vol version posts a higher Sharpe than the market at ~a third
# the vol) that the family's own spine already embodies (corr 0.96) and mildly improves on. So this
# sleeve is NOT a new edge — it's the recognizable, no-forecast, maximally-diversified beta book.
#
# Its ONE true weakness is a regime the family already maps: All-Weather's whole premise is that bonds
# diversify stocks; when the STOCK-BOND CORRELATION turns positive (2022) that premise breaks and the
# long-bond-heavy static book fell ~-19%, no better than the S&P.  That regime is exactly what benchmark's
# sibling BONDS sleeve publishes (63d SPY-IEF correlation).  So this driver can CONSUME bonds_regime.txt and
# de-risk gross x0.5 whenever the bond hedge is DEAD (pos-corr) — aiming the right signal at All-Weather's
# one weakness (contrast blackstone, whose right signal is market_regime).
#
# BUT the overlay ships OFF by default: live/bridgewater_bonds_regime_validation.jl FAILS the family bar.
# The 63d correlation flags "hedge dead" ~33% of days while All-Weather only truly breaks in the acute
# 2022-type episodes, so de-risking the rest of the pos-corr stretches cuts drawdown (-23% -> -19%) but
# costs Sharpe (+0.77 -> +0.74) and ~22% of return. All-Weather already self-diversifies (risk-parity,
# only -23% maxDD), so a blunt overlay can't clear the bar (benchmark #4's monotonic law; cf. broad/bore).
# Enable with BB_BONDS_OVERLAY=1 if you specifically want the ~20% drawdown reduction and will pay for it.
#
# Graceful: overlay OFF/missing/stale -> full book. Set BB_BONDS_OVERLAY=1 to switch it on.
# MODES: dry-run by default via the wrapper (BB_DRYRUN=1). Paper: unset BB_DRYRUN with paper keys.
# Real money requires BB_LIVE_CONFIRM=I_UNDERSTAND_THIS_IS_REAL_MONEY. Kill switch: ~/.config/blaquebaux/HALT.
# Run:  julia --project=engine live/bridgewater_live.jl
# ============================================================================
using Dates, Printf, Statistics

const REPO   = normpath(joinpath(@__DIR__, ".."))
const ENGINE = joinpath(REPO, "engine")
include(joinpath(ENGINE, "src/module_7_execution/module_7_execution.jl"))
include(joinpath(ENGINE, "src/module_10_feedback/module_10_feedback.jl"))
include(joinpath(ENGINE, "src/module_13_portfolio/module_13_portfolio.jl"))
include(joinpath(ENGINE, "src/module_1_data/equity_panel.jl"))
include(joinpath(ENGINE, "src/module_1_data/alpaca_panel.jl"))
include(joinpath(ENGINE, "src/module_8_governance/safety_gate.jl"))
using .ExecutionLayer, .FeedbackLayer, .PortfolioOptModule, .EquityPanel, .AlpacaPanel, .SafetyGate
include(joinpath(ENGINE, "scripts/live_execution.jl"))

# canonical public All-Seasons static weights (sum = 1.0, long-only, ~1x gross)
const ALLSEASONS = ["SPY" => 0.30, "IEF" => 0.15, "TLT" => 0.40, "GLD" => 0.075, "DBC" => 0.075]
const UNIVERSE = first.(ALLSEASONS)
const LIVE_SENTINEL = "I_UNDERSTAND_THIS_IS_REAL_MONEY"
const BONDS_DERISK = 0.5                                       # gross multiplier when the bond hedge is dead
const REGIME_MAXSTALE = Day(7)

_readf(p) = isfile(p) ? (v = tryparse(Float64, strip(read(p, String))); v === nothing ? NaN : v) : NaN
_writef(p, x) = (mkpath(dirname(p)); write(p, string(x)))

"Read bonds' published stock-bond regime (key=value). Returns (; ok, hedge_on, asof)."
function read_bonds_regime(path)
    isfile(path) || return (; ok = false)
    d = Dict{String,String}()
    for ln in eachline(path)
        s = strip(ln); (isempty(s) || startswith(s, "#")) && continue
        kv = split(s, "=", limit = 2); length(kv) == 2 && (d[strip(kv[1])] = strip(kv[2]))
    end
    ho = get(d, "hedge_on", ""); asof = tryparse(Date, get(d, "asof", ""))
    (ho in ("0", "1") && asof !== nothing) || return (; ok = false)
    (; ok = true, hedge_on = ho == "1", asof = asof)
end

"Gross multiplier from the bonds regime (graceful: off/missing/stale -> 1.0). Hedge dead (pos-corr) -> de-risk."
function bonds_scale(path; derisk = parse(Float64, get(ENV, "BB_BONDS_DERISK", string(BONDS_DERISK))))
    get(ENV, "BB_BONDS_OVERLAY", "0") in ("0", "false", "no") && return (1.0, "bonds overlay OFF (full book — validation FAIL, opt-in only)")
    r = read_bonds_regime(path)
    r.ok || return (1.0, "no bonds regime signal -> full book")
    (Dates.today() - r.asof) > REGIME_MAXSTALE && return (1.0, "bonds regime STALE ($(r.asof)) -> full book")
    r.hedge_on ? (1.0, "NEG-corr: bond hedge LIVE -> full All-Weather") : (derisk, "POS-corr: bond hedge DEAD -> de-risk x$derisk")
end

"Static All-Seasons book, scaled by the bonds-regime overlay."
function bridgewater_target(panel, cap; gross_scale = 1.0)
    syms = panel.symbols
    idx(s) = findfirst(==(s), syms); px(s) = panel.prices[idx(s)]
    net = Dict(s => w * gross_scale for (s, w) in ALLSEASONS)
    price = Dict(s => px(s) for s in UNIVERSE)
    targets = Dict(s => round(Float64, net[s] * cap / price[s]) for s in UNIVERSE)
    (targets = targets, prices = price, net = net)
end

function main(; capital = nothing, pool = "us", limits::SafetyLimits = SafetyLimits(),
              db_path     = get(ENV, "BB_LEDGER_PATH", joinpath(REPO, "alpaca_ledger_bridgewater.sqlite")),
              audit_path  = get(ENV, "BB_AUDIT_PATH",  joinpath(REPO, "alpaca_audit_bridgewater.jsonl")),
              hwm_path    = get(ENV, "BB_HWM_PATH",    joinpath(homedir(), ".config", "blaquebaux", "equity_hwm_bridgewater.txt")),
              equity_path = get(ENV, "BB_EQUITY_PATH", joinpath(homedir(), ".config", "blaquebaux", "equity_last_bridgewater.txt")),
              regime_path = get(ENV, "BB_REGIME_PATH", joinpath(homedir(), ".config", "blaquebaux", "bonds_regime.txt")))
    (get(ENV, "ALPACA_KEY_ID", "") == "" || get(ENV, "ALPACA_SECRET_KEY", "") == "") &&
        error("Set ALPACA_KEY_ID and ALPACA_SECRET_KEY (read-only bars are needed even in dry-run).")
    dryrun = get(ENV, "BB_DRYRUN", "") in ("1", "true", "yes")

    if dryrun
        panel = panel_at(AlpacaPanelProvider(UNIVERSE; lookback = 120))
        gscale, gnote = bonds_scale(regime_path)
        bk = bridgewater_target(panel, capital === nothing ? 100_000.0 : capital; gross_scale = gscale)
        @info "BRIDGEWATER dry run" asof=panel.asof
        println("\n  bonds regime -> ", gnote)
        println("  All-Weather static book (gross ", @sprintf("%.0f%%", 100sum(values(bk.net))), "):")
        for (s, w) in sort(collect(bk.net), by = x -> -x[2])
            @printf("    %-4s %5.1f%%  -> %d sh @ \$%.2f\n", s, 100w, Int(get(bk.targets, s, 0.0)), get(bk.prices, s, NaN))
        end
        ok, reasons = preflight(; account_status = "ACTIVE", equity = 100_000.0, hwm = 100_000.0,
            last_equity = 100_000.0, buying_power = 100_000.0, data_fresh = (Dates.today() - panel.asof) <= Day(5),
            targets = bk.targets, prices = bk.prices, limits = limits)
        println("\n  DRY RUN — no venue, no orders. Gate: ", ok ? "PASS" : "ABORT: " * join(reasons, "; "))
        return ok ? :dryrun_ok : :dryrun_gate_abort
    end

    live = get(ENV, "BB_LIVE_CONFIRM", "") == LIVE_SENTINEL; paper = !live
    mode = live ? "*** LIVE REAL MONEY ***" : "paper"
    @info "bridgewater_live starting" mode
    live && alert("BRIDGEWATER LIVE REAL-MONEY mode engaged"; level = :critical)
    venue = AlpacaVenue(AlpacaConfig(; paper = paper))
    built = build_live_controller(; venue = venue, ledger_config = LedgerConfig(; db_path = db_path), audit_path = audit_path)
    ctrl, ledger = built.ctrl, built.ledger
    try
        connect!(venue) || (alert("ABORT [$mode]: Alpaca connect failed (bridgewater)"; level = :critical); return :connect_failed)
        acct = account_info(venue)
        acct === nothing && (alert("ABORT [$mode]: could not read account (bridgewater)"; level = :critical); return :no_account)
        cap = capital === nothing ? acct.equity : capital
        hwm = max(load_hwm(hwm_path), acct.equity); last_eq = _readf(equity_path)
        panel = panel_at(AlpacaPanelProvider(UNIVERSE; lookback = 120)); fresh = (Dates.today() - panel.asof) <= Day(5)
        gscale, gnote = bonds_scale(regime_path); @info "bonds regime overlay" note=gnote
        bk = bridgewater_target(panel, cap; gross_scale = gscale)
        ok, reasons = preflight(; account_status = acct.status, trading_blocked = acct.trading_blocked,
            account_blocked = acct.account_blocked, equity = acct.equity, hwm = hwm, last_equity = last_eq,
            buying_power = acct.buying_power, data_fresh = fresh, targets = bk.targets, prices = bk.prices, limits = limits)
        save_hwm(hwm, hwm_path); _writef(equity_path, acct.equity)
        if !ok
            msg = "SAFETY ABORT [$mode] (bridgewater): " * join(reasons, "; "); @error msg
            halt!(ctrl, "safety gate"); alert(msg; level = :critical); return :aborted
        end
        reset_daily!(ctrl)
        set_pool_budget!(ctrl, pool, limits.max_gross_leverage * acct.equity)
        set_pool_loss_limit!(ctrl, pool, limits.max_daily_loss)
        set_pool_staleness!(ctrl, pool, Day(5)); feed_staleness!(ctrl, pool; stale = !fresh)
        isfinite(last_eq) && update_pnl!(ctrl, pool, acct.equity - last_eq)
        ncanc = cancel_all_open!(venue); ncanc > 0 && sleep(2)
        for (sym, qty) in positions(venue, ctrl.account); apply_fill!(ctrl, sym, qty); end
        res = execute_rebalance!(ctrl, ledger; targets = bk.targets, prices = bk.prices,
            signal_id = "bridgewater", regime = "all-weather-bondsx$(round(gscale, digits=2))",
            solve_id = Dates.format(panel.asof, "yyyymmdd"), pool_id = pool, settle_secs = 20)
        !res.reconciled && (alert("RECONCILE FAILED [$mode] (bridgewater) — halting"; level = :critical); halt!(ctrl, "reconcile mismatch"))
        summary = "[$mode] bridgewater All-Weather (gross $(round(Int, 100sum(values(bk.net))))%); orders=$(length(res.acks)) fills=$(length(res.fills)) reconciled=$(res.reconciled) equity=$(round(Int, acct.equity))"
        @info "bridgewater_live complete" summary; alert(summary; level = :info)
        return res.reconciled ? :ok : :reconcile_failed
    finally
        disconnect!(venue); close_ledger(ledger)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
