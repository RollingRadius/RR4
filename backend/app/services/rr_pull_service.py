"""Pull what RR web changed on our trips' papers and stage fields / uploads (md/RR_TWO_WAY_SYNC_PLAN.md section 10,
user 2026-11-24). Our side -> RR stays the send-only-what-changed sync; this is the RR -> our side half.

Only what our app has is compared (RR-only fields are never read). Per field:
- same on both sides                                         -> nothing;
- our user changed it and it is not sent yet (rr_change_marks) -> ours wins (the sync sends it);
- ours is filled but its stage never synced                  -> ours wins (not sent yet);
- RR has nothing                                             -> nothing (RR web does not wipe our data);
- otherwise RR web changed it                                -> copied into our trip, never sent back.
Photos: RR keeps a photo as a file record; RR web replaces a photo IN PLACE (same id, new bytes - F15), so a photo is
seen by "file id @ file etag" (kept per trip in trips.rr_synced_doc_urls[_RR_SEEN]); a photo is downloaded only
when that changed, and stored with the app's own storage code (Stage 1 under its driver / truck / owner, Stages 2-5
under the trip), marked as already in RR (rr_file_id) so it is never sent back, with author "RR web".
Each trip with pulls gets one trip_booking_events row "rr_web_updated" (the fields in `reason`) and
trips.rr_web_changed_at. RR reads are batched (about 7 calls per 50 trips). Never raises.
"""
import json
import logging
import mimetypes
import uuid
from datetime import date, datetime, timezone
from decimal import Decimal, InvalidOperation
from pathlib import Path
from email.utils import parsedate_to_datetime
from types import SimpleNamespace

from app.config import settings
from app.core.document_map import UPLOAD_COLUMNS
from app.models import trip_booking_event as ev
from app.models.document import DriverDocument, OwnerDocument, TripDocument, VehicleDocument
# modules, not names: rr_sync_service imports this module back (through rr_follow_service), and tests patch them
from app.services import rr_change_marks, rr_sync_service, stage1_document_service, trip_document_service
from app.services.upload_storage import describe_upload

logger = logging.getLogger(__name__)

RR_SEEN_KEY = "_rr_seen"
RR_WEB_ACTOR = SimpleNamespace(id=None, username="RR web")
RR_WEB_ROLE = "rr_web"
BATCH = 50

# ── what is compared: our trip column -> where RR keeps it ─────────────────────
# numbers / dates / values: (column, stage, source, getter, kind, label)
# source: driver | vehicle | owner | parcel ; kind: text | digits | nospace | upper | date | datetime | float
def _ident(name, field="number"):
    def get(rec):
        for i in (rec or {}).get("identities") or []:
            if i.get("id_name") == name:
                return i.get(field)
        return None
    return get


def _path(*keys):
    def get(rec):
        cur = rec
        for k in keys:
            if not isinstance(cur, dict):
                return None
            cur = cur.get(k)
        return cur
    return get


VALUES = (
    ("s1_driving_license", 1, "driver", _ident("Driving Licence"), "nospace", "Driving licence number"),
    ("s1_aadhaar", 1, "driver", _ident("Aadhaar Card"), "digits", "Aadhaar number"),
    ("s1_rc_number", 1, "vehicle", _ident("Registration Certificate"), "nospace", "RC number"),
    ("s1_puc_number", 1, "vehicle", _ident("PUC Certificate"), "upper", "PUC number"),
    ("s1_fitness_number", 1, "vehicle", _ident("Fitness Certificate"), "upper", "Fitness number"),
    ("s1_permit_number", 1, "vehicle", _ident("Permit"), "upper", "Permit number"),
    ("s1_insurance_number", 1, "vehicle", _path("insurance", "policy_number"), "upper", "Insurance policy number"),
    ("s1_pan_number", 1, "owner", _ident("PAN"), "upper", "Owner PAN number"),
    ("s1_tax_declaration_expiry", 1, "owner", _ident("Tax Declaration Slip", "expiry_date"), "datetime",
     "Tax declaration valid till"),
    ("s3_eway_bill_number", 3, "parcel", _path("documents", "eway_bill", "number"), "upper", "E-way bill number"),
    ("s3_eway_bill_issue_date", 3, "parcel", _path("documents", "eway_bill", "issue_date"), "datetime",
     "E-way bill issue date"),
    ("s3_eway_bill_expiry_date", 3, "parcel", _path("documents", "eway_bill", "expiry_date"), "datetime",
     "E-way bill expiry date"),
    ("s3_invoice_number", 3, "parcel", _path("documents", "consignor_invoice", "number"), "upper", "Invoice number"),
    ("s3_vehicle_reach_datetime", 3, "parcel", _path("loading", "truck_reach_datetime"), "datetime",
     "Loading reach time"),
    ("s3_loading_start_datetime", 3, "parcel", _path("loading", "start_datetime"), "datetime", "Loading start time"),
    ("s4_vehicle_exit_datetime", 4, "parcel", _path("loading", "end_datetime"), "datetime", "Exit time"),
    ("s4_bilty_number", 4, "parcel", _path("documents", "bilty"), "upper", "Bilty number"),
    ("s4_bilty_date", 4, "parcel", _path("documents", "bilty_date"), "datetime", "Bilty date"),
    ("s5_vehicle_reach_datetime", 5, "parcel", _path("unloading", "truck_reach_datetime"), "datetime",
     "Unloading reach time"),
    ("s5_unloading_start_datetime", 5, "parcel", _path("unloading", "start_datetime"), "datetime",
     "Unloading start time"),
    ("s5_unloading_end_datetime", 5, "parcel", _path("unloading", "end_datetime"), "datetime", "Unloading end time"),
    ("s5_halting_charge", 5, "parcel", _path("unloading", "halting_charge"), "float", "Halting charge"),
)


def _photo_ident(name, side):
    def get(rec):
        for i in (rec or {}).get("identities") or []:
            if i.get("id_name") == name:
                photos = [p for p in i.get("photos") or [] if p.get("photo") or p.get("manual_photo")]
                for p in photos:
                    if (p.get("side") or "Front").lower() == side:
                        return str(p.get("photo") or p.get("manual_photo"))
                if side == "front" and photos and not photos[0].get("side"):
                    return str(photos[0].get("photo") or photos[0].get("manual_photo"))
        return None
    return get


def _first_photo(*keys):
    def get(rec):
        cur = _path(*keys)(rec)
        for p in (cur or []) if isinstance(cur, list) else []:
            fid = p.get("photo") or p.get("manual_photo")
            if fid:
                return str(fid)
        return None
    return get


def _trip_doc(name):
    def get(rec):
        for d in (rec or {}).get("trip_documents") or []:
            if d.get("document") == name:
                return _first_photo("photos")(d)
        return None
    return get


# photos: (column, stage, source, getter, file prefix, label); source adds trip | bank
PHOTOS = (
    ("s1_driving_license_url", 1, "driver", _photo_ident("Driving Licence", "front"), "dl", "Driving licence photo"),
    ("s1_driving_license_back_url", 1, "driver", _photo_ident("Driving Licence", "back"), "dl_back",
     "Driving licence back photo"),
    ("s1_aadhaar_url", 1, "driver", _photo_ident("Aadhaar Card", "front"), "aadhaar", "Aadhaar photo"),
    ("s1_aadhaar_back_url", 1, "driver", _photo_ident("Aadhaar Card", "back"), "aadhaar_back", "Aadhaar back photo"),
    ("s1_rc", 1, "vehicle", _photo_ident("Registration Certificate", "front"), "rc", "RC photo"),
    ("s1_rc_back", 1, "vehicle", _photo_ident("Registration Certificate", "back"), "rc_back", "RC back photo"),
    ("s1_pollution", 1, "vehicle", _photo_ident("PUC Certificate", "front"), "pollution", "PUC photo"),
    ("s1_fitness", 1, "vehicle", _photo_ident("Fitness Certificate", "front"), "fitness", "Fitness photo"),
    ("s1_permit", 1, "vehicle", _photo_ident("Permit", "front"), "permit", "Permit photo"),
    ("s1_insurance", 1, "vehicle", _first_photo("insurance", "photos"), "insurance", "Insurance photo"),
    ("s1_pan", 1, "owner", _photo_ident("PAN", "front"), "pan", "Owner PAN photo"),
    ("s1_tax_declaration", 1, "owner", _photo_ident("Tax Declaration Slip", "front"), "tax_decl",
     "Tax declaration photo"),
    ("s1_cancelled_cheque", 1, "bank", lambda rec: str(rec["account_identity"]) if (rec or {}).get("account_identity")
     else None, "cheque", "Owner cheque photo"),
    ("s2_loading_slip_url", 2, "trip", _trip_doc("Loading Slip"), "loading_slip", "Loading slip"),
    ("s3_loaded_weight_slip_url", 3, "parcel", _first_photo("documents", "weight_receipt", "photos"), "weight_slip",
     "Weight slip"),
    ("s3_eway_bill_url", 3, "parcel", _first_photo("documents", "eway_bill", "photos"), "eway", "E-way bill photo"),
    ("s4_diesel_receipt_url", 4, "trip", _trip_doc("Fuel Slip"), "diesel", "Fuel slip"),
    ("s4_bilty_url", 4, "parcel", _first_photo("documents", "manual_bilty", "photos"), "bilty", "Bilty photo"),
    ("s5_pod_url", 5, "parcel", _first_photo("documents", "pod", "photos"), "pod", "POD"),
)
LABELS = {c: lab for c, *_x, lab in VALUES} | {c: lab for c, *_x, lab in PHOTOS} | {
    "s3_loaded_truck_weight_kg": "Kanta weight", "s3_actual_invoice_value": "Invoice value",
    "s3_material_doc_urls": "Invoice / material photos"}


# ── normalising for comparison ──────────────────────────────────────────────────

def _parse_dt(v):
    if v is None or v == "":
        return None
    if isinstance(v, datetime):
        return v.astimezone(timezone.utc).replace(tzinfo=None) if v.tzinfo else v
    try:
        d = datetime.fromisoformat(str(v).replace("Z", "+00:00"))
    except ValueError:
        try:
            d = parsedate_to_datetime(str(v))
        except Exception:
            return None
    return d.astimezone(timezone.utc).replace(tzinfo=None) if d.tzinfo else d


def norm(value, kind):
    if value is None or value == "":
        return None
    if kind == "datetime":
        d = _parse_dt(value)
        return d.replace(microsecond=0) if d else None
    if kind == "date":
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, date):
            return value
        try:
            return date.fromisoformat(str(value)[:10])
        except ValueError:
            return None
    if kind == "float":
        try:
            return round(float(value), 2)
        except (TypeError, ValueError, InvalidOperation):
            return None
    s = str(value).strip()
    if kind == "digits":
        return "".join(ch for ch in s if ch.isdigit()) or None
    if kind == "nospace":
        return s.replace(" ", "").upper() or None
    return s.upper() or None


def _to_column(column, value, kind):
    """RR's value in the type our column keeps."""
    if kind == "datetime":
        d = _parse_dt(value)
        return d.replace(tzinfo=timezone.utc) if d else None
    if kind == "date":
        return norm(value, "date")
    if kind == "float":
        return Decimal(str(round(float(value), 2)))
    if kind == "digits":
        return norm(value, "digits")
    if column in ("s1_driving_license", "s1_rc_number"):
        return norm(value, "nospace")
    return str(value).strip().upper()[:100]


# ── decision (pure) ─────────────────────────────────────────────────────────────

def stage_synced(trip, stage: int) -> bool:
    return getattr(trip, f"rr_s{stage}_sync_status", None) == "synced"


def may_take_rr(trip, column: str, stage: int, ours_filled: bool) -> bool:
    """RR's differing value may replace ours: ours not changed-and-unsent, and not filled-but-never-sent."""
    if column in rr_change_marks.changed_columns(trip):
        return False
    # Stage 1 counts per part (driver / truck / insurance / owner / cheque): a part RR accepted is "synced" even when
    # another part of Stage 1 failed (fc11, 2026-11-25).
    synced = (rr_change_marks.s1_part_synced(trip, rr_change_marks.s1_part_of(column)) if stage == 1
              else stage_synced(trip, stage))
    if ours_filled and not synced:
        return False
    return True


def value_to_pull(trip, column, stage, rr_raw, kind):
    """(take?, new column value). Pure."""
    rr = norm(rr_raw, kind)
    if rr is None:
        return False, None
    ours = norm(getattr(trip, column, None), kind)
    if ours == rr:
        return False, None
    if not may_take_rr(trip, column, stage, ours is not None):
        return False, None
    return True, _to_column(column, rr_raw, kind)


def weight_to_pull(trip, kanta: dict | None):
    """(take?, kg string, unit) for RR's actual_kanta_weight. Pure."""
    if not kanta or kanta.get("weight") in (None, ""):
        return False, None, None
    unit = "tons" if str(kanta.get("weight_unit") or "").upper().startswith("TONNE") else "kg"
    rr_w = round(float(kanta["weight"]), 3)
    try:
        ours_w = round(float(trip.s3_loaded_truck_weight_kg), 3) if trip.s3_loaded_truck_weight_kg else None
    except (TypeError, ValueError):
        ours_w = None
    ours_u = (trip.s3_loaded_truck_weight_unit or "kg").lower()
    if ours_w == rr_w and ours_u == unit:
        return False, None, None
    pending = {"s3_loaded_truck_weight_kg", "s3_loaded_truck_weight_unit"} & rr_change_marks.changed_columns(trip)
    if pending or (ours_w is not None and not stage_synced(trip, 3)):
        return False, None, None
    text = str(int(rr_w)) if rr_w == int(rr_w) else str(rr_w)
    return True, text, unit


def photo_action(trip, column, stage, rr_file_id, rr_etag, stored_rr_file_id):
    """'skip' | 'baseline' (RR shows the file we have - just remember it) | 'check' (download and compare). Pure."""
    if not rr_file_id:
        return "skip"
    seen = ((trip.rr_synced_doc_urls or {}).get(RR_SEEN_KEY) or {}).get(column)
    ref = f"{rr_file_id}@{rr_etag or ''}"
    if seen == ref:
        return "skip"
    seen_id = seen.split("@")[0] if seen else None
    if stored_rr_file_id == rr_file_id and seen_id != rr_file_id:
        return "baseline"                 # first look, or the file we just sent: RR holds exactly ours
    if not may_take_rr(trip, column, stage, bool(getattr(trip, column, None))):
        return "skip"
    return "check"


def remember_seen(trip, column, rr_file_id, rr_etag):
    marks = dict(trip.rr_synced_doc_urls or {})
    seen = dict(marks.get(RR_SEEN_KEY) or {})
    seen[column] = f"{rr_file_id}@{rr_etag or ''}"
    marks[RR_SEEN_KEY] = seen
    trip.rr_synced_doc_urls = marks


# ── RR reads (batched) ──────────────────────────────────────────────────────────

def _hdr(token):
    return {"Authorization": f"Bearer {token}"}


async def _get_many(client, token, resource, where, projection, n):
    resp = await client.get(f"{settings.RR_API_BASE}/{resource}", headers=_hdr(token), params={
        "where": json.dumps(where), "projection": json.dumps(projection), "max_results": max(n, 1)})
    if resp.status_code != 200:
        raise RuntimeError(f"RR {resource} HTTP {resp.status_code}")
    return resp.json().get("_items", [])


async def read_rr_records(client, token, trips) -> dict:
    """{trip.id: {"parcel", "trip", "driver", "vehicle", "owner", "bank"}} plus "_etags": {file id: etag}."""
    out, ids = {}, lambda attr: list(dict.fromkeys(getattr(t, attr) for t in trips if getattr(t, attr, None)))
    parcels, rtrips, drivers, vehicles, owners = (ids("rr_parcel_id"), ids("rr_trip_id"), ids("rr_driver_id"),
                                                  ids("rr_vehicle_id"), ids("transporter_rr_company_id"))
    by = {}

    async def read(kind, resource, ids_, where_key, projection, extra=None, per=1):
        """One source; a refused / failed read only skips that source (nothing of it is pulled)."""
        for start in range(0, len(ids_), BATCH):
            chunk = ids_[start:start + BATCH]
            try:
                rows = await _get_many(client, token, resource, {where_key: {"$in": chunk}, **(extra or {})},
                                       projection, len(chunk) * per)
            except Exception as exc:
                logger.info(f"[RR Pull] {resource} not readable ({exc}) - skipped")
                return False
            for r in rows:
                by[(kind, str(r.get("_id") if where_key == "_id" else r.get(where_key)))] = r
        return True

    await read("parcel", "parcels", parcels, "_id", {"documents": 1, "actual_kanta_weight": 1, "loading": 1,
                                                     "unloading": 1, "cost": 1})
    await read("trip", "trips", rtrips, "_id", {"trip_documents": 1})
    if not await read("driver", "users", drivers, "_id", {"identities": 1}):
        for d in drivers:                     # LP / RR-ops logins may not list users: RR's own per-user read
            try:
                resp = await client.get(f"{settings.RR_API_BASE}/get_user_record_by_id", headers=_hdr(token),
                                        params={"record_id": d})
                if resp.status_code == 200:
                    by[("driver", d)] = resp.json()
            except Exception:
                pass
    await read("vehicle", "vehicles", vehicles, "_id", {"identities": 1, "insurance": 1})
    await read("owner", "companies", owners, "_id", {"identities": 1})
    await read("bank", "banking_details", owners, "created_by_company", {"created_by_company": 1,
                                                                         "account_identity": 1},
               extra={"primary": True}, per=2)
    for t in trips:
        out[t.id] = {"parcel": by.get(("parcel", str(t.rr_parcel_id))), "trip": by.get(("trip", str(t.rr_trip_id))),
                     "driver": by.get(("driver", str(t.rr_driver_id))),
                     "vehicle": by.get(("vehicle", str(t.rr_vehicle_id))),
                     "owner": by.get(("owner", str(t.transporter_rr_company_id))),
                     "bank": by.get(("bank", str(t.transporter_rr_company_id)))}
    file_ids = list(dict.fromkeys([fid for t in trips for (col, _s, src, get, _p, _l) in PHOTOS
                                   if (fid := get(out[t.id].get(src)))]
                                  + [fid for t in trips for fid in material_ids(out[t.id].get("parcel") or {})]))
    etags = {}
    for start in range(0, len(file_ids), BATCH):
        try:
            for r in await _get_many(client, token, "files", {"_id": {"$in": file_ids[start:start + BATCH]}},
                                     {"_etag": 1}, BATCH):
                etags[str(r["_id"])] = r.get("_etag")
        except Exception as exc:
            logger.info(f"[RR Pull] file records not readable ({exc}) - photos compared by id only")
    out["_etags"] = etags
    return out


# ── applying ────────────────────────────────────────────────────────────────────

def _stored_row(db, url):
    """The stored document behind a trip column's URL (any document table), or None."""
    if not url:
        return None
    for model in (DriverDocument, VehicleDocument, OwnerDocument, TripDocument):
        row = db.query(model).filter(model.url_path == url).first()
        if row is not None:
            return row
    return None


async def _store_photo(db, trip, column, stage, prefix, file_id, client, token) -> bool:
    """Download RR's file and store it as this trip column's document. False when it could not be read or it is the
    same bytes we hold."""
    got = await rr_sync_service._download_rr_file(file_id, client, token)
    if got is None:
        return False
    content, content_type, file_name = got
    upload = describe_upload(content, file_name, content_type)
    row = _stored_row(db, getattr(trip, column, None))
    if row is not None and row.sha256 == upload.sha256:
        return False
    ext = Path(file_name or "").suffix or mimetypes.guess_extension(content_type or "") or ".jpg"
    url = f"/uploads/trips/{trip.id}/{prefix}_{uuid.uuid4().hex}{ext}"
    kw = dict(url_path=url, file_name=Path(url).name, upload=upload, user=RR_WEB_ACTOR, role_key=RR_WEB_ROLE,
              org_id=trip.organization_id, uploaded_via="rr_web", rr_file_id=file_id)
    if stage == 1:
        # Set before saving: when the owner's stored paper is this same file, save_stage1_document points the trip
        # at THAT row's link instead - setting it after (as before) left the trip on a link stored nowhere (broken
        # photo; found in the e2e run 2026-11-25 after a reassign to a driver whose papers we already held).
        setattr(trip, column, url)
        stage1_document_service.save_stage1_document(db, trip=trip, column=column, **kw)
        _mark_in_rr(trip, column, getattr(trip, column), file_id)
    elif column == "s2_loading_slip_url":
        trip_document_service.save_loading_slip(db, trip=trip, doc_type="loading_slip", **kw)
        trip.rr_loading_slip_file_id = file_id
    else:
        col = next(c for c in UPLOAD_COLUMNS if c.column == column)
        trip_document_service.save_trip_document(db, trip_id=trip.id, doc_type=col.doc_type, stage=stage, **kw)
        setattr(trip, column, url)
    db.flush()
    return True


def material_ids(parcel: dict) -> list[str]:
    """RR's consignor invoice photos (our Stage 3 material documents), in order."""
    out = []
    for p in ((parcel.get("documents") or {}).get("consignor_invoice") or {}).get("photos") or []:
        fid = p.get("photo") or p.get("manual_photo")
        if fid:
            out.append(str(fid))
    return out


class _ColumnNames:
    """Stands in for a trip so the sync's paper lists give back column names (trip.s1_rc -> "s1_rc")."""
    def __getattr__(self, name):
        return name


def stage1_sync_mark(column: str):
    """(the sync's "already sent" key, the trip's RR file-id attribute or None) of a Stage 1 photo column, or None."""
    names = _ColumnNames()
    for it in rr_sync_service.driver_doc_items(names) + rr_sync_service.vehicle_doc_items(names):
        for side in ("front", "back"):
            if it.get(f"{side}_url") == column:
                return f"{it['id_name']}::{side}", it.get(f"{side}_attr")
    if column == "s1_insurance":
        return "Insurance::front", "rr_insurance_file_id"
    return stage1_document_service.OWNER_SYNC_MARKS.get(column)


def _mark_in_rr(trip, column: str, url: str, file_id: str) -> None:
    """A Stage 1 photo taken from RR is what RR holds: mark it as already sent (the sync does not upload it back as a
    new copy) and keep its RR file id (the RR document status shows it as synced) - as for collected owner papers.
    Found in the e2e run 2026-11-24: after a reassign the new driver's pulled papers showed 'not synced'."""
    mark = stage1_sync_mark(column)
    if not mark:
        return
    key, attr = mark
    marks = dict(trip.rr_synced_doc_urls or {})
    marks[key] = url
    trip.rr_synced_doc_urls = marks
    if attr:
        setattr(trip, attr, file_id)


async def _pull_material_docs(db, trip, parcel: dict, etags: dict, client, token) -> bool:
    """The Stage 3 material documents as a list (same rules as one photo, on the whole list). True when replaced."""
    column = "s3_material_doc_urls"
    ids = material_ids(parcel)
    if not ids:
        return False
    ref = ",".join(f"{i}@{etags.get(i) or ''}" for i in ids)
    seen = ((trip.rr_synced_doc_urls or {}).get(RR_SEEN_KEY) or {}).get(column)
    if seen == ref:
        return False
    try:
        ours = json.loads(trip.s3_material_doc_urls) if isinstance(trip.s3_material_doc_urls, str) else (trip.s3_material_doc_urls or [])
    except ValueError:
        ours = []
    rows = [_stored_row(db, u) for u in ours]
    ours_rr_ids = [getattr(r, "rr_file_id", None) for r in rows]
    marks = dict(trip.rr_synced_doc_urls or {})
    if ours and ours_rr_ids == ids and (not seen or seen.split("@")[0].split(",")[0] != ids[0]):
        marks.setdefault(RR_SEEN_KEY, {})[column] = ref       # RR holds exactly what we sent: remember only
        trip.rr_synced_doc_urls = marks
        return False
    if not may_take_rr(trip, column, 3, bool(ours)):
        return False
    items = []
    for fid in ids:
        got = await rr_sync_service._download_rr_file(fid, client, token)
        if got is None:
            return False                                     # all or nothing: keep ours when one cannot be read
        content, content_type, file_name = got
        ext = Path(file_name or "").suffix or mimetypes.guess_extension(content_type or "") or ".jpg"
        url = f"/uploads/trips/{trip.id}/material_{uuid.uuid4().hex}{ext}"
        items.append((url, Path(url).name, describe_upload(content, file_name, content_type), fid))
    if [r.sha256 if r else None for r in rows] == [u.sha256 for _, _, u, _ in items]:
        marks.setdefault(RR_SEEN_KEY, {})[column] = ref
        trip.rr_synced_doc_urls = marks
        return False
    stored = trip_document_service.save_trip_document_list(db, trip_id=trip.id, doc_type="material_doc", stage=3,
                                     items=[(u, n, up) for u, n, up, _ in items], user=RR_WEB_ACTOR,
                                     role_key=RR_WEB_ROLE, org_id=trip.organization_id)
    for row, (_u, _n, up, fid) in zip(stored or [], items):
        row.uploaded_via, row.rr_file_id, row.rr_synced_sha256 = "rr_web", fid, up.sha256
    trip.s3_material_doc_urls = json.dumps([u for u, _, _, _ in items])
    marks = dict(trip.rr_synced_doc_urls or {})
    marks.setdefault(RR_SEEN_KEY, {})[column] = ref
    trip.rr_synced_doc_urls = marks
    db.flush()
    return True


async def pull_trip(db, trip, records: dict, etags: dict, client, token) -> list[str]:
    """Copy RR web's changes into this trip (see module doc). Returns the columns pulled; the caller commits."""
    pulled = []
    has_booking = bool(trip.rr_vehicle_id) and trip.booking_status != "booking_cancelled"
    for column, stage, source, get, kind, _label in VALUES:
        if stage == 1 and not has_booking:
            continue
        take, value = value_to_pull(trip, column, stage, get(records.get(source)), kind)
        if take:
            setattr(trip, column, value)
            pulled.append(column)
    take, kg, unit = weight_to_pull(trip, (records.get("parcel") or {}).get("actual_kanta_weight"))
    if take:
        trip.s3_loaded_truck_weight_kg, trip.s3_loaded_truck_weight_unit = kg, unit
        pulled.append("s3_loaded_truck_weight_kg")
    # Actual invoice value = RR's parcels.cost. RR's cost starts as the placeholder sent at trip creation, so it is
    # taken only when ours is filled and Stage 3 synced (an RR web correction of the real value), never into an empty one.
    cost = (records.get("parcel") or {}).get("cost")
    if trip.s3_actual_invoice_value is not None and stage_synced(trip, 3):
        take, value = value_to_pull(trip, "s3_actual_invoice_value", 3, cost, "float")
        if take:
            trip.s3_actual_invoice_value = value
            pulled.append("s3_actual_invoice_value")
    if await _pull_material_docs(db, trip, records.get("parcel") or {}, etags, client, token):
        pulled.append("s3_material_doc_urls")
    for column, stage, source, get, prefix, _label in PHOTOS:
        if stage == 1 and not has_booking:
            continue
        fid = get(records.get(source))
        if not fid:
            continue
        stored = _stored_row(db, getattr(trip, column, None))
        action = photo_action(trip, column, stage, fid, etags.get(fid), getattr(stored, "rr_file_id", None))
        if action == "skip":
            continue
        if action == "check" and await _store_photo(db, trip, column, stage, prefix, fid, client, token):
            pulled.append(column)
        remember_seen(trip, column, fid, etags.get(fid))
    if pulled and any(c.startswith("s1_") for c in pulled):
        stage1_document_service.refresh_stage1_numbers(db, trip)       # pulled numbers / valid-till dates reach the stored papers too
    return pulled


async def pull_trips(db, trips: list, client, token, *, claim: bool = True) -> list[tuple]:
    """Pull RR web's changes into these trips. Returns [(trip, [columns])]. Never raises."""
    done = []
    mine = [t for t in trips if t.rr_trip_id and t.status not in ("cancelled", "completed")]
    if not mine or not token:
        return done
    try:
        records = await read_rr_records(client, token, mine)
    except Exception as exc:
        logger.info(f"[RR Pull] reading RR failed - nothing changed ({exc})")
        return done
    etags = records.pop("_etags", {})
    for trip in mine:
        if claim and not rr_sync_service._claim_trip_sync(db, trip.id):
            continue
        try:
            db.refresh(trip)
            before_seen = json.dumps((trip.rr_synced_doc_urls or {}).get(RR_SEEN_KEY), sort_keys=True)
            pulled = await pull_trip(db, trip, records.get(trip.id) or {}, etags, client, token)
            if pulled:
                db.add(ev.TripBookingEvent(trip_id=trip.id, event=RR_WEB_UPDATED, rr_trip_id=trip.rr_trip_id,
                                           created_by=None, reason=", ".join(LABELS.get(c, c) for c in pulled)[:2000]))
                trip.rr_web_changed_at = datetime.now(timezone.utc)
                done.append((trip, pulled))
            if pulled or json.dumps((trip.rr_synced_doc_urls or {}).get(RR_SEEN_KEY), sort_keys=True) != before_seen:
                db.commit()
            if pulled:
                logger.info(f"[RR Pull] {trip.trip_number}: pulled from RR web: {', '.join(pulled)}")
        except Exception:
            db.rollback()
            logger.exception(f"[RR Pull] could not pull RR web's changes into {trip.trip_number}")
        finally:
            if claim:
                rr_sync_service._release_trip_sync(db, trip.id)
    return done


RR_WEB_UPDATED = "rr_web_updated"
