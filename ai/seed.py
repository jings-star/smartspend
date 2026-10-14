"""
Creates ~3 months of fake transactions for ONE user so you can test the AI.

    python seed.py <uid>

Get the uid from Firebase Console > Authentication > Users (User UID).
Use a test account only. Run with GOOGLE_APPLICATION_CREDENTIALS set.
"""
import random
import sys
from datetime import datetime, timedelta, timezone

import firebase_admin
from firebase_admin import firestore

if len(sys.argv) != 2:
    sys.exit("usage: python seed.py <uid>")

firebase_admin.initialize_app()
col = (firestore.client().collection("users").document(sys.argv[1])
       .collection("transactions"))

now = datetime.now(timezone.utc)
random.seed(7)
rows = []
for m in range(3):
    base = now.replace(day=1) - timedelta(days=30 * m)
    rows.append(("income", "Allowance", 1500, base.replace(day=1)))
    rows.append(("expense", "Rent", 450, base.replace(day=2)))
    for d in range(3, 27):
        if random.random() < 0.8:
            rows.append(("expense", "Food", round(random.uniform(6, 22), 2),
                         base.replace(day=d)))
        if random.random() < 0.3:
            rows.append(("expense", "Transport", round(random.uniform(3, 12), 2),
                         base.replace(day=d)))
    rows.append(("expense", "Shopping", round(random.uniform(60, 150), 2),
                 base.replace(day=15)))
rows.append(("expense", "Shopping", 420, now - timedelta(days=4)))  # unusual

for kind, cat, amount, date in rows:
    if date <= now:
        col.add({"type": kind, "category": cat, "amount": amount, "date": date})
print("done")
