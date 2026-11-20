# Kuesioner skripsi: cara online-kan

Halaman kuesioner (`index.html`) di-hosting gratis di GitHub Pages. Jawaban dikirim ke Google Sheet milik peneliti lewat Apps Script (`apps-script/Code.gs`). Total waktu setup sekitar 15 menit.

## A. Google Sheet + Apps Script (penerima jawaban)

1. Buat Google Sheet baru, misalnya **Data Kuesioner Skripsi**.
2. Di Sheet itu: **Ekstensi → Apps Script**. Hapus isi `Code.gs`, lalu tempel isi file `apps-script/Code.gs`.
3. Ganti `TOKEN` dengan kata acak, misalnya `maskulinitas-ugm-7392`. Simpan.
4. **Terapkan (Deploy) → Deployment baru**, lalu pilih jenis **Aplikasi web**:
   - Jalankan sebagai: **Saya**
   - Yang memiliki akses: **Siapa saja**
5. Klik Terapkan, lalu izinkan akses. Akan muncul peringatan "Google belum memverifikasi aplikasi ini". Itu normal untuk script buatan sendiri: pilih **Lanjutan → Buka (tidak aman)**.
6. Salin **URL aplikasi web** (berakhiran `/exec`). Buka di browser: kalau muncul `{"ok":true,"info":"Endpoint kuesioner aktif"}`, berarti sudah jalan.

## B. Halaman kuesioner (GitHub Pages)

7. Buka `index.html`, cari bagian `PENGATURAN`, lalu isi:
   - `ENDPOINT`: URL dari langkah 6
   - `TOKEN`: kata yang sama dengan langkah 3
   - `GELOMBANG`: `'pilot'` untuk uji coba, ganti `'utama'` saat pengumpulan data
8. Di GitHub, buat repo **publik** baru (misalnya `kuesioner`), lalu **Add file → Upload files** dan unggah `index.html`.
9. **Settings → Pages → Build and deployment**: Source **Deploy from a branch**, branch **main**, folder **/(root)**. Simpan.
10. Tunggu 1–2 menit. Link kuesioner: `https://<username>.github.io/kuesioner/`

## C. Uji sebelum disebar

11. Buka `https://<username>.github.io/kuesioner/#uji`. Akhiran `#uji` memunculkan tombol "Isi acak" dan kode variabel. Jawaban dari mode uji tetap terkirim, tapi ditandai `gelombang = uji`.
12. Klik **Isi acak (uji)**, lalu **Kirim**. Cek Sheet: tab `jawaban` harus berisi satu baris baru. Kalau mengisi wawancara "Ya", tab `kontak` juga terisi.
13. Hapus baris `uji` sebelum piloting. Sebar link **tanpa** `#uji` ke responden.

## Struktur data di Sheet

| Tab | Isi |
| --- | --- |
| `jawaban` | Satu baris per responden yang selesai. Kolom memakai nama variabel codebook (`mrni01`–`mrni21`, `mfq01`–`mfq30`, `aset01`–`aset11`, dst.) dan `durasi_detik`. |
| `status` | Yang berhenti di awal: `tolak` (tidak setuju) atau `kriteria` (bukan mahasiswa laki-laki S1 aktif). Berguna untuk menghitung tingkat respons. |
| `kontak` | Kontak wawancara, terpisah dari jawaban, dihubungkan lewat `resp_id`. |

Kode khusus: `97` = tidak ingin menjawab (MRNI-SF), `98` = tidak tahu, `99` = tidak berlaku.

Ke Stata: **File → Download → CSV** dari tab `jawaban`, lalu:

```stata
import delimited "jawaban.csv", clear
mvdecode mrni*, mv(97=.a)
mvdecode aset* listrik pend_*, mv(98=.b \ 99=.c)
```

## Catatan

- **Mengubah `Code.gs` setelah deploy:** pilih **Terapkan → Kelola deployment → Edit (ikon pensil) → Versi: Versi baru**. URL tetap sama. Kalau hanya disimpan, perubahan tidak berlaku.
- **Mengubah `index.html`:** edit langsung di GitHub. Halaman ikut berubah dalam 1–2 menit.
- **Repo publik hanya berisi kode.** Data responden ada di Google Sheet pribadi. Jangan pernah mengunggah data ke repo.
- **Token terlihat di kode halaman.** Fungsinya hanya menyaring kiriman iseng, bukan pengaman data.
- **Kirim ulang aman.** Kalau koneksi responden putus, jawaban tetap tersimpan di perangkatnya dan bisa dikirim lagi. Baris ganda dengan `resp_id` yang sama tidak akan tercatat dua kali.
- **Kode responden** ditampilkan di akhir kuesioner, supaya responden bisa meminta jawabannya ditarik.
