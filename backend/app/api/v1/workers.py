"""
Workers API
Leaderboard and performance tracking for LP workers — accessible by logistic_partner owners.
"""

import calendar
from datetime import datetime, date, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.role import Role
from app.models.user_organization import UserOrganization
from app.models.trip import Trip

router = APIRouter()


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _verify_lp_owner(current_user: User, db: Session) -> UserOrganization:
    """Only logistic_partner owners can access the workers leaderboard."""
    user_org = db.query(UserOrganization).join(
        Role, UserOrganization.role_id == Role.id
    ).filter(
        UserOrganization.user_id == current_user.id,
        Role.role_key == 'logistic_partner',
        UserOrganization.status == 'active',
    ).first()
    if not user_org:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only logistic partner owners can access worker stats",
        )
    return user_org


def _date_range(period: str, date_str: Optional[str]):
    """Return (start, end) datetime range in UTC for the requested period."""
    tz = timezone.utc
    now = datetime.now(tz)

    if period == 'daily':
        d = date.fromisoformat(date_str) if date_str else now.date()
        start = datetime(d.year, d.month, d.day, 0, 0, 0, tzinfo=tz)
        end   = datetime(d.year, d.month, d.day, 23, 59, 59, 999999, tzinfo=tz)
        label = d.strftime('%B %d, %Y')
    else:  # monthly
        if date_str:
            parts = date_str.split('-')
            year, month = int(parts[0]), int(parts[1])
        else:
            year, month = now.year, now.month
        last_day = calendar.monthrange(year, month)[1]
        start = datetime(year, month, 1, 0, 0, 0, tzinfo=tz)
        end   = datetime(year, month, last_day, 23, 59, 59, 999999, tzinfo=tz)
        label = datetime(year, month, 1).strftime('%B %Y')

    return start, end, label


def _count_points(user_id, org_id, start, end, db: Session):
    """
    Count individual item completions (1 pt per checkbox/field/upload) for a worker.

    Stage 1  — 4 text fields + 9 document uploads          (max 13 pts)
    Stage 2  — 4 checkboxes + loading slip upload           (max  5 pts)
    Stage 3  — 6 checkboxes + 2 weight fields + bilty
               + material docs                              (max 10 pts)
    Stage 4  — 5 checkboxes                                 (max  5 pts)
    ─────────────────────────────────────────────────────────────────────
    Max per trip: 33 pts
    """

    # ── Stage 1 ──────────────────────────────────────────────────────────────────
    s1_trips = db.query(Trip).filter(
        Trip.organization_id == org_id,
        Trip.s1_submitted_by == user_id,
        Trip.s1_submitted_at.isnot(None),
        Trip.s1_submitted_at >= start,
        Trip.s1_submitted_at <= end,
    ).all()

    s1 = 0
    for t in s1_trips:
        # Text fields
        for v in [t.s1_driver_name, t.s1_driver_phone, t.s1_driving_license, t.s1_aadhaar]:
            if v:
                s1 += 1
        # Document uploads
        for v in [t.s1_driving_license_url, t.s1_aadhaar_url, t.s1_rc,
                  t.s1_insurance, t.s1_pollution, t.s1_fitness,
                  t.s1_pan, t.s1_tax_declaration, t.s1_cancelled_cheque]:
            if v:
                s1 += 1

    # ── Stage 2 ──────────────────────────────────────────────────────────────────
    s2_trips = db.query(Trip).filter(
        Trip.organization_id == org_id,
        Trip.s2_submitted_by == user_id,
        Trip.s2_verified_at.isnot(None),
        Trip.s2_verified_at >= start,
        Trip.s2_verified_at <= end,
    ).all()

    s2 = 0
    for t in s2_trips:
        # Checkboxes
        for v in [t.s2_specs_verified, t.s2_docs_verified,
                  t.s2_driver_docs_valid, t.s2_entry_permission]:
            if v:
                s2 += 1
        # Loading slip upload
        if t.s2_loading_slip_url:
            s2 += 1

    # ── Stage 3 ──────────────────────────────────────────────────────────────────
    s3_trips = db.query(Trip).filter(
        Trip.organization_id == org_id,
        Trip.s3_submitted_by == user_id,
        Trip.s3_completed_at.isnot(None),
        Trip.s3_completed_at >= start,
        Trip.s3_completed_at <= end,
    ).all()

    s3 = 0
    for t in s3_trips:
        # Checkboxes
        for v in [t.s3_driver_parked, t.s3_docs_submitted, t.s3_security_verified,
                  t.s3_driver_exited_cabin, t.s3_wheel_stoppers, t.s3_safety_gear]:
            if v:
                s3 += 1
        # Weight entries
        for v in [t.s3_empty_truck_weight_kg, t.s3_loaded_truck_weight_kg]:
            if v:
                s3 += 1
        # Document uploads
        if t.s3_eway_bill_url:
            s3 += 1
        if t.s3_material_doc_urls:
            s3 += 1

    # ── Stage 4 ──────────────────────────────────────────────────────────────────
    s4_trips = db.query(Trip).filter(
        Trip.organization_id == org_id,
        Trip.s4_submitted_by == user_id,
        Trip.s4_completed_at.isnot(None),
        Trip.s4_completed_at >= start,
        Trip.s4_completed_at <= end,
    ).all()

    s4 = 0
    for t in s4_trips:
        for v in [t.s4_truck_moved, t.s4_security_verified,
                  t.s4_bilty_checked, t.s4_weight_checked, t.s4_material_checked]:
            if v:
                s4 += 1

    # ── Trips completed (separate from points — actual trip count) ────────────────
    trips_completed = db.query(func.count(Trip.id)).filter(
        Trip.organization_id == org_id,
        Trip.s4_submitted_by == user_id,
        Trip.s4_completed_at.isnot(None),
        Trip.s4_completed_at >= start,
        Trip.s4_completed_at <= end,
    ).scalar() or 0

    return s1, s2, s3, s4, trips_completed


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/workers/leaderboard")
def get_leaderboard(
    period: str = Query("daily", pattern="^(daily|monthly)$"),
    date: Optional[str] = Query(None, description="YYYY-MM-DD for daily, YYYY-MM for monthly"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Worker performance leaderboard for the logistic partner's organisation.
    Ranks all LP workers (+ the owner) by number of stages submitted in the period.
    Only the logistic_partner owner can call this.
    """
    owner_org = _verify_lp_owner(current_user, db)
    org_id = owner_org.organization_id

    try:
        start, end, label = _date_range(period, date)
    except (ValueError, IndexError):
        raise HTTPException(status_code=400, detail="Invalid date format")

    # Fetch all active members of this org (owner + workers)
    members = (
        db.query(User, Role)
        .join(UserOrganization, User.id == UserOrganization.user_id)
        .join(Role, UserOrganization.role_id == Role.id)
        .filter(
            UserOrganization.organization_id == org_id,
            Role.role_key.in_(['logistic_partner', 'logistic_partner_worker', 'lp_rr_operations']),
            UserOrganization.status == 'active',
        )
        .all()
    )

    leaderboard = []
    for user, role in members:
        s1, s2, s3, s4, trips_completed = _count_points(user.id, org_id, start, end, db)
        total = s1 + s2 + s3 + s4
        leaderboard.append({
            "user_id":         str(user.id),
            "full_name":       user.full_name,
            "username":        user.username,
            "phone":           user.phone,
            "role_key":        role.role_key,
            "role_label":      "Owner" if role.role_key == 'logistic_partner' else ("RR Ops" if role.role_key == 'lp_rr_operations' else "Worker"),
            "s1_count":        s1,
            "s2_count":        s2,
            "s3_count":        s3,
            "s4_count":        s4,
            "total_stages":    total,
            "trips_completed": trips_completed,
        })

    # Sort: total stages desc → trips_completed desc → name asc
    leaderboard.sort(key=lambda x: (-x["total_stages"], -x["trips_completed"], x["full_name"]))

    # Assign ranks (shared rank for ties)
    rank = 1
    for i, entry in enumerate(leaderboard):
        if i > 0:
            prev = leaderboard[i - 1]
            if entry["total_stages"] != prev["total_stages"] or entry["trips_completed"] != prev["trips_completed"]:
                rank = i + 1
        entry["rank"] = rank

    return {
        "success":    True,
        "period":     period,
        "date_label": label,
        "count":      len(leaderboard),
        "leaderboard": leaderboard,
    }


@router.get("/workers/records")
def get_records(
    date: Optional[str] = Query(None, description="YYYY-MM-DD (defaults to today)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Chronological log of every stage submission made by any org member on a given day.
    Only the logistic_partner owner can call this.
    """
    owner_org = _verify_lp_owner(current_user, db)
    org_id = owner_org.organization_id

    try:
        start, end, label = _date_range('daily', date)
    except (ValueError, IndexError):
        raise HTTPException(status_code=400, detail="Invalid date format")

    # Build a user-id → name map for org members
    members = (
        db.query(User)
        .join(UserOrganization, User.id == UserOrganization.user_id)
        .join(Role, UserOrganization.role_id == Role.id)
        .filter(
            UserOrganization.organization_id == org_id,
            Role.role_key.in_(['logistic_partner', 'logistic_partner_worker', 'lp_rr_operations']),
            UserOrganization.status == 'active',
        )
        .all()
    )
    user_map = {str(u.id): u.full_name for u in members}

    # Fetch all trips in org
    trips = db.query(Trip).filter(Trip.organization_id == org_id).all()

    _STAGE_LABELS = {1: 'Truck Details', 2: 'Compliance Check', 3: 'Truck Arrival', 4: 'Truck Exit'}

    records = []
    for trip in trips:
        submissions = [
            (1, trip.s1_submitted_by, trip.s1_submitted_at),
            (2, trip.s2_submitted_by, trip.s2_verified_at),
            (3, trip.s3_submitted_by, trip.s3_completed_at),
            (4, trip.s4_submitted_by, trip.s4_completed_at),
        ]
        for stage_num, submitted_by, submitted_at in submissions:
            if not submitted_by or not submitted_at:
                continue
            if not (start <= submitted_at.replace(tzinfo=submitted_at.tzinfo or timezone.utc) <= end):
                continue
            records.append({
                "trip_number":  trip.trip_number,
                "trip_id":      str(trip.id),
                "origin":       trip.origin,
                "destination":  trip.destination,
                "stage":        stage_num,
                "stage_label":  _STAGE_LABELS[stage_num],
                "worker_id":    str(submitted_by),
                "worker_name":  user_map.get(str(submitted_by), 'Unknown'),
                "submitted_at": submitted_at.isoformat(),
            })

    # Sort chronologically (latest first)
    records.sort(key=lambda r: r["submitted_at"], reverse=True)

    return {
        "success":    True,
        "date_label": label,
        "count":      len(records),
        "records":    records,
    }


@router.get("/workers")
def list_workers(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all active workers in the LP owner's organisation."""
    owner_org = _verify_lp_owner(current_user, db)
    org_id = owner_org.organization_id

    members = (
        db.query(User, Role)
        .join(UserOrganization, User.id == UserOrganization.user_id)
        .join(Role, UserOrganization.role_id == Role.id)
        .filter(
            UserOrganization.organization_id == org_id,
            Role.role_key.in_(['logistic_partner', 'logistic_partner_worker', 'lp_rr_operations']),
            UserOrganization.status == 'active',
        )
        .order_by(User.full_name)
        .all()
    )

    return {
        "success": True,
        "count":   len(members),
        "workers": [
            {
                "user_id":    str(u.id),
                "full_name":  u.full_name,
                "username":   u.username,
                "phone":      u.phone,
                "role_key":   r.role_key,
                "role_label": "Owner" if r.role_key == 'logistic_partner' else ("RR Ops" if r.role_key == 'lp_rr_operations' else "Worker"),
            }
            for u, r in members
        ],
    }
