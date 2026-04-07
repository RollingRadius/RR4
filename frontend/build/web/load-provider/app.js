'use strict';

/* ── Config ─────────────────────────────────────────────── */
const CFG = window.RR_CONFIG || { apiBase: '', tokenKey: 'rr_lp_token' };
const API = `${CFG.apiBase}/api`;

/* ── State ──────────────────────────────────────────────── */
const state = {
  token:        null,
  user:         null,
  loads:        [],
  loadsLoaded:  false,
  activeView:   'home',
  tripsFilter:  'all',
  activeTab:    'manual',
  truckCount:   8,
  specsOpen:    true,
  files:        [],
  cameraStream: null,
  capturedBlob: null,
  submitting:   false,
};

/* ── DOM shortcut ──────────────────────────────────────── */
const $ = id => document.getElementById(id);

/* ── API helper ────────────────────────────────────────── */
async function apiFetch(path, opts = {}) {
  const headers = {
    ...(opts.body && !(opts.body instanceof FormData)
        ? { 'Content-Type': 'application/json' } : {}),
    ...(state.token ? { Authorization: `Bearer ${state.token}` } : {}),
    ...(opts.headers || {}),
  };
  const res = await fetch(`${API}${path}`, { ...opts, headers });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.detail || `HTTP ${res.status}`);
  }
  return res.json();
}

/* ── Auth guard ────────────────────────────────────────── */
async function bootAuth() {
  const token = localStorage.getItem(CFG.tokenKey);
  if (!token) { window.location.assign('/'); return false; }
  state.token = token;
  try {
    const profile = await apiFetch('/users/me');
    if (profile.business_type !== 'load_owner') {
      localStorage.removeItem(CFG.tokenKey);
      window.location.assign('/');
      return false;
    }
    state.user = profile;
    hydrateUserUI(profile);
    return true;
  } catch {
    localStorage.removeItem(CFG.tokenKey);
    window.location.assign('/');
    return false;
  }
}

function hydrateUserUI(profile) {
  const name    = profile.full_name || profile.username || 'User';
  const parts   = name.trim().split(/\s+/);
  const initials = parts.length >= 2
    ? (parts[0][0] + parts[1][0]).toUpperCase()
    : (name[0] || 'U').toUpperCase();

  // Top bar avatar
  const avatar = $('avatarBtn');
  if (avatar) avatar.textContent = initials;

  // Hero greeting
  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  const heroEl = $('heroGreeting');
  if (heroEl) heroEl.textContent = `${greeting}, ${parts[0]} 👋`;

  const heroCompany = $('heroCompany');
  if (heroCompany) heroCompany.textContent = profile.company_name || 'RR Logistics';

  const heroDate = $('heroDate');
  if (heroDate) {
    heroDate.textContent = new Date().toLocaleDateString('en-IN', {
      day: 'numeric', month: 'short', year: 'numeric',
    });
  }

  // Profile view
  const pAvatar = $('profileAvatar');
  if (pAvatar) pAvatar.textContent = initials;
  const pName = $('profileName');
  if (pName) pName.textContent = name;
  const pUser = $('profileUsername');
  if (pUser) pUser.textContent = `@${profile.username || '—'}`;
  const pCompany = $('profileCompany');
  if (pCompany) pCompany.textContent = profile.company_name || '—';
  const pEmail = $('profileEmail');
  if (pEmail) pEmail.textContent = profile.email || '—';
  const pPhone = $('profilePhone');
  if (pPhone) pPhone.textContent = profile.phone || '—';
}

/* ── Snackbar ───────────────────────────────────────────── */
let _snackTimer = null;
function showSnack(msg, type = 'info') {
  const wrap  = $('snackbar');
  const inner = $('snackInner');
  const icon  = $('snackIcon');
  $('snackMsg').textContent = msg;

  inner.className = 'flex items-center gap-3 px-4 py-3 rounded-2xl shadow-xl text-white text-sm font-medium';
  if (type === 'success') {
    inner.classList.add('bg-green-800');
    icon.textContent = 'check_circle';
  } else if (type === 'error') {
    inner.classList.add('bg-red-700');
    icon.textContent = 'error';
  } else {
    inner.style.background = '#2d3133';
    icon.textContent = 'info';
  }

  wrap.classList.remove('hidden');
  wrap.classList.add('snack-show');
  clearTimeout(_snackTimer);
  _snackTimer = setTimeout(() => {
    wrap.classList.add('hidden');
    wrap.classList.remove('snack-show');
  }, 3500);
}

/* ── Scroll shadow on header ────────────────────────────── */
window.addEventListener('scroll', () => {
  const bar = $('topBar');
  if (!bar) return;
  bar.style.borderBottomColor = window.scrollY > 4
    ? 'rgba(0,30,64,.08)' : 'transparent';
}, { passive: true });

/* ═══════════════════════════════════════════════════════════
   ROUTER — view switching
════════════════════════════════════════════════════════════ */
const VIEWS = ['home', 'upload', 'trips', 'fleet', 'profile'];

function navigateTo(view, opts = {}) {
  if (!VIEWS.includes(view)) return;
  state.activeView = view;

  // Switch views
  VIEWS.forEach(v => {
    const el = $(`view-${v}`);
    if (!el) return;
    el.classList.toggle('active', v === view);
    if (v === view) el.classList.add('view-enter');
  });

  // Show/hide submit FAB (upload view only)
  const fab = $('fabWrap');
  if (fab) fab.classList.toggle('hidden', view !== 'upload');

  // Show/hide New Load FAB (home view only)
  const newLoadFab = $('newLoadFab');
  if (newLoadFab) newLoadFab.classList.toggle('hidden', view !== 'home');

  // Update nav pills
  document.querySelectorAll('[data-nav]').forEach(btn => {
    const on = btn.dataset.nav === view;
    btn.classList.toggle('active', on);
    if (on) btn.setAttribute('aria-current', 'page');
    else btn.removeAttribute('aria-current');
  });

  // Scroll to top
  if (!opts.noScroll) window.scrollTo({ top: 0, behavior: 'smooth' });

  // Lazy-load data for views
  if (view === 'home') renderHome();
  if (view === 'trips') renderTrips();
  if (view === 'fleet') renderFleet();
  if (view === 'profile') renderProfile();
}

/* Bottom nav clicks */
document.querySelectorAll('[data-nav]').forEach(btn => {
  btn.addEventListener('click', () => navigateTo(btn.dataset.nav));
});

/* ═══════════════════════════════════════════════════════════
   LOADS DATA
════════════════════════════════════════════════════════════ */
async function fetchLoads() {
  if (state.loadsLoaded) return state.loads;
  try {
    const data = await apiFetch('/loads');
    state.loads = Array.isArray(data) ? data
      : Array.isArray(data?.items) ? data.items
      : Array.isArray(data?.loads) ? data.loads : [];
    state.loadsLoaded = true;
  } catch {
    state.loads = [];
    state.loadsLoaded = true;
  }
  return state.loads;
}

/* Force-refresh loads (after submit) */
async function refreshLoads() {
  state.loadsLoaded = false;
  return fetchLoads();
}

/* ═══════════════════════════════════════════════════════════
   HOME DASHBOARD
════════════════════════════════════════════════════════════ */
async function renderHome() {
  const loads = await fetchLoads();

  const active    = loads.filter(l => (l.status || '').toLowerCase() === 'active').length;
  const completed = loads.filter(l => (l.status || '').toLowerCase() === 'completed' || (l.status || '').toLowerCase() === 'delivered').length;
  const pending   = loads.filter(l => (l.status || '').toLowerCase() === 'pending' || !l.status).length;

  const sa = $('statActive');    if (sa) sa.textContent = String(active).padStart(2, '0');
  const sc = $('statCompleted'); if (sc) sc.textContent = String(completed).padStart(2, '0');
  const sp = $('statPending');   if (sp) sp.textContent = String(pending).padStart(2, '0');

  renderRecentLoads(loads.slice(-5).reverse());
}

function renderRecentLoads(loads) {
  const container = $('recentLoads');
  if (!container) return;

  if (!loads.length) {
    container.innerHTML = `
      <div class="flex flex-col items-center justify-center gap-3 py-10 text-center">
        <span class="material-symbols-outlined text-outline text-4xl">inbox</span>
        <p class="text-sm font-bold text-on-surface-variant">No loads yet</p>
        <p class="text-xs text-outline">Submit your first load requirement to get started</p>
      </div>`;
    return;
  }

  container.innerHTML = loads.map(load => buildLoadCard(load)).join('');
}

/* ═══════════════════════════════════════════════════════════
   MY TRIPS
════════════════════════════════════════════════════════════ */
async function renderTrips() {
  const loads = await fetchLoads();
  applyTripsFilter(loads, state.tripsFilter);
}

function applyTripsFilter(loads, filter) {
  state.tripsFilter = filter;
  const filtered = filter === 'all' ? loads
    : loads.filter(l => {
        const s = (l.status || 'pending').toLowerCase();
        if (filter === 'active')    return s === 'active';
        if (filter === 'completed') return s === 'completed' || s === 'delivered';
        if (filter === 'pending')   return s === 'pending' || !l.status;
        return true;
      });

  // Update chip styles
  document.querySelectorAll('#tripFilters .chip').forEach(c => {
    const on = c.dataset.filter === filter;
    c.classList.toggle('active', on);
  });

  const container = $('tripsList');
  if (!container) return;

  if (!filtered.length) {
    container.innerHTML = `
      <div class="flex flex-col items-center justify-center gap-3 py-10 text-center">
        <span class="material-symbols-outlined text-outline text-4xl">search_off</span>
        <p class="text-sm font-bold text-on-surface-variant">No ${filter} trips</p>
      </div>`;
    return;
  }

  container.innerHTML = [...filtered].reverse().map(load => buildLoadCard(load)).join('');
}

/* Filter chip clicks */
document.querySelectorAll('#tripFilters .chip').forEach(btn => {
  btn.addEventListener('click', () => {
    fetchLoads().then(loads => applyTripsFilter(loads, btn.dataset.filter));
  });
});

/* ═══════════════════════════════════════════════════════════
   FLEET VIEW
════════════════════════════════════════════════════════════ */
async function renderFleet() {
  const loads = await fetchLoads();

  // Derive fleet stats from truck counts across loads
  const totalTrucks    = loads.reduce((s, l) => s + (l.truck_count || 0), 0);
  const activeTrucks   = loads.filter(l => (l.status || '').toLowerCase() === 'active')
                               .reduce((s, l) => s + (l.truck_count || 0), 0);
  const availTrucks    = Math.max(0, totalTrucks - activeTrucks);
  const maintTrucks    = 0; // no maintenance data from loads

  const ft = $('fleetTotal');    if (ft) ft.textContent = totalTrucks  || '—';
  const fr = $('fleetOnRoute');  if (fr) fr.textContent = activeTrucks || '—';
  const fa = $('fleetAvail');    if (fa) fa.textContent = availTrucks  || '—';
  const fm = $('fleetMaint');    if (fm) fm.textContent = maintTrucks  || '—';
}

/* ═══════════════════════════════════════════════════════════
   PROFILE VIEW
════════════════════════════════════════════════════════════ */
async function renderProfile() {
  const loads = await fetchLoads();
  const active    = loads.filter(l => (l.status || '').toLowerCase() === 'active').length;
  const completed = loads.filter(l => ['completed','delivered'].includes((l.status || '').toLowerCase())).length;

  const pt = $('profileTotal'); if (pt) pt.textContent = loads.length;
  const pa = $('profileActive'); if (pa) pa.textContent = active;
  const pd = $('profileDone');  if (pd) pd.textContent = completed;
}

/* ═══════════════════════════════════════════════════════════
   LOAD CARD BUILDER
════════════════════════════════════════════════════════════ */
function buildLoadCard(load) {
  const pickup  = load.pickup_location  || load.origin      || 'Unknown origin';
  const unload  = load.unload_location  || load.destination || 'Unknown destination';
  const status  = (load.status || 'pending').toLowerCase();
  const material = load.material_type  || '—';
  const trucks   = load.truck_count    || '—';
  const date     = load.entry_date || load.created_at
    ? new Date(load.entry_date || load.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
    : '—';

  const badgeClass = {
    active:    'badge--active',
    completed: 'badge--delivered',
    delivered: 'badge--delivered',
    pending:   'badge--pending',
    cancelled: 'badge--cancelled',
  }[status] || 'badge--pending';

  const badgeLabel = status.charAt(0).toUpperCase() + status.slice(1);

  return `
    <div class="load-card">
      <div class="flex items-start justify-between gap-2">
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-1">
            <span class="material-symbols-outlined text-primary text-[16px] shrink-0">trip_origin</span>
            <span class="text-sm font-semibold text-on-surface truncate">${escHtml(pickup)}</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-primary text-[16px] shrink-0">location_on</span>
            <span class="text-sm text-on-surface-variant truncate">${escHtml(unload)}</span>
          </div>
        </div>
        <span class="badge ${badgeClass} shrink-0">${escHtml(badgeLabel)}</span>
      </div>
      <div class="flex items-center gap-4 text-[0.625rem] font-semibold text-on-surface-variant uppercase tracking-wider">
        <span class="flex items-center gap-1">
          <span class="material-symbols-outlined text-[14px]">inventory_2</span>
          ${escHtml(material)}
        </span>
        <span class="flex items-center gap-1">
          <span class="material-symbols-outlined text-[14px]">local_shipping</span>
          ${trucks} trucks
        </span>
        <span class="flex items-center gap-1 ml-auto">
          <span class="material-symbols-outlined text-[14px]">calendar_today</span>
          ${date}
        </span>
      </div>
    </div>`;
}

function escHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* ═══════════════════════════════════════════════════════════
   UPLOAD VIEW — Entry Method Tabs
════════════════════════════════════════════════════════════ */
const TAB_PANELS = { manual: 'panelManual', bulk: 'panelBulk', photo: 'panelPhoto' };

function switchTab(tab) {
  state.activeTab = tab;

  document.querySelectorAll('[data-tab]').forEach(btn => {
    const on = btn.dataset.tab === tab;
    btn.classList.toggle('bg-primary',              on);
    btn.classList.toggle('text-white',              on);
    btn.classList.toggle('bg-surface-container',    !on);
    btn.classList.toggle('text-on-surface-variant', !on);
    btn.setAttribute('aria-selected', String(on));
  });

  Object.entries(TAB_PANELS).forEach(([key, panelId]) => {
    const p = $(panelId);
    if (!p) return;
    p.classList.toggle('active', key === tab);
  });

  if (tab === 'photo') initCamera(); else stopCamera();
}

document.querySelectorAll('[data-tab]').forEach(btn =>
  btn.addEventListener('click', () => switchTab(btn.dataset.tab))
);

/* ── Truck Count stepper ──────────────────────────────── */
function updateTruckDisplay() {
  const el = $('truckDisplay');
  if (el) el.textContent = String(state.truckCount).padStart(2, '0') + ' Units';
}
$('btnMinus')?.addEventListener('click', () => {
  if (state.truckCount > 1) { state.truckCount--; updateTruckDisplay(); }
});
$('btnPlus')?.addEventListener('click', () => {
  if (state.truckCount < 99) { state.truckCount++; updateTruckDisplay(); }
});

/* ── Specs collapsible ─────────────────────────────────── */
$('specsToggle')?.addEventListener('click', () => {
  state.specsOpen = !state.specsOpen;
  const grid    = $('specsGrid');
  const chevron = $('specsChevron');
  if (grid)    grid.classList.toggle('open', state.specsOpen);
  if (chevron) chevron.style.transform = state.specsOpen ? 'rotate(180deg)' : 'rotate(0deg)';
  $('specsToggle')?.setAttribute('aria-expanded', String(state.specsOpen));
});
const specsChevron = $('specsChevron');
if (specsChevron) specsChevron.style.transform = 'rotate(180deg)';

/* ── File Upload ──────────────────────────────────────── */
const MAX_FILES = 5;
const ACCEPTED  = ['xlsx', 'xls', 'csv'];

function handleFiles(incoming) {
  const valid = Array.from(incoming).filter(f =>
    ACCEPTED.includes(f.name.split('.').pop().toLowerCase())
  );
  if (!valid.length) { showSnack('Only .xlsx, .xls or .csv files accepted', 'error'); return; }
  const slots = MAX_FILES - state.files.length;
  if (!slots)  { showSnack(`Maximum ${MAX_FILES} files allowed`, 'error'); return; }
  const toAdd = valid.slice(0, slots);
  if (valid.length > slots) showSnack(`Added ${toAdd.length} of ${valid.length} files`);
  state.files.push(...toAdd);
  renderFileList();
}

function renderFileList() {
  const list = $('fileList');
  if (!list) return;
  list.innerHTML = '';
  state.files.forEach((file, i) => {
    const ext  = file.name.split('.').pop().toUpperCase();
    const icon = ext === 'CSV' ? 'table_chart' : 'grid_on';
    const row  = document.createElement('div');
    row.className = 'flex items-center gap-3 px-4 py-3 bg-surface-container rounded-xl';
    row.innerHTML = `
      <span class="material-symbols-outlined text-primary text-[20px]">${icon}</span>
      <span class="flex-1 text-sm font-medium text-on-surface truncate">${escHtml(file.name)}</span>
      <span class="text-[0.625rem] text-on-surface-variant whitespace-nowrap">${fmtBytes(file.size)}</span>
      <button data-i="${i}" aria-label="Remove ${escHtml(file.name)}"
        class="file-rm material-symbols-outlined text-outline hover:text-error text-[18px] transition-colors">close</button>`;
    list.appendChild(row);
  });
  list.querySelectorAll('.file-rm').forEach(btn =>
    btn.addEventListener('click', () => { state.files.splice(+btn.dataset.i, 1); renderFileList(); })
  );
}

function fmtBytes(b) {
  if (b < 1024)    return b + ' B';
  if (b < 1048576) return (b / 1024).toFixed(1) + ' KB';
  return (b / 1048576).toFixed(1) + ' MB';
}

function setupDropZone(dzId, inputId) {
  const dz = $(dzId);
  const fi = $(inputId);
  if (!dz || !fi) return;
  ['dragenter','dragover'].forEach(ev =>
    dz.addEventListener(ev, e => { e.preventDefault(); dz.classList.add('drag-over-ring'); })
  );
  ['dragleave','dragend','drop'].forEach(ev =>
    dz.addEventListener(ev, e => { e.preventDefault(); dz.classList.remove('drag-over-ring'); })
  );
  dz.addEventListener('drop', e => handleFiles(e.dataTransfer.files));
  dz.addEventListener('keydown', e => {
    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); fi.click(); }
  });
  fi.addEventListener('change', e => handleFiles(e.target.files));
}

setupDropZone('dropZone', 'fileInput');
setupDropZone('dropZone2', 'fileInput2');

$('browseBtn')?.addEventListener('click',  e => { e.stopPropagation(); $('fileInput')?.click(); });
$('browseBtn2')?.addEventListener('click', e => { e.stopPropagation(); $('fileInput2')?.click(); });

$('photoShortcut')?.addEventListener('click', () => switchTab('photo'));
$('photoShortcut')?.addEventListener('keydown', e => {
  if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); switchTab('photo'); }
});

/* ── Camera ────────────────────────────────────────────── */
async function initCamera() {
  if (state.cameraStream) return;
  if (!navigator.mediaDevices?.getUserMedia) {
    showSnack('Camera not supported on this device', 'error'); return;
  }
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'environment', width: { ideal: 1920 } }, audio: false,
    });
    state.cameraStream = stream;
    const feed = $('cameraFeed');
    feed.srcObject = stream;
    feed.classList.remove('hidden');
    $('cameraPlaceholder')?.classList.add('hidden');
    $('capturedPhoto')?.classList.add('hidden');
    $('captureBtn')?.classList.remove('hidden');
    $('retakeBtn')?.classList.add('hidden');
  } catch {
    showSnack('Camera access denied', 'error');
  }
}

function stopCamera() {
  if (!state.cameraStream) return;
  state.cameraStream.getTracks().forEach(t => t.stop());
  state.cameraStream = null;
  const feed = $('cameraFeed');
  if (feed) { feed.srcObject = null; feed.classList.add('hidden'); }
  $('cameraPlaceholder')?.classList.remove('hidden');
  $('captureBtn')?.classList.add('hidden');
  $('retakeBtn')?.classList.add('hidden');
}

$('cameraWrap')?.addEventListener('click', () => {
  if (!state.cameraStream && !state.capturedBlob) initCamera();
});

$('captureBtn')?.addEventListener('click', () => {
  const vid = $('cameraFeed');
  const c   = document.createElement('canvas');
  c.width = vid.videoWidth; c.height = vid.videoHeight;
  c.getContext('2d').drawImage(vid, 0, 0);
  c.toBlob(blob => {
    state.capturedBlob = blob;
    const photo = $('capturedPhoto');
    photo.src = URL.createObjectURL(blob);
    photo.classList.remove('hidden');
    $('cameraFeed')?.classList.add('hidden');
    $('captureBtn')?.classList.add('hidden');
    $('retakeBtn')?.classList.remove('hidden');
    stopCamera();
    showSnack('Photo captured — ready to submit', 'success');
  }, 'image/jpeg', 0.9);
});

$('retakeBtn')?.addEventListener('click', () => {
  state.capturedBlob = null;
  const p = $('capturedPhoto');
  if (p?.src) URL.revokeObjectURL(p.src);
  p?.classList.add('hidden');
  $('retakeBtn')?.classList.add('hidden');
  initCamera();
});

/* ═══════════════════════════════════════════════════════════
   SUBMIT LOAD
════════════════════════════════════════════════════════════ */
$('submitBtn')?.addEventListener('click', handleSubmit);

async function handleSubmit() {
  if (state.submitting) return;

  if (state.activeTab === 'manual') {
    const pickup = $('pickup')?.value.trim();
    const unload = $('unload')?.value.trim();
    if (!pickup) { showSnack('Enter a pickup location', 'error'); $('pickup')?.focus(); return; }
    if (!unload) { showSnack('Enter an unload location', 'error'); $('unload')?.focus(); return; }
  }
  if (state.activeTab === 'bulk'  && !state.files.length)  { showSnack('Attach at least one manifest file', 'error'); return; }
  if (state.activeTab === 'photo' && !state.capturedBlob)  { showSnack('Capture a photo first', 'error'); return; }

  setSubmitting(true);
  try {
    await postLoad();
    showSnack('Load requirement submitted!', 'success');
    resetForm();
    await refreshLoads();
    navigateTo('home');
  } catch (err) {
    showSnack(err.message || 'Submission failed', 'error');
  } finally {
    setSubmitting(false);
  }
}

function setSubmitting(on) {
  state.submitting = on;
  const btn  = $('submitBtn');
  const text = $('submitBtnText');
  const icon = $('submitBtnIcon');
  if (!btn) return;
  btn.disabled = on;
  btn.classList.toggle('fab-disabled', on);
  if (on) {
    if (text) text.textContent = 'Submitting…';
    if (icon) { icon.className = ''; icon.innerHTML = '<span class="spinner"></span>'; }
  } else {
    if (text) text.textContent = 'Submit Load Requirement';
    if (icon) { icon.className = 'material-symbols-outlined text-[20px]'; icon.textContent = 'send'; }
  }
}

async function postLoad() {
  if (state.activeTab === 'bulk' && state.files.length) {
    const fd = new FormData();
    state.files.forEach(f => fd.append('files', f));
    const date = $('entryDate')?.value;
    if (date) fd.append('entry_date', date);
    fd.append('truck_count', String(state.truckCount));
    return apiFetch('/loads/bulk', { method: 'POST', body: fd });
  }

  if (state.activeTab === 'photo' && state.capturedBlob) {
    const fd = new FormData();
    fd.append('photo', state.capturedBlob, 'load-photo.jpg');
    return apiFetch('/loads/photo', { method: 'POST', body: fd });
  }

  return apiFetch('/loads', {
    method: 'POST',
    body: JSON.stringify({
      entry_method:    'manual',
      pickup_location: $('pickup')?.value.trim(),
      unload_location: $('unload')?.value.trim(),
      material_type:   $('material')?.value,
      entry_date:      $('entryDate')?.value || null,
      truck_count:     state.truckCount,
      specifications: {
        capacity:  $('specCapacity')?.textContent,
        axel_type: $('specAxel')?.textContent,
        body:      $('specBody')?.textContent,
        floor:     $('specFloor')?.textContent,
      },
    }),
  });
}

function resetForm() {
  ['pickup', 'unload'].forEach(id => { const el = $(id); if (el) el.value = ''; });
  const mat = $('material');
  if (mat) mat.value = 'Steel Coils';
  const de = $('entryDate');
  if (de) de.value = new Date().toISOString().split('T')[0];
  state.truckCount   = 8;
  state.files        = [];
  state.capturedBlob = null;
  updateTruckDisplay();
  renderFileList();
  const p = $('capturedPhoto');
  if (p?.src) { URL.revokeObjectURL(p.src); p.classList.add('hidden'); }
}

/* ═══════════════════════════════════════════════════════════
   MENU & PROFILE ACTIONS
════════════════════════════════════════════════════════════ */
$('menuBtn')?.addEventListener('click', () => showSnack('Sidebar menu coming soon'));

$('avatarBtn')?.addEventListener('click', () => navigateTo('profile'));

$('logoutBtn')?.addEventListener('click', handleLogout);

function handleLogout() {
  if (confirm('Sign out of RR Logistics?')) {
    stopCamera();
    localStorage.removeItem(CFG.tokenKey);
    window.location.assign('/');
  }
}

/* Quick action buttons */
$('btnNewLoad')?.addEventListener('click', () => navigateTo('upload'));
$('btnViewAll')?.addEventListener('click', () => navigateTo('trips'));

// Expose for inline onclick on FAB
window.navigateTo = navigateTo;

/* ═══════════════════════════════════════════════════════════
   INIT
════════════════════════════════════════════════════════════ */
(async function init() {
  // Default entry date
  const de = $('entryDate');
  if (de) { de.min = de.value = new Date().toISOString().split('T')[0]; }

  updateTruckDisplay();
  switchTab('manual');

  // Start on home view
  navigateTo('home', { noScroll: true });

  const ok = await bootAuth();
  if (ok) {
    // Remove auth guard with fade
    const guard = $('authGuard');
    if (guard) {
      guard.style.transition = 'opacity 300ms ease';
      guard.style.opacity    = '0';
      setTimeout(() => guard.remove(), 320);
    }
    // Pre-fetch loads in background
    fetchLoads();
  }
})();
