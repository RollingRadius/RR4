# Testing Guide - Fleet Management System

## ✅ Fixes Applied

### Issue: 422 Unprocessable Content on Signup
**Problem:** Frontend wasn't sending security questions data with the signup request.

**Solution:** Updated signup flow to:
1. Collect basic user info (name, username, phone, password)
2. If "Security Questions" method → navigate to Security Questions screen
3. User selects and answers 3 questions
4. Complete signup data (with questions) is submitted to backend

**Files Modified:**
- `frontend/lib/presentation/screens/auth/signup_screen.dart`

---

## 🧪 How to Test Signup

### Method 1: Email Signup (Simplest for now)

1. **Go to Signup Screen**
   - Open the app in Chrome
   - Click "Sign Up" button

2. **Select "Email" Method**
   - Use the toggle button at the top
   - Select "Email" option

3. **Fill in the Form:**
   ```
   Full Name: Test User
   Username: testuser1
   Email: test@example.com
   Phone: 1234567890
   Password: Test1234!
   Confirm Password: Test1234!
   ```

4. **Accept Terms** and click "Sign Up"

5. **Expected Result:**
   - Success message: "Verification email sent"
   - Redirected to Login screen
   - **Note:** Email won't actually send (SMTP not configured)
   - Account will be in "pending_verification" status

---

### Method 2: Security Questions Signup (Full Flow)

1. **Go to Signup Screen**

2. **Select "Security Questions" Method**
   - Use the toggle button at the top
   - Select "Security Questions" option
   - Email field will hide

3. **Fill in the Form:**
   ```
   Full Name: Test User 2
   Username: testuser2
   Phone: 0987654321
   Password: Test1234!
   Confirm Password: Test1234!
   ```

4. **Accept Terms** and click "Sign Up"

5. **Security Questions Screen appears:**
   - Select 3 DIFFERENT questions from dropdowns
   - Answer each question (minimum 2 characters)
   - Example:
     - Q1: "What is your mother's maiden name?" → "Smith"
     - Q2: "What was the name of your first pet?" → "Buddy"
     - Q3: "In what city were you born?" → "Portland"

6. **Click "Continue"**

7. **Expected Result:**
   - Success message
   - Redirected to Login screen
   - Account is immediately active (can login right away!)

---

## 🔑 Test Login

After creating an account with **Security Questions method**:

1. Go to Login screen
2. Enter credentials:
   ```
   Username: testuser2
   Password: Test1234!
   ```
3. Click "Login"

**Expected Result:**
- Successful login
- Redirected to Dashboard
- Can see statistics, navigation, profile menu

---

## 📊 Check Backend Logs

Watch the backend terminal window for:

```
INFO:     127.0.0.1:XXXXX - "POST /api/auth/signup HTTP/1.1" 201 Created
```

**201 Created** = Success! ✅
**422 Unprocessable Content** = Validation error ❌

---

## 🐛 Troubleshooting

### Still Getting 422 Error?

1. **Check the browser DevTools (F12) → Network tab**
   - Find the `/api/auth/signup` request
   - Click on it
   - Check "Payload" or "Request" tab
   - Verify it includes:
     ```json
     {
       "full_name": "...",
       "username": "...",
       "phone": "...",
       "password": "...",
       "auth_method": "security_questions",
       "security_questions": [
         {
           "question_id": "Q1",
           "question_text": "...",
           "answer": "..."
         },
         ...3 total
       ],
       "terms_accepted": true
     }
     ```

2. **Check the Response tab** for specific validation error

3. **Hot Reload Flutter:**
   - In the Flutter terminal window
   - Press `r` to hot reload
   - Or press `R` for hot restart

### Backend Not Responding?

```powershell
# Check if backend is running
curl http://localhost:8000/

# Should return:
# {"message":"Fleet Management System API",...}
```

### Frontend Not Updating?

```powershell
cd E:\Projects\RR4\frontend
flutter clean
flutter run -d chrome
```

---

## ✅ What Should Work Now

- ✅ Email signup (creates pending_verification account)
- ✅ Security questions signup (creates active account)
- ✅ Login with security questions account
- ✅ Dashboard access after login
- ✅ Profile menu
- ✅ Logout

## ⏳ What's Not Implemented Yet

- ❌ Email verification (email not sent, but endpoint exists)
- ❌ Company selection during signup
- ❌ Password recovery
- ❌ Username recovery
- ❌ Actual vehicle/driver/trip management (mock data only)

---

## 📝 Database Verification

Check if your account was created:

```powershell
# If you have psql in PATH
psql -U postgres -d RR4 -c "SELECT username, full_name, auth_method, status FROM users;"

# Should show your test accounts
```

Or use pgAdmin to browse the `users` table.

---

## 🎯 Next Steps After Testing

Once signup/login works:

1. **Test Dashboard Features:**
   - View statistics cards
   - Click "Vehicles" tab (shows 5 mock vehicles)
   - Try search and filters
   - Check "Drivers", "Trips", "Reports" tabs

2. **Test Profile Menu:**
   - Click user avatar in top-right
   - Try "Profile", "Settings"
   - Test "Logout"

3. **Test Recovery Flows** (if curious):
   - These screens exist but won't work without SMTP
   - Password recovery
   - Username recovery

---

## 🔥 Hot Reload Tips

### Frontend:
- Press `r` in Flutter terminal for hot reload (fast, preserves state)
- Press `R` for hot restart (slower, resets state)
- Press `q` to quit

### Backend:
- Uvicorn auto-reloads when you save files
- Check terminal for reload messages

---

## 📞 If Something Breaks

1. **Check both terminal windows** (backend + frontend) for errors
2. **Check browser console** (F12) for JavaScript errors
3. **Restart services:**
   ```powershell
   # Ctrl+C in both windows, then:
   # Backend
   cd E:\Projects\RR4\backend
   venv\Scripts\activate
   uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload

   # Frontend
   cd E:\Projects\RR4\frontend
   flutter run -d chrome
   ```

---

Last Updated: 2026-01-21
Status: ✅ Signup Fixed - Ready to Test!
