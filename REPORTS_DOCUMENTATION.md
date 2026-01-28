# Reports & Analytics Documentation

## Overview
Comprehensive reporting system for fleet management with 5 key report types to monitor drivers, licenses, users, and organizational activity.

## Features Implemented

### Backend (Python/FastAPI)

#### 1. Report Schemas (`backend/app/schemas/report.py`)
Pydantic models for:
- Driver List Report
- License Expiry Report
- Organization Summary Report
- Audit Log Report
- User Activity Report

#### 2. Report Service (`backend/app/services/report_service.py`)
Business logic for generating reports:
- `get_driver_list_report()` - All drivers with license info
- `get_license_expiry_report()` - License compliance tracking
- `get_organization_summary_report()` - KPIs and stats
- `get_audit_log_report()` - System activity logs
- `get_user_activity_report()` - User engagement metrics

#### 3. Report API Endpoints (`backend/app/api/v1/reports.py`)
REST API endpoints:
- `GET /api/reports/driver-list`
- `GET /api/reports/license-expiry`
- `GET /api/reports/organization-summary`
- `GET /api/reports/audit-log`
- `GET /api/reports/user-activity`

### Frontend (Flutter)

#### 1. Report Data Service (`frontend/lib/data/services/report_api.dart`)
API client for report endpoints

#### 2. Report Provider (`frontend/lib/providers/report_provider.dart`)
State management for reports with loading/error handling

#### 3. Report Screens
- **Reports Dashboard** - Grid of report cards
- **Organization Summary** - Key metrics and recent activity
- **Driver List** - Filterable driver list with license status
- **License Expiry** - License compliance with color-coded alerts
- **Audit Log** - Coming soon
- **User Activity** - Coming soon

## Report Types

### 1. Organization Summary Report

**Purpose:** High-level overview of organization health

**Metrics:**
- Driver Statistics
  - Total drivers
  - Active/Inactive/On Leave/Terminated counts
- User Statistics
  - Total users
  - Active/Pending counts
- License Compliance
  - Licenses expiring soon (within 30 days)
  - Expired licenses
- Recent Activity (last 10 actions)

**Use Cases:**
- Dashboard overview
- Management reporting
- Quick health check
- KPI monitoring

**API Endpoint:**
```
GET /api/reports/organization-summary
```

**Response:**
```json
{
  "success": true,
  "report_type": "organization_summary",
  "organization_id": "uuid",
  "organization_name": "Company Name",
  "generated_at": "2026-01-27T12:00:00",
  "stats": {
    "total_drivers": 25,
    "active_drivers": 20,
    "licenses_expiring_soon": 3,
    "expired_licenses": 1
  },
  "recent_activity": [...]
}
```

### 2. Driver List Report

**Purpose:** Complete driver roster with details

**Features:**
- Filter by status (Active/Inactive/On Leave)
- License information for each driver
- Expiry status indicators
- Days until license expiry

**Data Included:**
- Employee ID
- Full name
- Phone number
- Status
- License number and type
- License expiry date
- Join date

**API Endpoint:**
```
GET /api/reports/driver-list?status_filter=active
```

**Query Parameters:**
- `status_filter` (optional): Filter by driver status

### 3. License Expiry Report

**Purpose:** Proactive license compliance monitoring

**Categories:**
- **Expired** - Licenses past expiry date (RED)
- **Expiring Soon** - Within 30 days (ORANGE)
- **Valid** - Beyond 30 days (GREEN)

**Features:**
- Sorted by expiry date (soonest first)
- Color-coded status indicators
- Days until expiry countdown
- Alert messages for action required

**Use Cases:**
- Compliance monitoring
- Proactive license renewal
- Avoid operational disruptions
- Regulatory compliance

**API Endpoint:**
```
GET /api/reports/license-expiry?days_ahead=90
```

**Query Parameters:**
- `days_ahead` (default: 90): Look ahead this many days

### 4. Audit Log Report

**Purpose:** Security and compliance auditing

**Features:**
- Date range filtering
- Action type filtering
- User attribution
- Detailed event information

**Common Actions:**
- user_login
- user_logout
- driver_created
- driver_updated
- user_approved
- role_changed

**API Endpoint:**
```
GET /api/reports/audit-log?start_date=2026-01-01&end_date=2026-01-31&limit=100
```

**Query Parameters:**
- `start_date` (optional): Start date (default: 30 days ago)
- `end_date` (optional): End date (default: today)
- `action_filter` (optional): Filter by action type
- `limit` (default: 100, max: 1000): Maximum entries

### 5. User Activity Report

**Purpose:** User engagement and productivity analysis

**Metrics Per User:**
- Total actions in date range
- Recent actions list
- Last login time
- User status and role

**Sorted By:** Most active users first

**Use Cases:**
- User engagement analysis
- Identify inactive users
- Audit user productivity
- License utilization tracking

**API Endpoint:**
```
GET /api/reports/user-activity?start_date=2026-01-01&end_date=2026-01-31
```

**Query Parameters:**
- `start_date` (optional): Start date (default: 30 days ago)
- `end_date` (optional): End date (default: today)

## Access Control

All report endpoints require:
- ✅ JWT authentication
- ✅ Active organization membership

Reports are organization-scoped - users only see data for their organization.

## User Interface

### Reports Dashboard (`/reports`)

Grid layout with report cards:
- Organization Summary (Blue)
- Driver List (Green)
- License Expiry (Orange)
- Audit Log (Purple)
- User Activity (Teal)

Each card shows:
- Report icon
- Title
- Description
- Arrow to navigate

### Report Screens

Common features:
- Refresh button in app bar
- Loading indicators
- Error handling with retry
- Generated timestamp
- Organization name header

#### Organization Summary Screen
- Stats cards grid
- Color-coded metrics
- Recent activity list
- Export button (placeholder)

#### Driver List Screen
- Filter by status dropdown
- Statistics header (Total/Active/Inactive)
- Expandable driver cards
- License expiry badges

#### License Expiry Screen
- Color-coded statistics (Expired/Expiring/Valid)
- Detailed license cards
- Alert messages for urgent renewals
- Days countdown

## Navigation

Access Reports via:
1. Bottom navigation bar → Reports tab
2. Direct URL: `/reports`
3. Individual report URLs:
   - `/reports/organization-summary`
   - `/reports/driver-list`
   - `/reports/license-expiry`
   - `/reports/audit-log`
   - `/reports/user-activity`

## Testing

### Test Organization Summary Report

```bash
curl -X GET "http://localhost:8000/api/reports/organization-summary" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Test Driver List Report

```bash
curl -X GET "http://localhost:8000/api/reports/driver-list?status_filter=active" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Test License Expiry Report

```bash
curl -X GET "http://localhost:8000/api/reports/license-expiry?days_ahead=90" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Future Enhancements

### Short Term
- [ ] Audit log report screen (UI)
- [ ] User activity report screen (UI)
- [ ] Export to PDF
- [ ] Export to CSV/Excel
- [ ] Email report delivery
- [ ] Scheduled reports

### Long Term
- [ ] Trip reports (distance, fuel, revenue)
- [ ] Vehicle reports (maintenance, usage)
- [ ] Financial reports (costs, revenue)
- [ ] Charts and visualizations
- [ ] Custom report builder
- [ ] Report templates
- [ ] Dashboard widgets

## API Documentation

Full interactive API documentation available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

Look for the **"Reports"** tag for all report endpoints.

## Files Structure

### Backend
```
backend/
├── app/
│   ├── api/v1/
│   │   └── reports.py          # API endpoints
│   ├── schemas/
│   │   └── report.py           # Pydantic schemas
│   └── services/
│       └── report_service.py   # Business logic
```

### Frontend
```
frontend/lib/
├── data/services/
│   └── report_api.dart          # API client
├── providers/
│   └── report_provider.dart     # State management
├── presentation/screens/reports/
│   ├── reports_screen.dart                        # Dashboard
│   ├── organization_summary_report_screen.dart    # Summary
│   ├── driver_list_report_screen.dart            # Drivers
│   └── license_expiry_report_screen.dart         # Licenses
└── routes/
    └── app_router.dart          # Routing config
```

## Quick Start

### 1. Restart Backend
```bash
cd backend
python -m uvicorn app.main:app --reload
```

### 2. Restart Frontend
```bash
cd frontend
flutter run -d chrome
```

### 3. Navigate to Reports
1. Login to application
2. Click "Reports" in bottom navigation
3. Select report type from dashboard
4. View generated report

## Troubleshooting

### Report Returns Empty Data
**Solution:** Make sure you have:
- Created an organization
- Added drivers (for driver/license reports)
- Some activity in the system (for audit log)

### 403 Forbidden Error
**Solution:**
- Ensure you're logged in
- Verify you're member of an organization
- Check JWT token is valid

### Report Shows Old Data
**Solution:** Click refresh button in app bar to reload latest data

## Performance Considerations

- Reports are generated in real-time from database
- Large organizations may see slower report generation
- Consider implementing caching for frequently accessed reports
- Audit log reports limited to 1000 entries max per request

## Security

- All reports require authentication
- Organization-scoped data (users can't see other orgs)
- Audit logging tracks who accessed reports
- Sensitive data (like passwords) never included in reports

## Summary

✅ **5 Report Types** - Comprehensive coverage
✅ **Backend API** - RESTful endpoints with filters
✅ **Frontend UI** - Responsive, mobile-friendly screens
✅ **Real-time Data** - Always up-to-date information
✅ **Access Control** - Organization-scoped security
✅ **Easy Navigation** - Intuitive dashboard interface

The reports system provides essential insights for fleet management operations, compliance monitoring, and organizational oversight.
