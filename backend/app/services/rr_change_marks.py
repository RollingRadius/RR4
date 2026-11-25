"""Which trip fields and files changed since they were last sent to RR (user rule, 2026-11-20):

- changed and saved      -> sent on the next sync;
- saved but not changed  -> kept in our database only, not sent.

Every stage save snapshots the synced columns before it writes (snapshot) and, just before its commit, records the
columns whose value changed (record_changes). The sync then sends a stage's column only when that stage never synced
successfully before (new trips, failed stages, saves made before this rule existed) or the column is on the trip's
"changed" list (should_send); after RR accepted it the column is taken off the list (clear). Values pulled from RR,
files copied from the disk and links repointed by scripts are never recorded as changed, so they are not sent back.

The list lives in the trip's existing JSON column trips.rr_synced_doc_urls under CHANGED_KEY (no migration)."""

CHANGED_KEY = "_changed"

# The columns each stage's sync sends to RR.
STAGE_COLUMNS = {
    1: ("s1_driving_license_url", "s1_driving_license_back_url", "s1_aadhaar_url", "s1_aadhaar_back_url",
        "s1_driving_license", "s1_aadhaar",
        "s1_rc", "s1_rc_back", "s1_rc_number", "s1_pollution", "s1_puc_number", "s1_fitness", "s1_fitness_number",
        "s1_permit", "s1_permit_number", "s1_insurance", "s1_insurance_number",
        "s1_pan", "s1_pan_number", "s1_tax_declaration", "s1_tax_declaration_expiry", "s1_cancelled_cheque"),
    2: ("s2_loading_slip_url",),
    3: ("s3_eway_bill_number", "s3_eway_bill_url", "s3_eway_bill_issue_date", "s3_eway_bill_expiry_date",
        "s3_loaded_truck_weight_kg", "s3_loaded_truck_weight_unit", "s3_loaded_weight_slip_url", "s3_material_doc_urls",
        "s3_invoice_number", "s3_vehicle_reach_datetime", "s3_loading_start_datetime", "s3_actual_invoice_value"),
    4: ("s4_diesel_receipt_url", "s4_vehicle_exit_datetime", "s4_bilty_url"),
    5: ("s5_pod_url", "s5_halting_charge", "s5_vehicle_reach_datetime", "s5_unloading_start_datetime",
        "s5_unloading_end_datetime"),
}
ALL_COLUMNS = tuple(c for cols in STAGE_COLUMNS.values() for c in cols)


def snapshot(trip) -> dict:
    """The synced columns' values before a save writes."""
    return {c: getattr(trip, c, None) for c in ALL_COLUMNS}


def record_changes(trip, before: dict) -> list[str]:
    """Put every synced column whose value differs from `before` on the trip's changed list. Returns them."""
    changed = [c for c, old in before.items() if getattr(trip, c, None) != old]
    if changed:
        marks = dict(trip.rr_synced_doc_urls or {})
        marks[CHANGED_KEY] = sorted(set(marks.get(CHANGED_KEY) or []) | set(changed))
        trip.rr_synced_doc_urls = marks
    return changed


def changed_columns(trip) -> set:
    return set((getattr(trip, "rr_synced_doc_urls", None) or {}).get(CHANGED_KEY) or [])


def should_send(trip, column: str, stage_synced_before: bool) -> bool:
    """Send this column now? Yes when its stage never synced successfully before, else only when it changed."""
    return (not stage_synced_before) or column in changed_columns(trip)


def clear(trip, columns) -> None:
    """Take columns RR has accepted off the changed list."""
    marks = dict(getattr(trip, "rr_synced_doc_urls", None) or {})
    left = set(marks.get(CHANGED_KEY) or []) - set(columns)
    if left:
        marks[CHANGED_KEY] = sorted(left)
    else:
        marks.pop(CHANGED_KEY, None)
    trip.rr_synced_doc_urls = marks


# ── Stage 1 is sent in parts (driver / truck / insurance / owner papers / cheque) ─────────────────────────────────────
# One failed part (e.g. the cheque: the owner has no bank account in RR) used to keep the WHOLE stage "never synced":
# every Stage 1 mark stayed, RR web's later changes to papers RR had accepted were never pulled, and the next sync sent
# our older values back over them (fc11, 2026-11-25). Each part RR accepted is now recorded and its marks cleared; a
# failed part stays pending on its own. Kept in rr_synced_doc_urls under S1_PARTS_OK_KEY (no migration).
S1_PARTS = {
    "driver": ("s1_driving_license_url", "s1_driving_license_back_url", "s1_aadhaar_url", "s1_aadhaar_back_url",
               "s1_driving_license", "s1_aadhaar"),
    "vehicle": ("s1_rc", "s1_rc_back", "s1_rc_number", "s1_pollution", "s1_puc_number", "s1_fitness",
                "s1_fitness_number", "s1_permit", "s1_permit_number"),
    "insurance": ("s1_insurance", "s1_insurance_number"),
    "owner": ("s1_pan", "s1_pan_number", "s1_tax_declaration", "s1_tax_declaration_expiry"),
    "cheque": ("s1_cancelled_cheque",),
}
S1_PARTS_OK_KEY = "_s1_parts_ok"
assert set(c for cols in S1_PARTS.values() for c in cols) == set(STAGE_COLUMNS[1])


def s1_part_of(column: str):
    return next((p for p, cols in S1_PARTS.items() if column in cols), None)


def s1_parts_ok(trip) -> set:
    return set((getattr(trip, "rr_synced_doc_urls", None) or {}).get(S1_PARTS_OK_KEY) or [])


def s1_part_synced(trip, part) -> bool:
    """This Stage 1 part reached RR at least once (the whole stage synced, or this part did)."""
    return getattr(trip, "rr_s1_sync_status", None) == "synced" or (part is not None and part in s1_parts_ok(trip))


def mark_s1_parts_ok(trip, parts) -> None:
    """RR accepted these parts: recorded, and their columns taken off the changed list."""
    parts = set(parts)
    if not parts:
        return
    clear(trip, [c for p in parts for c in S1_PARTS[p]])
    marks = dict(getattr(trip, "rr_synced_doc_urls", None) or {})
    marks[S1_PARTS_OK_KEY] = sorted(set(marks.get(S1_PARTS_OK_KEY) or []) | parts)
    trip.rr_synced_doc_urls = marks


def forget_s1_parts(trip, parts) -> None:
    """Papers of these parts left the trip (reassign / booking cancel): their marks and "reached RR" record go too,
    so the NEW driver's / truck's / owner's papers are pulled and sent as new."""
    clear(trip, [c for p in parts for c in S1_PARTS[p]])
    marks = dict(getattr(trip, "rr_synced_doc_urls", None) or {})
    left = set(marks.get(S1_PARTS_OK_KEY) or []) - set(parts)
    if left:
        marks[S1_PARTS_OK_KEY] = sorted(left)
    else:
        marks.pop(S1_PARTS_OK_KEY, None)
    trip.rr_synced_doc_urls = marks
