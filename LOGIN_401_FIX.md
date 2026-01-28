# 401 Unauthorized - Login Fix

## 🎯 Quick Solution

**Login with the test account that I verified is working:**

```
Username: testuser2
Password: Test1234!
```

This account exists in the database and login works successfully.

---

## 🔍 Why You're Getting 401

The 401 Unauthorized error means **the username doesn't exist** or **the password is wrong**.

From the backend logs, you tried to login as "amanyadav", but that user was never successfully created because:
- The signup requests kept getting 422 validation errors
- The signup never completed
- No user "amanyadav" exists in the database

---

## ✅ Option 1: Test with Existing Account (Fastest)

1. **Open Flutter app**
2. **Go to Login screen**
3. **Enter:**
   - Username: `testuser2`
   - Password: `Test1234!`
4. **Click Login**
5. **Should work!** ✅

---

## 📝 Option 2: Create Your Own Account

### Step-by-Step Signup with Security Questions

1. **Open Signup screen in Flutter**

2. **Toggle to "Security Questions" method** (click the segmented button)

3. **Fill the form completely:**
   ```
   Full Name: Aman Yadav
   Username: amanyadav
   Phone: 9876543210
   Password: Test1234!
   Confirm Password: Test1234!
   ✓ I accept the terms and conditions
   ```

4. **Click "Sign Up" button**

5. **⚠️ CRITICAL:** You should be taken to a **Security Questions screen**
   - **If you don't see this screen, that's why signup is failing!**
   - The signup won't complete without answering security questions

6. **On Security Questions screen:**
   - **Question 1:** Select from dropdown → Enter answer
   - **Question 2:** Select DIFFERENT question → Enter answer
   - **Question 3:** Select DIFFERENT question → Enter answer
   - All 3 questions must be different!
   - Click "Continue"

7. **Should show:** "Signup successful! You can now login."

8. **Navigate back to Login**

9. **Login with:**
   - Username: `amanyadav`
   - Password: `Test1234!`

---

## 🐛 Troubleshooting 422 Errors During Signup

If you're still getting 422 errors when signing up:

### Check 1: Are Security Questions Loading?

Open browser and visit:
```
http://localhost:8000/api/auth/security-questions
```

**Expected:** JSON response with 10 security questions

**If it fails:** Backend issue - restart backend server

### Check 2: Flutter Console Logs

The Flutter app has detailed logging enabled. In your Flutter terminal, look for:

```
*** REQUEST ***
POST /api/auth/signup
{
  "full_name": "...",
  "username": "...",
  "security_questions": [...]  ← This should be present!
}

*** RESPONSE ***
statusCode: 422
data: {
  "detail": [
    {
      "loc": ["body", "field_name"],
      "msg": "Error message here"
    }
  ]
}
```

The "detail" field will tell you exactly what's wrong.

### Check 3: Complete the Full Flow

The signup flow has TWO screens:
1. **Signup Screen** → Fill basic info → Click Sign Up
2. **Security Questions Screen** → Answer 3 questions → Click Continue

**Common mistake:** Clicking Sign Up and expecting it to complete immediately. You MUST complete the security questions screen!

### Check 4: Browser Cache

Sometimes the browser caches old code. Try:
- **Hot restart Flutter:** Press `Shift+R` in Flutter terminal
- **Hard refresh browser:** `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
- **Or use incognito/private window**

---

## 🔍 Check Database Status

I created a script to see all users in the database:

**Windows:**
```powershell
Double-click: E:\Projects\RR4\backend\check_users.bat
```

**Or manually:**
```powershell
cd E:\Projects\RR4\backend
venv\Scripts\activate
python check_users.py
```

This will show:
- All usernames in database
- Which users can login
- Status of each account

---

## 🧪 Test Backend Directly

You can create an account directly via curl to verify backend works:

```powershell
cd E:\Projects\RR4\backend
curl -X POST http://localhost:8000/api/auth/signup -H "Content-Type: application/json" -d @test_signup.json
```

Then login:
```powershell
curl -X POST http://localhost:8000/api/auth/login -H "Content-Type: application/json" -d @test_login.json
```

Both should return 200/201 with user data.

---

## 📊 Current State Summary

✅ **Backend:** Working perfectly
- Signup endpoint works (tested with curl)
- Login endpoint works (tested with curl)
- User "testuser2" created successfully
- testuser2 can login with password "Test1234!"

❌ **Frontend:** Signup not completing
- 422 errors indicate incomplete request data
- Most likely: security_questions array not being sent
- Or: user not completing security questions screen

🎯 **Next Action:**
1. **Test login with testuser2** first (should work!)
2. **Then try signup** with a new username following the complete flow
3. **Check Flutter console** for detailed error messages if signup fails

---

## 🆘 If Still Stuck

Share these details:

1. **Flutter console output** when clicking Sign Up (look for REQUEST/RESPONSE logs)
2. **Screenshot of what happens** after clicking Sign Up button
3. **Do you see the Security Questions screen?** Yes/No
4. **Backend console logs** around the time of the request

This will help pinpoint exactly where the issue is.

---

Last Updated: 2026-01-21
Status: Backend ✅ | Frontend 🔄 Testing Needed
