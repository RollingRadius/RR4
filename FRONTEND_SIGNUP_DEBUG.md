# Frontend Signup Debugging Guide

## ✅ Backend Status: WORKING

The backend signup endpoint is **fully functional**. I successfully created a test user using curl:

```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d @test_signup.json
```

**Response:**
```json
{
  "success": true,
  "user_id": "7edf4e71-4267-4b2e-ad6f-fe12c7d277eb",
  "username": "testuser2",
  "status": "active",
  "auth_method": "security_questions",
  "role": "Independent User"
}
```

---

## 🧪 Test Login with testuser2

Since "testuser2" was successfully created, you can test login now:

1. **Open your Flutter app in browser**
2. **Go to Login screen**
3. **Enter credentials:**
   - Username: `testuser2`
   - Password: `Test1234!`
4. **Click Login**

**Expected:** Should login successfully and go to dashboard! ✅

---

## 🐛 Why Frontend Signup Might Be Failing

The 422 error means the Flutter app is sending data that doesn't match what the backend expects. The Flutter app has **Dio LogInterceptor enabled**, so you should see detailed logs in your Flutter terminal.

### Check Flutter Console Logs

Look for lines like:
```
*** REQUEST ***
POST /api/auth/signup
{
  "full_name": "...",
  "username": "...",
  ...
}
```

**What to look for:**
1. Is `security_questions` array present when auth_method = "security_questions"?
2. Is `email` set to `null` (not empty string) for security questions method?
3. Does `security_questions` have exactly 3 items with `question_id`, `question_text`, `answer`?

---

## 🔍 How to Test Signup Properly

### Method 1: Security Questions Signup (Recommended)

1. **Open Signup screen**
2. **Select "Security Questions" auth method** (toggle button at top)
3. **Fill in all fields:**
   - Full Name: "Aman Yadav"
   - Username: "amanyadav"
   - Phone: "1234567890"
   - Password: "Test1234!"
   - Confirm Password: "Test1234!"
4. **Check "I accept terms and conditions"**
5. **Click "Sign Up" button**
6. **You should be navigated to Security Questions screen**
7. **Select 3 different questions and provide answers:**
   - Question 1: Select any question → Enter answer
   - Question 2: Select a different question → Enter answer
   - Question 3: Select a third different question → Enter answer
8. **Click "Continue"**
9. **Should show success message and navigate to Login**
10. **Now login with amanyadav / Test1234!**

### Method 2: Email Signup

1. **Open Signup screen**
2. **Select "Email" auth method**
3. **Fill in all fields (including email)**
4. **Click "Sign Up"**
5. **Should show "Verification email sent" message**
6. **Note:** Email won't actually send (needs SMTP config), but user will be created with status="pending_verification"

---

## ⚠️ Common Issues

### Issue 1: Clicking Signup Too Fast
**Problem:** Clicking "Sign Up" before completing security questions

**Solution:** Make sure you complete the entire flow:
- Fill form → Click Sign Up → Complete Security Questions screen → Click Continue

### Issue 2: Browser Cache
**Problem:** Old code cached in browser

**Solution:** Hard refresh the Flutter app:
- Chrome: `Ctrl+Shift+R` or `Cmd+Shift+R`
- Or close and restart Flutter: Press `R` in Flutter terminal

### Issue 3: Security Questions Not Loading
**Problem:** Security questions API failing

**Test:** Visit http://localhost:8000/api/auth/security-questions in browser
- Should return JSON with 10 questions
- If it fails, backend might need restart

---

## 📝 What the Flutter Logs Should Show

### Successful Signup Request

```
*** REQUEST ***
uri: http://localhost:8000/api/auth/signup
method: POST
data: {
  "full_name": "Aman Yadav",
  "username": "amanyadav",
  "email": null,
  "phone": "1234567890",
  "password": "Test1234!",
  "auth_method": "security_questions",
  "security_questions": [
    {
      "question_id": "Q1",
      "question_text": "What is your mother's maiden name?",
      "answer": "Smith"
    },
    {
      "question_id": "Q2",
      "question_text": "What was the name of your first pet?",
      "answer": "Buddy"
    },
    {
      "question_id": "Q3",
      "question_text": "In what city were you born?",
      "answer": "Portland"
    }
  ],
  "terms_accepted": true
}

*** RESPONSE ***
statusCode: 201
data: {
  "success": true,
  "user_id": "...",
  "username": "amanyadav",
  "status": "active",
  ...
}
```

### Failed Request (422)

```
*** RESPONSE ***
statusCode: 422
data: {
  "detail": [
    {
      "loc": ["body", "security_questions"],
      "msg": "Exactly 3 security questions are required",
      "type": "value_error"
    }
  ]
}
```

---

## 🚀 Quick Test Steps

**Test 1: Login with Existing User**
```
Username: testuser2
Password: Test1234!
```
Should work! ✅

**Test 2: Create New User via Frontend**
1. Signup screen → Security Questions method
2. Fill form completely
3. Complete security questions (3 different questions)
4. Check Flutter console for request/response logs
5. If 422, check the "detail" field in response for specific validation error

---

## 🔧 If Still Getting 422

1. **Check Flutter Terminal Output**
   - Look for Dio logs showing the actual request body
   - Find the validation error message in the response

2. **Test with Different Username**
   - Try username: "test123" (testuser2 already exists)

3. **Restart Both Servers**
   ```powershell
   # Backend
   Ctrl+C in backend terminal
   uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload

   # Frontend
   Press 'R' in Flutter terminal (hot reload)
   Or press 'Shift+R' (hot restart)
   ```

4. **Clear Browser Cache**
   - Chrome DevTools → Application tab → Clear storage
   - Or use incognito/private window

---

Last Updated: 2026-01-21
Status: Backend ✅ Working | Frontend 🔍 Needs Testing
