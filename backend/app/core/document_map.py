"""Single source of truth for which trip column holds which uploaded document.

Each entry says where the file lives in the document tables, which owner it
belongs to, and which field_attributions key / RR stage it touches when it is
replaced. The dry-run report, the copy script and the upload endpoints all read
this map so they cannot drift apart.
"""

from dataclasses import dataclass
from typing import Optional
from urllib.parse import urlparse

DRIVER = "driver_documents"
VEHICLE = "vehicle_documents"
OWNER = "owner_documents"
TRIP = "trip_documents"


@dataclass(frozen=True)
class UploadColumn:
    column: str
    table: str
    doc_type: str
    stage: int
    side: Optional[str] = None
    number_column: Optional[str] = None
    attr_key: Optional[str] = None
    is_list: bool = False
    legacy: bool = False
    expiry_column: Optional[str] = None   # trip column holding the document's valid-till date


UPLOAD_COLUMNS = [
    # Stage 1 - driver
    UploadColumn("s1_driving_license_url", DRIVER, "driving_licence", 1, "front", "s1_driving_license", "dl_doc"),
    UploadColumn("s1_driving_license_back_url", DRIVER, "driving_licence", 1, "back", "s1_driving_license", "dl_back_doc"),
    UploadColumn("s1_aadhaar_url", DRIVER, "aadhaar", 1, "front", "s1_aadhaar", "aadhaar_doc"),
    UploadColumn("s1_aadhaar_back_url", DRIVER, "aadhaar", 1, "back", "s1_aadhaar", "aadhaar_back_doc"),
    # Stage 1 - vehicle
    UploadColumn("s1_rc", VEHICLE, "registration_certificate", 1, "front", "s1_rc_number", "rc_doc"),
    UploadColumn("s1_rc_back", VEHICLE, "registration_certificate", 1, "back", "s1_rc_number", "rc_back_doc"),
    UploadColumn("s1_insurance", VEHICLE, "insurance", 1, "front", "s1_insurance_number", "insurance_doc"),
    UploadColumn("s1_pollution", VEHICLE, "puc", 1, "front", "s1_puc_number", "pollution_doc"),
    UploadColumn("s1_fitness", VEHICLE, "fitness", 1, "front", "s1_fitness_number", "fitness_doc"),
    UploadColumn("s1_permit", VEHICLE, "permit", 1, "front", "s1_permit_number", "permit_doc"),
    # Stage 1 - vehicle owner
    UploadColumn("s1_pan", OWNER, "pan", 1, "front", "s1_pan_number", "pan_doc"),
    UploadColumn("s1_tax_declaration", OWNER, "tax_declaration", 1, "front", None, "tax_declaration_doc",
                 expiry_column="s1_tax_declaration_expiry"),
    UploadColumn("s1_cancelled_cheque", OWNER, "cancelled_cheque", 1, "front", None, "cancelled_cheque_doc"),
    # Trip documents
    UploadColumn("s2_loading_slip_url", TRIP, "loading_slip", 2, attr_key="loading_slip"),
    UploadColumn("rr_loading_slip_url", TRIP, "rr_loading_slip", 2),
    UploadColumn("s3_loaded_weight_slip_url", TRIP, "loaded_weight_slip", 3, attr_key="loaded_weight_slip"),
    UploadColumn("s3_eway_bill_url", TRIP, "eway_bill", 3, attr_key="eway_bill_doc"),
    UploadColumn("s3_material_doc_urls", TRIP, "material_doc", 3, attr_key="material_docs", is_list=True),
    UploadColumn("s3_bilty_url", TRIP, "bilty_legacy", 3, legacy=True),
    UploadColumn("s4_diesel_receipt_url", TRIP, "diesel_receipt", 4, attr_key="diesel_receipt"),
    UploadColumn("s4_bilty_url", TRIP, "bilty", 4, attr_key="bilty_doc"),
    UploadColumn("s4_material_verification_url", TRIP, "material_verification", 4, attr_key="material_verification_sheet"),
    UploadColumn("s5_pod_url", TRIP, "pod", 5, attr_key="pod_doc"),
]

# Trip columns that look like uploads (end in _url / _urls) but hold no file.
NOT_UPLOADS = {"rr_synced_doc_urls"}

UPLOAD_COLUMN_NAMES = [c.column for c in UPLOAD_COLUMNS]

# Local databases the dry-run and copy scripts may touch. Anything else is refused.
# fleet_db_prodcopy holds a restored copy of the prod database for practice (same local container).
DEV_DB_HOST = "localhost"
DEV_DB_PORT = 5434
DEV_DB_NAMES = ("fleet_db_dev", "fleet_db_prodcopy")


def is_dev_database_url(url: str) -> bool:
    """True only for the local dev databases (localhost:5434, fleet_db_dev or fleet_db_prodcopy)."""
    parsed = urlparse(url)
    host = (parsed.hostname or "").lower()
    name = (parsed.path or "").lstrip("/")
    return host in ("localhost", "127.0.0.1") and parsed.port == DEV_DB_PORT and name in DEV_DB_NAMES
