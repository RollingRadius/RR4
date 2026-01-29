# Company Search from Organizations Table

## Overview

During signup, when users choose to "Join Existing Company", they can search for companies. The search results come directly from the **organizations table** in the database.

## How It Works

### Signup Flow

1. **User Signs Up** → Enters username, password, security questions, etc.
2. **Company Selection** → Choose: Join Existing, Create New, or Skip
3. **Join Existing** → Opens company search screen
4. **Search** → User types company name (min 3 characters)
5. **Results** → Shows matching companies from organizations table
6. **Select** → User selects a company to join
7. **Pending** → User is added with status='pending', waits for owner approval

### Database Query

**Backend Query:**
```python
# backend/app/services/company_service.py: search_companies()
companies = self.db.query(Organization).filter(
    Organization.company_name.ilike(f"%{query}%"),  # Case-insensitive partial match
    Organization.status == 'active'                  # Only active companies
).limit(3).all()                                     # Max 3 results
```

**What it does:**
- Searches the `organizations` table (also called `company` table)
- Matches company name using case-insensitive partial match
- Only shows active companies (status='active')
- Returns maximum 3 results
- Shows: company_id, company_name, business_type, city, state

### API Endpoints

**Search Companies:**
```http
GET /api/companies/search?q={query}&limit=3
```

**Response:**
```json
{
  "success": true,
  "companies": [
    {
      "id": "uuid",
      "company_name": "ABC Transport",
      "business_type": "Transportation",
      "city": "Mumbai",
      "state": "Maharashtra"
    }
  ],
  "count": 1,
  "query": "ABC",
  "has_more": false
}
```

## What Was Fixed

### Issue: Wrong API Path

**Problem:** Frontend was calling `/api/auth/companies/search` but backend had `/api/companies/search`

**Files Fixed:**
- `frontend/lib/data/services/company_api.dart`

**Changes:**
```dart
// Before
'/api/auth/companies/search'  ❌
'/api/auth/companies/validate' ❌
'/api/auth/companies'          ❌

// After
'/api/companies/search'  ✅
'/api/companies/validate' ✅
'/api/companies'          ✅
```

## Frontend Implementation

### 1. Company Selection Screen
**File:** `frontend/lib/presentation/screens/company/company_selection_screen.dart`

Shows 3 options:
- **Join Existing Company** → Navigate to search
- **Create New Company** → Navigate to create form
- **Skip for Now** → Continue as independent user

### 2. Company Search Screen
**File:** `frontend/lib/presentation/screens/company/company_search_screen.dart`

Features:
- Search bar (min 3 characters)
- Real-time search results
- Company cards with name, location, business type
- Select company to join
- Confirmation dialog before joining

### 3. Company Provider
**File:** `frontend/lib/providers/company_provider.dart`

State management:
- `searchCompanies(query)` - Search for companies
- `searchResults` - List of matching companies
- `isLoading` - Loading state
- `error` - Error message

### 4. Company API Service
**File:** `frontend/lib/data/services/company_api.dart`

API calls:
- `searchCompanies(query)` - GET /api/companies/search
- `validateCompanyDetails()` - POST /api/companies/validate
- `createCompanySignup()` - POST /api/companies

## Backend Implementation

### 1. Company API Endpoint
**File:** `backend/app/api/v1/company.py`

```python
@router.get("/search", response_model=CompanySearchResponse)
async def search_companies(
    q: str = Query(..., min_length=3),
    limit: int = Query(3, ge=1, le=3),
    db: Session = Depends(get_db)
):
    company_service = CompanyService(db)
    result = company_service.search_companies(query=q, limit=limit)
    return CompanySearchResponse(**result)
```

### 2. Company Service
**File:** `backend/app/services/company_service.py`

```python
def search_companies(self, query: str, limit: int = 3) -> dict:
    # Query organizations table
    companies = self.db.query(Organization).filter(
        Organization.company_name.ilike(f"%{query}%"),
        Organization.status == 'active'
    ).limit(limit).all()

    # Return results
    return {
        "success": True,
        "companies": [company.to_search_result() for company in companies],
        "count": len(companies),
        "query": query,
        "has_more": total_count > limit
    }
```

### 3. Organization Model
**File:** `backend/app/models/company.py`

```python
class Organization(Base):
    __tablename__ = "organizations"

    id = Column(UUID(as_uuid=True), primary_key=True)
    company_name = Column(String(200), nullable=False)
    business_type = Column(String(100))
    city = Column(String(100))
    state = Column(String(100))
    status = Column(String(20), default='active')
    # ... other fields

    def to_search_result(self):
        """Convert to search result format"""
        return {
            "id": str(self.id),
            "company_name": self.company_name,
            "business_type": self.business_type,
            "city": self.city,
            "state": self.state
        }
```

## Database Schema

### Organizations Table
```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY,
    company_name VARCHAR(200) NOT NULL,
    business_type VARCHAR(100),
    business_email VARCHAR(255),
    business_phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    country VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### User Organizations Table
```sql
CREATE TABLE user_organizations (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    organization_id UUID REFERENCES organizations(id),
    role_id UUID REFERENCES roles(id),
    requested_role_id UUID REFERENCES roles(id),
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'active', 'inactive'
    joined_at TIMESTAMP,
    approved_at TIMESTAMP,
    approved_by UUID REFERENCES users(id)
);
```

## User Journey Example

1. **User registers:**
   - Username: john_doe
   - Email: john@example.com
   - Password: ********

2. **Company selection screen:**
   - Chooses "Join Existing Company"

3. **Search for company:**
   - Types: "ABC"
   - Results:
     - ABC Transport (Mumbai, Maharashtra)
     - ABC Logistics (Delhi, Delhi)
     - ABC Freight (Bangalore, Karnataka)

4. **Select company:**
   - Clicks on "ABC Transport"
   - Confirms selection

5. **Join request sent:**
   - User added to `user_organizations` table
   - organization_id: ABC Transport's ID
   - status: 'pending'
   - requested_role_id: Selected role

6. **Wait for approval:**
   - Owner sees pending request
   - Owner approves or rejects
   - If approved: status → 'active', user can access company features

## Testing

### Test Company Search

```bash
# Search for companies
curl "http://192.168.1.4:8000/api/companies/search?q=ABC&limit=3"

# Expected Response:
{
  "success": true,
  "companies": [
    {
      "id": "uuid",
      "company_name": "ABC Transport",
      "business_type": "Transportation",
      "city": "Mumbai",
      "state": "Maharashtra"
    }
  ],
  "count": 1,
  "query": "ABC",
  "has_more": false
}
```

### Frontend Testing

1. Run the Flutter app
2. Go to Signup
3. Complete registration form
4. Select "Join Existing Company"
5. Type at least 3 characters in search box
6. See list of companies from organizations table
7. Select a company
8. Confirm and complete signup

## Summary

✅ **Company list comes from organizations table**
✅ **Backend queries organizations table correctly**
✅ **Frontend API paths fixed to match backend**
✅ **Search works with minimum 3 characters**
✅ **Returns maximum 3 results**
✅ **Only shows active companies**
✅ **Case-insensitive partial match on company name**

All companies displayed during signup come directly from the `organizations` table in your database!
