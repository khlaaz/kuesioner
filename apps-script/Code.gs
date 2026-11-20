/**
 * Penerima jawaban kuesioner skripsi.
 * Ditempel di Google Sheet: Ekstensi > Apps Script, lalu di-deploy sebagai Web App.
 *
 * Menulis ke tiga tab (dibuat otomatis kalau belum ada):
 *   jawaban : satu baris per responden yang selesai, kolom = nama variabel codebook
 *   status  : semua yang membuka kuesioner dan berhenti (tolak / tidak memenuhi kriteria)
 *   kontak  : kontak wawancara, terpisah dari jawaban, dihubungkan lewat resp_id
 */

// Harus sama persis dengan CONFIG.TOKEN di index.html.
// Ini hanya penyaring kiriman iseng/bot, bukan rahasia: token terlihat di kode halaman.
const TOKEN = 'ganti-dengan-kata-acak';

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    const p = JSON.parse(e.postData.contents);
    if (p.token !== TOKEN) return out_({ ok: false, err: 'token' });
    if (!p.data || !p.data.resp_id) return out_({ ok: false, err: 'data' });

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const meta = {
      diterima: new Date().toISOString(),
      versi: p.versi || '',
      gelombang: p.gelombang || '',
      status: p.status || ''
    };

    if (p.status === 'selesai') {
      // Kirim ulang dengan resp_id yang sama (mis. koneksi putus) tidak membuat baris ganda.
      if (!exists_(ss, 'jawaban', p.data.resp_id)) {
        append_(ss, 'jawaban', Object.assign(meta, p.data));
      }
      if (p.kontak && !exists_(ss, 'kontak', p.data.resp_id)) {
        append_(ss, 'kontak', { diterima: meta.diterima, resp_id: p.data.resp_id, kontak: String(p.kontak).slice(0, 200) });
      }
    } else {
      append_(ss, 'status', Object.assign(meta, p.data));
    }
    return out_({ ok: true });
  } catch (err) {
    return out_({ ok: false, err: String(err) });
  } finally {
    lock.releaseLock();
  }
}

// Membuka URL Web App di browser menampilkan ini: tanda endpoint sudah aktif.
function doGet() {
  return out_({ ok: true, info: 'Endpoint kuesioner aktif' });
}

function append_(ss, name, obj) {
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

function exists_(ss, name, id) {
  const sh = ss.getSheetByName(name);
  if (!sh || sh.getLastRow() < 2) return false;
  const head = sh.getRange(1, 1, 1, sh.getLastColumn()).getValues()[0];
  const c = head.indexOf('resp_id');
  if (c < 0) return false;
  const ids = sh.getRange(2, c + 1, sh.getLastRow() - 1, 1).getValues();
  return ids.some(r => r[0] === id);
}

function out_(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}
