# Quick Fix - SQLAlchemy Relationship Error

## ✅ What I Fixed

**Problem:** SQLAlchemy error when trying to signup:
```
AmbiguousForeignKeysError: Could not determine join condition between User and UserOrganization
```

**Root Cause:** The `UserOrganization` table has TWO foreign keys to the `User` table:
- `user_id` (the user who belongs to the organization)
- `approved_by` (the user who approved them)

This created ambiguity for SQLAlchemy.

**Fix Applied:** Updated `backend/app/models/user.py` line 52-57 to specify which foreign key to use:
```python
organizations = relationship(
    "UserOrganization",
    foreign_keys="UserOrganization.user_id",  # <-- Added this
    back_populates="user",
    cascade="all, delete-orphan"
)
```

---

## 🔄 RESTART REQUIRED

**Python model changes require a server restart!**

### Step 1: Stop Backend Server

Go to the **Backend terminal window** and press: **`Ctrl+C`**

Wait for it to stop completely.

### Step 2: Restart Backend Server

In the same terminal window, run:
```powershell
cd E:\Projects\RR4\backend
venv\Scripts\activate
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

### Step 3: Wait for Startup

You should see:
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000
```

---

## ✅ Test It Works

Once backend restarts, try this in PowerShell:

```powershell
cd E:\Projects\RR4\backend
curl -X POST http://localhost:8000/api/auth/signup -H "Content-Type: application/json" -d @test_signup.json
```

**Expected:** 201 Created (success!) or a different error (not SQLAlchemy)

---

## 🎯 Then Test in Browser

1. **Refresh the Flutter app** (or press `R` in Flutter terminal)
2. **Try signup again** with Security Questions method
3. **Should work now!** ✅

---

## Alternative: Use start_backend.bat

You can also restart using the batch file:

1. Close the backend terminal window
2. Double-click: `E:\Projects\RR4\start_backend.bat`

---

Last Updated: 2026-01-21
Status: Fix Applied - Restart Needed!
