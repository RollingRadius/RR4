from sqlalchemy import or_
from sqlalchemy.dialects import postgresql

from app.api.v1.trips import _like_escape
from app.models.trip import Trip


def test_like_wildcards_are_matched_literally():
    bs = chr(92)
    assert _like_escape("a%b_c" + bs + "d") == "a" + bs + "%b" + bs + "_c" + bs + bs + "d"
    assert _like_escape("rlplwmz4087") == "rlplwmz4087"


def test_trip_search_filters_both_trip_numbers_and_bilty():
    term = f"%{_like_escape('4087')}%"
    sql = str(
        or_(
            Trip.trip_number.ilike(term, escape="\\"),
            Trip.rr_trip_number.ilike(term, escape="\\"),
        ).compile(dialect=postgresql.dialect())
    )
    assert "trips.trip_number ILIKE" in sql and "trips.rr_trip_number ILIKE" in sql
    assert "trips.s4_bilty_number" in str(Trip.s4_bilty_number.ilike("%1%", escape="\\"))
