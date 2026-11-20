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

## C. Kode undangan (link pribadi)

Dengan `WAJIB_KODE = true` (di `Code.gs` dan `index.html`), kuesioner hanya bisa diisi lewat link pribadi seperti `https://khlaaz.github.io/kuesioner/#K7F2QX`. Tiap kode hanya bisa dipakai sekali untuk mengirim jawaban. Kegunaannya:

- Mahasiswa yang terpilih secara acak tidak bisa meneruskan link ke orang lain, jadi sampel tetap acak.
- Kiriman iseng atau bot ditolak.
- Tingkat respons per strata bisa dihitung, dan pengingat bisa dikirim hanya ke yang belum mengisi.

Cara membuat kode:

11. Buka ulang Google Sheet. Akan muncul menu **Kuesioner** (kalau belum muncul, muat ulang halaman). Saat pertama dipakai, Google meminta izin lagi.
12. **Kuesioner → Buat kode undangan…**, lalu isi nama strata (misalnya `Sosiologi`) dan jumlah kode (= jumlah sampel strata itu). Ulangi untuk tiap departemen. Buat juga beberapa kode berstrata `uji` dan `pilot`.
13. Tab `undangan` berisi kolom `kode`, `strata`, `link`, `status`, `tanggal`. Pasangkan tiap link dengan satu mahasiswa terpilih **di file daftar kirim terpisah** milik peneliti (misalnya untuk mail merge), bukan di Sheet ini.
14. Kolom `status` terisi otomatis: kosong (belum dibuka/mengisi), `tolak`, `kriteria`, atau `selesai`. Yang masih kosong bisa dikirimi pengingat.

**Kenapa kode tidak bisa dicocokkan ke jawaban:** baris di tab `jawaban` tidak menyimpan kode, dan tab `undangan` hanya mencatat tanggal (tanpa jam). Jadi daftar kirim berisi nama mahasiswa tidak bisa dipakai untuk melihat jawaban seseorang. Dengan begitu kuesioner tetap anonim bagi peneliti, sesuai teks persetujuan.

Kalau terpaksa beralih ke quota sampling (kerangka sampel tidak didapat), set `WAJIB_KODE` jadi `false` di kedua file, lalu deploy ulang Apps Script sebagai versi baru.

## D. Uji sebelum disebar

15. Buat satu kode berstrata `uji`, lalu buka `https://khlaaz.github.io/kuesioner/#uji-KODEUJI`. Akhiran `uji-` memunculkan tombol "Isi acak" dan kode variabel. Jawaban dari mode ini tetap terkirim, tapi ditandai `gelombang = uji`.
16. Klik **Isi acak (uji)**, lalu **Kirim**. Cek Sheet: tab `jawaban` berisi satu baris baru, dan status kode uji berubah jadi `selesai`. Kalau mengisi wawancara "Ya", tab `kontak` juga terisi.
17. Coba buka lagi link kode yang sama: harus muncul "Anda sudah mengisi". Coba juga link tanpa kode: harus muncul "Link belum lengkap".
18. Hapus baris `uji` di tab `jawaban` sebelum piloting. Responden menerima link **tanpa** `uji-`.

## Struktur data di Sheet

| Tab | Isi |
| --- | --- |
| `jawaban` | Satu baris per responden yang selesai. Kolom memakai nama variabel codebook (`mrni01`–`mrni21`, `mfq01`–`mfq30`, `aset01`–`aset11`, dst.) dan `durasi_detik`. |
| `status` | Yang berhenti di awal: `tolak` (tidak setuju) atau `kriteria` (bukan mahasiswa laki-laki S1 aktif). Berguna untuk menghitung tingkat respons. |
| `kontak` | Kontak wawancara, terpisah dari jawaban, dihubungkan lewat `resp_id`. |
| `undangan` | Kode undangan per strata, link pribadi, status, dan tanggal dipakai. |

Kode khusus: `97` = tidak ingin menjawab (MRNI-SF), `98` = tidak tahu, `99` = tidak berlaku.

Ke Stata: buka tab `jawaban`, **File → Download → CSV**, simpan sebagai `jawaban.csv` di folder yang sama dengan `stata/siapkan_data.do`, lalu jalankan `do siapkan_data.do`. Do-file itu membuang baris uji, mengubah 97/98/99 jadi missing berjenis (`.a`/`.b`/`.c`), memberi label nilai dan variabel, menghitung skor subskala MRNI-SF dan MFQ-FF, alfa Cronbach, indeks aset (PCA), lalu menyimpan `kuesioner_bersih.dta`. Bagian indeks aset dan pendidikan pengasuh masih draf.

## Catatan

- **Mengubah `Code.gs` setelah deploy:** pilih **Terapkan → Kelola deployment → Edit (ikon pensil) → Versi: Versi baru**. URL tetap sama. Kalau hanya disimpan, perubahan tidak berlaku.
- **Mengubah `index.html`:** edit langsung di GitHub. Halaman ikut berubah dalam 1–2 menit.
- **Semua sel disimpan sebagai teks** (format `@`), supaya Sheets tidak mengubah kode undangan atau waktu menjadi angka/tanggal. Stata tetap membacanya sebagai angka saat impor CSV.
- **Repo publik hanya berisi kode.** Data responden ada di Google Sheet pribadi. Jangan pernah mengunggah data ke repo.
- **Token terlihat di kode halaman.** Fungsinya hanya menyaring kiriman iseng, bukan pengaman data. Penyaring yang sebenarnya adalah kode undangan.
- **Tidak ada endpoint yang mengembalikan isi Sheet.** Orang yang tahu URL Apps Script hanya bisa menambah baris (dengan kode yang sah) atau mengecek apakah sebuah kode valid.
- **Kirim ulang aman.** Kalau koneksi responden putus, jawaban tetap tersimpan di perangkatnya dan bisa dikirim lagi. Baris ganda dengan `resp_id` yang sama tidak akan tercatat dua kali.
- **Kode responden** ditampilkan di akhir kuesioner, supaya responden bisa meminta jawabannya ditarik.
