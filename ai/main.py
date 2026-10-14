import os, re
from datetime import datetime, timedelta, timezone
from collections import defaultdict
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore

load_dotenv()
firebase_admin.initialize_app(
    credentials.Certificate(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))
)
db = firestore.client()
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # fine for development; restrict before release
    allow_methods=["*"],
    allow_headers=["*"],
)

MY_TZ = timezone(timedelta(hours=8))  # Malaysia time


@app.get("/")
def home():
    return {"status": "SmartSpend AI is running"}


# ---------- 1. AUTO-CATEGORIZE ----------
EXPENSE_CATS = ["Food", "Shopping", "Transport", "Bills", "Personal Care",
                "Entertainment", "Health", "Education"]
INCOME_CATS = ["Salary", "Allowance", "Gift", "Other"]

# Order matters: the first category that matches wins.
KEYWORDS = {
    "Food": ["starbucks", "mcd", "mcdonald", "kfc", "restaurant", "cafe", "nasi",
             "makan", "grab food", "grabfood", "foodpanda", "pizza", "coffee",
             "lunch", "dinner", "breakfast", "supper", "mamak", "teh", "bubble tea",
             "boba", "tealive", "chicken", "rice", "burger", "snack", "drink",
             "roti", "mee", "laksa", "satay", "kopi", "kopitiam", "zus", "chagee",
             "subway", "dominos", "texas chicken", "secret recipe", "sushi",
             "ramen", "noodle", "noodles", "bakery", "bread", "ice cream",
             "dessert", "juice", "milk tea", "tea", "grocery", "groceries",
             "mydin", "giant", "aeon", "tesco", "lotus", "99 speedmart", "kk mart",
             "7 eleven", "7-eleven", "market", "pasar"],
    "Transport": ["grab", "petrol", "shell", "petronas", "petron", "caltex", "toll",
                  "lrt", "mrt", "ktm", "erl", "monorail", "parking", "touch n go",
                  "tng", "bus", "taxi", "fuel", "uber", "mycar", "bolt", "indrive",
                  "train", "flight", "airasia", "car wash", "road tax", "saman"],
    "Shopping": ["shopee", "lazada", "tiktok shop", "mall", "uniqlo", "zalora",
                 "clothes", "shirt", "shoes", "mr diy", "daiso", "ikea", "h&m",
                 "shein", "bag", "dress", "pants", "gift shop", "gadget",
                 "phone case", "taobao", "aliexpress", "amazon", "ebay",
                 "johor premium outlet", "jpo"],
    "Bills": ["tnb", "unifi", "water bill", "syabas", "air selangor", "celcom",
              "maxis", "digi", "u mobile", "umobile", "hotlink", "yes 5g", "rent",
              "insurance", "electric", "electricity", "bill", "topup", "top up",
              "reload", "prepaid", "postpaid", "internet", "wifi", "loan",
              "installment", "instalment", "subscription"],
    "Personal Care": ["haircut", "hair cut", "salon", "barber", "shampoo",
                      "skincare", "watsons", "guardian", "toothpaste", "soap",
                      "makeup", "laundry", "dobi", "spa", "massage", "nails",
                      "manicure", "perfume", "lotion", "facial", "razor"],
    "Entertainment": ["netflix", "spotify", "cinema", "tgv", "gsc", "game",
                      "gaming", "steam", "movie", "concert", "youtube", "disney",
                      "karaoke", "bowling", "arcade", "ticket", "tickets",
                      "playstation", "xbox", "genshin", "mobile legends", "hobby"],
    "Health": ["pharmacy", "clinic", "hospital", "doctor", "medicine", "vitamin",
               "dentist", "dental", "checkup", "check up", "supplement", "panadol",
               "mask", "optometrist", "glasses", "contact lens", "physio"],
    "Education": ["tuition", "book", "books", "textbook", "course", "exam", "school",
                  "college", "university", "stationery", "pen", "fees", "fee",
                  "assignment", "printing", "print", "photocopy", "workshop",
                  "class", "ptptn repayment", "uniform", "kolej"],
}

INCOME_KEYWORDS = {
    "Salary": ["salary", "gaji", "payroll", "wage", "wages", "bonus", "commission"],
    "Allowance": ["allowance", "duit belanja", "pocket money", "ptptn", "scholarship",
                  "biasiswa", "bantuan"],
    "Gift": ["gift", "angpao", "ang pao", "duit raya", "hongbao", "red packet"],
}


def has_word(text: str, word: str) -> bool:
    # whole-word match: "bus" does not match "business"
    return re.search(rf"(?<!\w){re.escape(word)}(?!\w)", text) is not None


def categorize_text(text: str):
    t = text.lower()
    for cat, words in KEYWORDS.items():
        if any(has_word(t, w) for w in words):
            return cat
    return None


def detect_type(text: str):
    t = text.lower()
    for cat, words in INCOME_KEYWORDS.items():
        if any(has_word(t, w) for w in words):
            return "income", cat
    return "expense", categorize_text(text)


def parse_expense(text: str):
    m = re.search(r"(?:rm\s*)?(\d+(?:[.,]\d{1,2})?)", text, re.IGNORECASE)
    amount = float(m.group(1).replace(",", ".")) if m else None
    title = re.sub(r"(?:rm\s*)?\d+(?:[.,]\d{1,2})?", "", text, flags=re.IGNORECASE).strip()
    return title or text, amount


# ---------- learning from the user's own choices ----------
def memory_key(title: str) -> str:
    t = re.sub(r"[^a-z0-9 ]", "", title.lower())
    t = re.sub(r"\s+", " ", t).strip()
    return t.replace(" ", "_")[:100]


def memory_ref(user_id: str, title: str):
    key = memory_key(title)
    if not key:
        return None
    return (db.collection("users").document(user_id)
              .collection("categoryMemory").document(key))


def recall(user_id: str, title: str):
    ref = memory_ref(user_id, title)
    if ref is None:
        return None
    snap = ref.get()
    return snap.to_dict() if snap.exists else None


class ExpenseText(BaseModel):
    text: str
    user_id: str | None = None


class LearnRequest(BaseModel):
    user_id: str
    title: str
    category: str
    type: str = "expense"


@app.post("/categorize")
def categorize(req: ExpenseText):
    title, amount = parse_expense(req.text)

    # 1) the user's own earlier choice wins
    if req.user_id:
        try:
            mem = recall(req.user_id, title)
        except Exception:
            mem = None
        if mem:
            return {"title": title, "amount": amount,
                    "category": mem.get("category"),
                    "type": mem.get("type", "expense"),
                    "source": "memory"}

    # 2) keyword lists
    tx_type, category = detect_type(req.text)
    return {"title": title, "amount": amount, "category": category,
            "type": tx_type, "source": "keywords" if category else "unknown"}


@app.post("/learn")
def learn(req: LearnRequest):
    valid = INCOME_CATS if req.type == "income" else EXPENSE_CATS
    if req.category not in valid:
        return {"saved": False, "reason": "unknown category"}
    ref = memory_ref(req.user_id, req.title)
    if ref is None:
        return {"saved": False, "reason": "empty title"}
    ref.set({"category": req.category, "type": req.type,
             "title": req.title.strip(),
             "updatedAt": firestore.SERVER_TIMESTAMP})
    return {"saved": True}


# ---------- 2. CHAT (analyzes the user's data) ----------
def to_dt(v):
    if isinstance(v, datetime):
        v = v if v.tzinfo else v.replace(tzinfo=timezone.utc)
        return v.astimezone(MY_TZ)
    if isinstance(v, str):
        try:
            d = datetime.fromisoformat(v.replace("Z", "+00:00"))
            d = d if d.tzinfo else d.replace(tzinfo=MY_TZ)
            return d.astimezone(MY_TZ)
        except ValueError:
            return None
    return None


def is_income(e: dict) -> bool:
    t = e.get("type")
    if isinstance(t, str):
        return "income" in t.lower()      # "income", "TxType.income", "Income"
    if isinstance(t, bool):
        return False
    if isinstance(t, int):
        return t == 0                     # enum order: income = 0, expense = 1
    return False


def load_transactions(user_id: str):
    docs = db.collection("users").document(user_id).collection("transactions").stream()
    out = []
    for d in docs:
        e = d.to_dict()
        e["_dt"] = to_dt(e.get("date"))
        e["_income"] = is_income(e)
        e["title"] = e.get("title") or e.get("notes") or e.get("category") or ""
        e["category"] = e.get("category") or "Other"
        try:
            e["amount"] = float(e.get("amount", 0))
        except (TypeError, ValueError):
            e["amount"] = 0.0
        out.append(e)
    return out


def period_range(q: str):
    now = datetime.now(MY_TZ)
    start_today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    first_this_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    if "today" in q:
        return start_today, now, "today"
    if "week" in q:
        return now - timedelta(days=7), now, "in the last 7 days"
    if "last month" in q:
        prev_start = (first_this_month - timedelta(days=1)).replace(day=1)
        return prev_start, first_this_month, "last month"
    if "month" in q:
        return first_this_month, now, "this month"
    return None, None, "overall"


class ChatRequest(BaseModel):
    user_id: str
    message: str


HELP = ("I can answer things like:\n"
        "• How much did I spend this month?\n"
        "• What's my biggest category?\n"
        "• How much on food last month?\n"
        "• Show my breakdown this week\n"
        "• What's my income this month?\n"
        "• What's my balance this month?")


@app.post("/chat")
def chat(req: ChatRequest):
    q = req.message.lower()
    start, end, label = period_range(q)
    all_tx = load_transactions(req.user_id)
    if start:
        all_tx = [e for e in all_tx if e["_dt"] and start <= e["_dt"] <= end]

    incomes = [e for e in all_tx if e["_income"]]
    expenses = [e for e in all_tx if not e["_income"]]
    total_in = sum(e["amount"] for e in incomes)

    # Income questions
    if any(has_word(q, w) for w in ["income", "earn", "earned", "salary"]):
        return {"reply": f"Your income {label} is RM{total_in:.2f} across {len(incomes)} entries."}

    # Balance (works even when there are no expenses)
    if any(has_word(q, w) for w in ["balance", "left", "saving", "savings"]):
        total_out = sum(e["amount"] for e in expenses)
        return {"reply": f"{label.capitalize()}: income RM{total_in:.2f}, "
                         f"expenses RM{total_out:.2f}, left RM{total_in - total_out:.2f}."}

    if not expenses:
        return {"reply": f"I couldn't find any expenses {label}."}

    totals = defaultdict(float)
    for e in expenses:
        totals[e["category"]] += e["amount"]
    grand = sum(totals.values()) or 1

    # A specific category, e.g. "how much on food"
    for cat in totals:
        if has_word(q, cat.lower()):
            amt = totals[cat]
            return {"reply": f"You spent RM{amt:.2f} on {cat} {label} ({amt/grand:.0%} of your spending)."}

    # Biggest category
    if any(has_word(q, w) for w in ["most", "biggest", "highest", "top"]):
        cat, amt = max(totals.items(), key=lambda x: x[1])
        return {"reply": f"Your biggest category {label} is {cat}: RM{amt:.2f} ({amt/grand:.0%})."}

    # Single largest expense
    if "expensive" in q or "largest" in q:
        e = max(expenses, key=lambda x: x["amount"])
        return {"reply": f"Your largest expense {label} was {e['title']} at RM{e['amount']:.2f}."}

    # Breakdown
    if any(w in q for w in ["breakdown", "summary", "category", "categories"]):
        lines = [f"{c}: RM{a:.2f}" for c, a in sorted(totals.items(), key=lambda x: -x[1])]
        return {"reply": f"Spending {label}:\n" + "\n".join(lines) + f"\nTotal: RM{grand:.2f}"}

    # Total
    if any(w in q for w in ["total", "how much", "spent", "spend"]):
        return {"reply": f"You spent RM{grand:.2f} {label} across {len(expenses)} expenses."}

    return {"reply": HELP}


# Development only: remove before sharing the app.
@app.get("/debug/{user_id}")
def debug(user_id: str):
    docs = db.collection("users").document(user_id).collection("transactions").limit(3).stream()
    return [{"id": d.id, **{k: f"{v} ({type(v).__name__})" for k, v in d.to_dict().items()}} for d in docs]