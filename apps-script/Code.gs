/**
 * Penerima jawaban kuesioner skripsi.
 * Ditempel di Google Sheet: Ekstensi > Apps Script, lalu di-deploy sebagai Web App.
 *
 * Tab (dibuat otomatis kalau belum ada):
 *   undangan : daftar kode undangan per strata + statusnya (dibuat lewat menu "Kuesioner")
 *   jawaban  : satu baris per responden yang selesai, kolom = nama variabel codebook
 *   status   : yang berhenti di awal (tolak / tidak memenuhi kriteria)
 *   kontak   : kontak wawancara, terpisah dari jawaban, dihubungkan lewat resp_id
 *
 * Kode undangan sengaja TIDAK disimpan di baris jawaban. Tab undangan hanya mencatat
 * bahwa sebuah kode sudah dipakai dan tanggalnya, jadi daftar penerima undangan tidak
 * bisa dicocokkan dengan jawaban seseorang.
 */

// Harus sama persis dengan CONFIG.TOKEN di index.html.
// Ini hanya penyaring kiriman iseng/bot, bukan rahasia: token terlihat di kode halaman.
const TOKEN = 'ganti-dengan-kata-acak';

// true = jawaban hanya diterima dari link berkode yang ada di tab undangan, dan tiap kode sekali pakai.
// Samakan dengan CONFIG.WAJIB_KODE di index.html.
const WAJIB_KODE = true;

// Alamat halaman kuesioner, dipakai untuk membuat link pribadi di tab undangan.
const BASE_URL = 'https://khlaaz.github.io/kuesioner/';

const ZONA = 'Asia/Jakarta';
const HURUF = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // tanpa 0/O, 1/I/L supaya tidak tertukar

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    const p = JSON.parse(e.postData.contents);
    if (p.token !== TOKEN) return out_({ ok: false, err: 'token' });
    if (!p.data || !p.data.resp_id) return out_({ ok: false, err: 'data' });

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const status = p.status || '';

    let u = null;
    if (WAJIB_KODE) {
      u = cariKode_(ss, String(p.kode || '').toUpperCase());
      if (!u) return out_({ ok: false, err: 'kode' });
      if (u.status === 'selesai') {
        // Kiriman ulang yang sah (koneksi putus setelah jawaban tercatat): jawab ok tanpa menulis apa pun.
        if (status === 'selesai' && ada_(ss, 'jawaban', p.data.resp_id)) return out_({ ok: true });
        return out_({ ok: false, err: 'dipakai' });
      }
    }

    const meta = {
      diterima: new Date().toISOString(),
      versi: p.versi || '',
      gelombang: p.gelombang || '',
      status: status
    };

    if (status === 'selesai') {
      if (!ada_(ss, 'jawaban', p.data.resp_id)) tambah_(ss, 'jawaban', Object.assign(meta, p.data));
      if (p.kontak && !ada_(ss, 'kontak', p.data.resp_id)) {
        tambah_(ss, 'kontak', { diterima: meta.diterima, resp_id: p.data.resp_id, kontak: String(p.kontak).slice(0, 200) });
      }
    } else {
      tambah_(ss, 'status', Object.assign(meta, p.data));
    }
    if (u) tandaiKode_(u, status);
    return out_({ ok: true });
  } catch (err) {
    return out_({ ok: false, err: String(err) });
  } finally {
    lock.releaseLock();
  }
}

// Halaman memanggil ini saat dibuka (…/exec?kode=XXXXXX) supaya responden tidak mengisi 15 menit
// lalu baru tahu kodenya salah. Tanpa parameter: tanda endpoint aktif.
function doGet(e) {
  const kode = e && e.parameter && e.parameter.kode;
  if (!kode) return out_({ ok: true, info: 'Endpoint kuesioner aktif' });
  const u = cariKode_(SpreadsheetApp.getActiveSpreadsheet(), String(kode).toUpperCase());
  return out_({ ok: true, kode: !u ? 'tidak_dikenal' : u.status === 'selesai' ? 'dipakai' : 'valid' });
}

// ===== Menu di Google Sheet =====
function onOpen() {
  SpreadsheetApp.getUi().createMenu('Kuesioner')
    .addItem('Buat kode undangan…', 'buatKode')
    .addToUi();
}

function buatKode() {
  const ui = SpreadsheetApp.getUi();
  const s = ui.prompt('Buat kode undangan', 'Nama strata (mis. Sosiologi, Teknik Sipil dan Lingkungan, pilot, uji):', ui.ButtonSet.OK_CANCEL);
  if (s.getSelectedButton() !== ui.Button.OK || !s.getResponseText().trim()) return;
  const n = ui.prompt('Buat kode undangan', 'Jumlah kode untuk strata "' + s.getResponseText().trim() + '":', ui.ButtonSet.OK_CANCEL);
  if (n.getSelectedButton() !== ui.Button.OK) return;
  const jumlah = parseInt(n.getResponseText(), 10);
  if (!(jumlah > 0 && jumlah <= 2000)) { ui.alert('Jumlah harus angka 1–2000.'); return; }
  const dibuat = tulisKode_(SpreadsheetApp.getActiveSpreadsheet(), s.getResponseText().trim(), jumlah);
  ui.alert(dibuat + ' kode dibuat di tab "undangan". Salin kolom link untuk dikirim ke responden terpilih.');
}

// ===== Pembantu =====
function tulisKode_(ss, strata, jumlah) {
  const sh = tab_(ss, 'undangan', ['kode', 'strata', 'link', 'status', 'tanggal']);
  const lama = sh.getLastRow() > 1 ? sh.getRange(2, 1, sh.getLastRow() - 1, 1).getValues().map(r => r[0]) : [];
  const pakai = {};
  lama.forEach(k => { pakai[k] = 1; });
  const baris = [];
  while (baris.length < jumlah) {
    let k = '';
    for (let i = 0; i < 6; i++) k += HURUF.charAt(Math.floor(Math.random() * HURUF.length));
    if (pakai[k]) continue;
    pakai[k] = 1;
    baris.push([k, strata, BASE_URL + '#' + k, '', '']);
  }
  sh.getRange(sh.getLastRow() + 1, 1, baris.length, 5).setValues(baris);
  return baris.length;
}

function cariKode_(ss, kode) {
  if (!/^[A-Z0-9]{6}$/.test(kode)) return null;
  const sh = ss.getSheetByName('undangan');
  if (!sh || sh.getLastRow() < 2) return null;
  const v = sh.getRange(2, 1, sh.getLastRow() - 1, 5).getValues();
  for (let i = 0; i < v.length; i++) {
    if (v[i][0] === kode) return { sh: sh, row: i + 2, status: v[i][3] };
  }
  return null;
}

// Hanya status dan TANGGAL (tanpa jam) yang dicatat, supaya kode tidak bisa dicocokkan ke baris jawaban lewat waktu kirim.
function tandaiKode_(u, status) {
  if (u.status === 'selesai') return;
  u.sh.getRange(u.row, 4, 1, 2).setValues([[status, Utilities.formatDate(new Date(), ZONA, 'yyyy-MM-dd')]]);
}

function tab_(ss, name, head) {
  let sh = ss.getSheetByName(name);
  if (!sh) {
    sh = ss.insertSheet(name);
    sh.getRange(1, 1, 1, head.length).setValues([head]);
    sh.setFrozenRows(1);
  }
  return sh;
}

function tambah_(ss, name, obj) {
  const sh = ss.getSheetByName(name) || ss.insertSheet(name);
  let head = sh.getLastRow() ? sh.getRange(1, 1, 1, sh.getLastColumn()).getValues()[0] : [];
  const add = Object.keys(obj).filter(k => head.indexOf(k) < 0);
  if (add.length) {
    head = head.concat(add);
    sh.getRange(1, 1, 1, head.length).setValues([head]);
    sh.setFrozenRows(1);
  }
  sh.appendRow(head.map(k => (obj[k] === undefined || obj[k] === null) ? '' : obj[k]));
}

function ada_(ss, name, id) {
  const sh = ss.getSheetByName(name);
  if (!sh || sh.getLastRow() < 2) return false;
  const head = sh.getRange(1, 1, 1, sh.getLastColumn()).getValues()[0];
  const c = head.indexOf('resp_id');
  if (c < 0) return false;
  return sh.getRange(2, c + 1, sh.getLastRow() - 1, 1).getValues().some(r => r[0] === id);
}

function out_(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}
