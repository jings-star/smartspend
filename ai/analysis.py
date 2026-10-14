"""
Pure analysis logic: no Firebase, no network, so it is easy to test.

Input: a list of transaction dicts
    {"amount": 12.5, "type": "income"|"expense", "category": "Food", "date": datetime}
Output: features, a 0-100 financial health score, a label and traits.
"""
from __future__ import annotations

from collections import defaultdict
from datetime import datetime, timedelta, timezone
from statistics import median

WINDOW_DAYS = 90

# Categories counted as "needs"; every other expense counts as "wants".
# Edit this to match the categories in your app (lower-case).
NEEDS = {
    "food", "groceries", "transport", "rent", "bills", "utilities",
    "education", "tuition", "health", "phone", "internet",
}
# Expenses in these categories are treated as money saved, not spent.
SAVING_CATS = {"savings", "investment", "investments"}

# (needs, wants, savings) as a share of income. Adjust to your definitions.
TARGETS = {
    "50 / 30 / 20 Rule": (0.50, 0.30, 0.20),
    "Zero-Based Budgeting": (0.55, 0.25, 0.20),
    "Pay Yourself First": (0.50, 0.20, 0.30),
    "Envelope Method": (0.55, 0.30, 0.15),
}
DEFAULT_STYLE = "50 / 30 / 20 Rule"


def _aware(d: datetime) -> datetime:
    if d.tzinfo is None:
        return d.replace(tzinfo=timezone.utc)
    return d.astimezone(timezone.utc)


def _norm(c) -> str:
    return (c or "other").strip().lower()


def _clamp(x: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, x))


def build_features(txns: list[dict], style: str = DEFAULT_STYLE,
                   now: datetime | None = None) -> dict:
    now = _aware(now or datetime.now(timezone.utc))
    start = now - timedelta(days=WINDOW_DAYS)

    rows = []
    for t in txns:
        d = t.get("date")
        if d is None:
            continue
        d = _aware(d)
        if d < start or d > now + timedelta(days=1):
            continue
        amount = abs(float(t.get("amount") or 0))
        cat = _norm(t.get("category"))
        if t.get("type") == "income":
            kind = "income"
        elif cat in SAVING_CATS:
            kind = "saving"
        else:
            kind = "expense"
        rows.append({"date": d, "amount": amount, "kind": kind, "cat": cat})

    income = sum(r["amount"] for r in rows if r["kind"] == "income")
    expense = sum(r["amount"] for r in rows if r["kind"] == "expense")
    savings_rate = (income - expense) / income if income > 0 else None

    # ---- needs / wants / savings vs the chosen budgeting style ----
    needs = sum(r["amount"] for r in rows
                if r["kind"] == "expense" and r["cat"] in NEEDS)
    wants = expense - needs
    t_needs, t_wants, t_sav = TARGETS.get(style, TARGETS[DEFAULT_STYLE])
    split = None
    adherence = 0.0
    if income > 0:
        s_needs, s_wants = needs / income, wants / income
        s_sav = max(0.0, savings_rate)
        split = {
            "needs": round(s_needs, 3), "wants": round(s_wants, 3),
            "savings": round(s_sav, 3),
            "target": {"needs": t_needs, "wants": t_wants, "savings": t_sav},
        }
        # Only penalise overshooting needs/wants or saving less than the
        # target. Saving MORE than the target is never penalised.
        deviation = (max(0.0, s_needs - t_needs) + max(0.0, s_wants - t_wants)
                     + max(0.0, t_sav - s_sav))
        adherence = _clamp(1 - deviation / 0.3)

    # ---- top categories ----
    by_cat = defaultdict(float)
    for r in rows:
        if r["kind"] == "expense":
            by_cat[r["cat"]] += r["amount"]
    top = sorted(by_cat.items(), key=lambda kv: kv[1], reverse=True)[:3]
    top_categories = [
        {"name": n, "amount": round(v, 2),
         "share": round(v / expense, 3) if expense else 0}
        for n, v in top
    ]

    # ---- monthly trend (last 3 calendar months) ----
    monthly = defaultdict(lambda: {"income": 0.0, "expense": 0.0})
    for r in rows:
        key = r["date"].strftime("%Y-%m")
        if r["kind"] == "income":
            monthly[key]["income"] += r["amount"]
        elif r["kind"] == "expense":
            monthly[key]["expense"] += r["amount"]
    months = []
    for key in sorted(monthly)[-3:]:
        m = monthly[key]
        rate = (m["income"] - m["expense"]) / m["income"] if m["income"] else None
        months.append({
            "month": key, "income": round(m["income"], 2),
            "expense": round(m["expense"], 2),
            "savings_rate": None if rate is None else round(rate, 3),
        })

    cur_key = now.strftime("%Y-%m")
    # Trend = last FULL month vs the full month before it (a partial month
    # would give a misleading comparison).
    full = [k for k in sorted(monthly) if k < cur_key]
    change_pct = None
    if len(full) >= 2:
        last, before = monthly[full[-1]]["expense"], monthly[full[-2]]["expense"]
        if before > 0:
            change_pct = (last - before) / before

    # ---- unusual spending: >= 3x the usual amount in that category ----
    amounts = defaultdict(list)
    for r in rows:
        if r["kind"] == "expense":
            amounts[r["cat"]].append(r)
    anomalies = []
    for cat, items in amounts.items():
        if len(items) < 4:
            continue
        med = median(i["amount"] for i in items)
        if med <= 0:
            continue
        for i in items:
            if i["amount"] >= 3 * med:
                anomalies.append({
                    "category": cat, "amount": round(i["amount"], 2),
                    "usual": round(med, 2), "date": i["date"].date().isoformat(),
                })
    anomalies = sorted(anomalies, key=lambda a: a["amount"], reverse=True)[:3]

    # ---- logging consistency ----
    days_with_entry = {r["date"].date() for r in rows}
    if rows:
        first = min(r["date"] for r in rows)
        days_tracked = min(WINDOW_DAYS, max(1, (now - first).days + 1))
    else:
        days_tracked = 1
    consistency = _clamp(len(days_with_entry) / days_tracked)

    # ---- health score (0-100) ----
    sc_savings = _clamp((savings_rate or 0) / 0.20) * 40
    sc_adherence = adherence * 25
    sc_consistency = _clamp(consistency / 0.6) * 20
    if change_pct is None:
        sc_trend = 10.0
    elif change_pct <= 0:
        sc_trend = 15.0
    else:
        sc_trend = 15 * (1 - _clamp(change_pct / 0.5))
    score = round(sc_savings + sc_adherence + sc_consistency + sc_trend)

    return {
        "window_days": WINDOW_DAYS,
        "transactions": len(rows),
        "income": round(income, 2),
        "expense": round(expense, 2),
        "savings_rate": None if savings_rate is None else round(savings_rate, 3),
        "budget_style": style,
        "split": split,
        "top_categories": top_categories,
        "months": months,
        "spending_change_vs_last_month": None if change_pct is None else round(change_pct, 3),
        "anomalies": anomalies,
        "logging_consistency": round(consistency, 3),
        "score": score,
        "score_breakdown": {
            "savings": round(sc_savings), "budget_fit": round(sc_adherence),
            "consistency": round(sc_consistency), "trend": round(sc_trend),
        },
    }


def classify(f: dict) -> str:
    if f["transactions"] < 10:
        return "New Tracker"
    sr = f["savings_rate"]
    if sr is None:
        return "Expense Tracker"  # no income logged, cannot judge savings
    if sr >= 0.30:
        return "Super Saver"
    if sr >= 0.15:
        return "Balanced Saver"
    if sr >= 0:
        return "Tight Budgeter"
    return "Big Spender"


def traits(f: dict) -> list[str]:
    out = []
    if f["transactions"] < 10:
        return out
    if f["logging_consistency"] >= 0.5:
        out.append("Consistent Logger")
    change = f["spending_change_vs_last_month"]
    if change is not None and change > 0.2:
        out.append("Spending Rising")
    if change is not None and change < -0.1:
        out.append("Spending Falling")
    if f["top_categories"] and f["top_categories"][0]["share"] > 0.4:
        out.append(f"{f['top_categories'][0]['name'].title()}-Heavy")
    if f["anomalies"]:
        out.append("Occasional Big Spends")
    return out
