#!/usr/bin/env julia
# ============================================================================
# bridgewater_bonds_regime_validation.jl — does the BONDS regime overlay earn its place on All-Weather?
#
# All-Weather's one true weakness is the POSITIVE stock-bond-correlation regime (2022): its long-bond-heavy
# static book stops being diversified and falls with stocks. The bonds sleeve publishes exactly that regime
# (63d SPY-IEF correlation). Test the match: de-risk the All-Seasons book x0.5 whenever the bond hedge is
# DEAD (pos-corr). Fully causal daily walk-forward on the real static book; full 2016-2026 SIP, net of cost.
# The bar is overlay-appropriate (must not hurt Sharpe, must cut drawdown, must retain most of the return).
#   Run:  julia --project=engine live/bridgewater_bonds_regime_validation.jl
# ============================================================================
include(joinpath(@__DIR__, "bridgewater_live.jl"))
using Dates, Printf, Statistics

_sh(r; ann = 252) = (x = r[isfinite.(r)]; s = std(x); s > 0 ? mean(x) / s * sqrt(ann) : NaN)
_dd(r) = (lvl = cumprod(1 .+ r); minimum(lvl ./ accumulate(max, lvl) .- 1))
_cagr(r) = (lvl = cumprod(1 .+ r); lvl[end]^(252 / length(r)) - 1)
# fat-tail toolkit (family evaluation standard)
function _jb(r); r = r[isfinite.(r)]; n = length(r); m = mean(r); s = std(r); s == 0 && return (p=1.0, skew=0.0, exkurt=0.0, normal=true)
    z = (r .- m) ./ s; sk = mean(z.^3); ku = mean(z.^4) - 3; jb = n/6*(sk^2 + ku^2/4); (p=exp(-jb/2), skew=sk, exkurt=ku, normal=(exp(-jb/2) >= 0.05)); end
_jensen(r, rb; rf=0.0) = (b = cov(r, rb)/var(rb); (alpha_ann = ((mean(r) - rf/252) - b*(mean(rb) - rf/252))*252, beta = b))
_m2(r, rb; rf=0.0) = (shp = (mean(r)-rf/252)/std(r)*sqrt(252); shb = (mean(rb)-rf/252)/std(rb)*sqrt(252); (m2_excess = (shp-shb)*std(rb)*sqrt(252),))  # Sharpe-difference form (bench vs itself = 0)

function fetch_panel(U, lb = 2600)
    try
        return panel_at(AlpacaPanelProvider(U; lookback = lb, calendar_days = 4300, feed = "sip"), Dates.today() - Day(30))
    catch e
        m = match(r"only (\d+) common", sprint(showerror, e)); m === nothing && rethrow(e)
        n = parse(Int, m.captures[1]) - 20; (n < 400 || n >= lb) && rethrow(e)
        return fetch_panel(U, n)
    end
end

function main_validate(; warmup = 200, corr_win = 63,
                       cost_bps = parse(Float64, get(ENV, "BB_COST_BPS", "5")), derisk = BONDS_DERISK)
    panel = fetch_panel(unique(vcat(UNIVERSE, "SPY", "IEF")))   # SPY, IEF already in the book
    R = panel.returns; syms = panel.symbols; T = size(R, 1); cost = cost_bps/1e4
    si = Dict(s => k for (k,s) in enumerate(syms))
    spy = R[:, si["SPY"]]; ief = R[:, si["IEF"]]
    aw = vec(sum(hcat([R[:, si[s]] .* w for (s, w) in ALLSEASONS]...), dims = 2))   # static All-Seasons daily return

    full = Float64[]; over = Float64[]; oosidx = Int[]; sc_prev = 1.0; nde = 0; npos = 0
    for t in warmup:(T-1)
        corr = cor(@view(spy[t-corr_win+1:t]), @view(ief[t-corr_win+1:t]))
        sc = corr < 0 ? 1.0 : derisk; npos += 1; corr < 0 || (nde += 1)
        push!(full, aw[t+1]); push!(over, sc*aw[t+1] - abs(sc - sc_prev)*cost); push!(oosidx, t+1); sc_prev = sc
    end
    spyO = spy[oosidx]
    println("="^80, "\nBRIDGEWATER All-Weather + bonds-regime overlay — does patching the 2022 hole pay?\n", "="^80)
    @printf("\n  full 2016-2026 SIP; net %dbps; de-risk x%.2f when bond hedge DEAD (pos-corr, %.0f%% of days)\n", round(Int,cost*1e4), derisk, 100nde/npos)
    @printf("  %-30s %8s %8s %7s %8s\n", "book", "Sharpe", "CAGR", "vol", "maxDD")
    for (lbl, r) in [("FULL All-Seasons (static)", full), ("All-Seasons + bonds overlay", over), ("SPY (reference)", spyO)]
        @printf("  %-30s %+8.2f %7.1f%% %6.1f%% %7.0f%%\n", lbl, _sh(r), _cagr(r)*100, std(r)*sqrt(252)*100, _dd(r)*100)
    end
    println("\n  Fat-tail toolkit (does the overlay improve tail quality Sharpe can't see?):")
    @printf("  %-30s %8s %7s %8s %9s %8s\n", "book", "JB p", "skew", "exkurt", "Jensen α", "M² exc")
    for (lbl, r) in [("FULL All-Seasons", full), ("+ bonds overlay", over)]
        j = _jb(r); je = _jensen(r, spyO); m = _m2(r, spyO)
        @printf("  %-30s %8.3f %+7.2f %8.1f %+8.1f%% %+7.1f%%   (%s)\n", lbl, j.p, j.skew, j.exkurt,
                je.alpha_ann*100, m.m2_excess*100, j.normal ? "normal" : "NON-normal → tail matters")
    end
    shF, shO, ddF, ddO = _sh(full), _sh(over), _dd(full), _dd(over)
    dd_cut = 1 - abs(ddO)/abs(ddF); ret_keep = _cagr(over)/_cagr(full)
    println("\n  THE BAR (overlay must earn its place — same bar as broad/bonds):")
    checks = [ ("Sharpe not worse (>= FULL - 0.03)", shO >= shF-0.03, @sprintf("%.2f vs %.2f", shO, shF)),
               ("reduces max drawdown",              ddO > ddF,       @sprintf("%.0f%% -> %.0f%% (%.0f%% cut)", ddF*100, ddO*100, dd_cut*100)),
               ("retains >= 80% of return",          ret_keep >= 0.80, @sprintf("%.0f%% kept", ret_keep*100)) ]
    for (n, ok, v) in checks; @printf("    [%s] %-36s %s\n", ok ? "PASS" : "FAIL", n, v); end
    allpass = all(c -> c[2], checks)
    println("\n  DECISION: ", allpass ?
        "ON by default — the bonds regime patches All-Weather's positive-correlation failure mode; the right signal for this book." :
        "OFF by default — the overlay does not clearly earn its place on the static book; ships off (raw All-Weather).")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_validate()
end
