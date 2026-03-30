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


def _count_stages(user_id, org_id, start, end, db: Session):
    """Count stage submissions for a user in the given time window."""
    s1 = db.query(func.count(Trip.id)).filter(
        Trip.organization_id == org_id,
        Trip.s1_submitted_by == user_id,
        Trip.s1_submitted_at.isnot(None),
        Trip.s1_submitted_at >= start,
        Trip.s1_submitted_at <= end,
    ).scalar() or 0

    s2 = db.query(func.count(Trip.id)).filter(
        Trip.organization_id == org_id,
        Trip.s2_submitted_by == user_id,
        Trip.s2_verified_at.isnot(None),
        Trip.s2_verified_at >= start,
        Trip.s2_verified_at <= end,
    ).scalar() or 0

    s3 = db.query(func.count(Trip.id)).filter(
        Trip.organization_id == org_id,
        Trip.s3_submitted_by == user_id,
        Trip.s3_completed_at.isnot(None),
        Trip.s3_completed_at >= start,
        Trip.s3_completed_at <= end,
    ).scalar() or 0

    s4 = db.query(func.count(Trip.id)).filter(
        Trip.organization_id == org_id,
        Trip.s4_submitted_by == user_id,
        Trip.s4_completed_at.isnot(None),
        Trip.s4_completed_at >= start,
        Trip.s4_completed_at <= end,
    ).scalar() or 0

    return s1, s2, s3, s4


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
            Role.role_key.in_(['logistic_partner', 'logistic_partner_worker']),
            UserOrganization.status == 'active',
        )
        .all()
    )

    leaderboard = []
    for user, role in members:
        s1, s2, s3, s4 = _count_stages(user.id, org_id, start, end, db)
        total = s1 + s2 + s3 + s4
        leaderboard.append({
            "user_id":         str(user.id),
            "full_name":       user.full_name,
            "username":        user.username,
            "role_key":        role.role_key,
            "role_label":      "Owner" if role.role_key == 'logistic_partner' else "Worker",
            "s1_count":        s1,
            "s2_count":        s2,
            "s3_count":        s3,
            "s4_count":        s4,
            "total_stages":    total,
            "trips_completed": s4,   # proxy: a completed trip = stage 4 done
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
            Role.role_key.in_(['logistic_partner', 'logistic_partner_worker']),
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
                "role_label": "Owner" if r.role_key == 'logistic_partner' else "Worker",
            }
            for u, r in members
        ],
    }
