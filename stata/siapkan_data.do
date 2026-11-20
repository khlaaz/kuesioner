* =====================================================================
* siapkan_data.do
* Impor dan rapikan data kuesioner skripsi (Ikhlas Marta Dharma, UGM)
*
* Cara pakai:
*   1. Di Google Sheet, buka tab "jawaban" > File > Download > CSV.
*   2. Simpan sebagai jawaban.csv di folder yang sama dengan do-file ini.
*   3. cd ke folder itu, lalu: do siapkan_data.do
*
* Hasil: kuesioner_bersih.dta (berlabel, kode khusus jadi missing,
*        skor subskala MRNI-SF dan MFQ-FF, indeks aset, alfa Cronbach).
* JANGAN commit file .csv/.dta ke repo GitHub (repo publik).
* =====================================================================

version 16
clear all
set more off

import delimited "jawaban.csv", varnames(1) encoding("utf-8") clear

* --- 1. Saring baris ------------------------------------------------------
drop if gelombang == "uji"             // kiriman dari mode uji
duplicates report resp_id               // harus 0 duplikat
* keep if gelombang == "utama"         // aktifkan saat analisis data utama

* --- 2. Waktu ------------------------------------------------------------
foreach v in diterima t_mulai t_selesai {
    capture confirm string variable `v'
    if !_rc {
        gen double `v'_tc = clock(subinstr(substr(`v', 1, 19), "T", " ", 1), "YMDhms")
        format `v'_tc %tc
        drop `v'
        rename `v'_tc `v'
    }
}
gen durasi_menit = durasi_detik / 60
label var durasi_menit "Durasi pengisian (menit)"

* --- 3. Kode khusus jadi missing berjenis -----------------------------------
*   .a = tidak ingin menjawab (97)   .b = tidak tahu (98)   .c = tidak berlaku (99)
mvdecode mrni*, mv(97 = .a)
mvdecode pend_ayah pend_ibu pend_wali aset* listrik, mv(98 = .b \ 99 = .c)

* --- 4. Label nilai --------------------------------------------------------
label define yn       0 "Tidak" 1 "Ya"
label define jk       1 "Laki-laki" 2 "Perempuan"
label define fak      1 "FISIPOL" 2 "Teknik" 9 "Fakultas lain (khusus pilot)"
label define dept     101 "Sosiologi" 102 "Ilmu Komunikasi" 103 "Ilmu Hubungan Internasional" ///
                      104 "Manajemen dan Kebijakan Publik" 105 "Politik dan Pemerintahan"     ///
                      106 "Pembangunan Sosial dan Kesejahteraan"                               ///
                      201 "Teknik Sipil dan Lingkungan" 202 "Teknik Arsitektur dan Perencanaan" ///
                      203 "Teknik Mesin dan Industri" 204 "Teknik Elektro dan Teknologi Informasi" ///
                      205 "Teknik Kimia" 206 "Teknik Geodesi" 207 "Teknik Geologi"              ///
                      208 "Teknik Nuklir dan Teknik Fisika"
label define prodi    1011 "Sosiologi" 1021 "Ilmu Komunikasi" 1031 "Ilmu Hubungan Internasional"      ///
                      1041 "Manajemen dan Kebijakan Publik" 1051 "Politik dan Pemerintahan"         ///
                      1061 "Pembangunan Sosial dan Kesejahteraan"                                    ///
                      2011 "Teknik Sipil" 2012 "Teknik Infrastruktur Lingkungan" 2013 "Teknik Sumber Daya Air" ///
                      2021 "Arsitektur" 2022 "Perencanaan Wilayah dan Kota"                         ///
                      2031 "Teknik Mesin" 2032 "Teknik Industri"                                     ///
                      2041 "Teknik Elektro" 2042 "Teknologi Informasi" 2043 "Teknik Biomedis"        ///
                      2051 "Teknik Kimia" 2061 "Teknik Geodesi" 2071 "Teknik Geologi"                ///
                      2081 "Teknik Nuklir" 2082 "Teknik Fisika"
label define angk     2019 "Sebelum 2020"
label define pend     1 "Tidak sekolah" 2 "SD" 3 "SMP" 4 "SMA/SMK" 5 "D1-D3" 6 "D4/S1" 7 "S2" 8 "S3" ///
                      .b "Tidak tahu" .c "Tidak berlaku"
label define asuh     1 "Ayah dan ibu" 2 "Ayah saja" 3 "Ibu saja" 4 "Wali"
label define hubwali  1 "Kakek/nenek" 2 "Paman/bibi" 3 "Kakak" 4 "Orang tua tiri" 5 "Lainnya"
label define aset     0 "Tidak" 1 "Ya" .b "Tidak tahu"
label define rumah    1 "Milik sendiri" 2 "Kontrak/sewa" 3 "Bebas sewa" 4 "Dinas" 5 "Lainnya"
label define lantai   1 "Keramik/marmer/granit" 2 "Ubin/tegel" 3 "Semen" 4 "Kayu/papan" 5 "Tanah" 6 "Lainnya"
label define air      1 "Kemasan/isi ulang" 2 "Ledeng" 3 "Sumur bor/pompa" 4 "Sumur terlindung" 5 "Lainnya"
label define listrik  1 "450 VA" 2 "900 VA" 3 "1.300 VA" 4 "2.200 VA" 5 ">2.200 VA" .b "Tidak tahu"
label define mrni     1 "Sangat tidak setuju" 2 "Tidak setuju" 3 "Setuju" 4 "Sangat setuju" ///
                      .a "Tidak ingin menjawab"
label define mfq      0 "Tidak pernah" 2 "Jarang" 4 "Kadang-kadang" 6 "Cukup sering" 8 "Selalu"
label define kenal    1 "Kampus" 2 "SMA/sekolah sebelumnya" 3 "Kos/lingkungan" 4 "Organisasi/komunitas" 5 "Lainnya"
label define frek     1 "Jarang" 2 "Beberapa kali sebulan" 3 "Sekali seminggu" 4 "Beberapa kali seminggu" 5 "Hampir setiap hari"

label values consent aktif teman teman_ugm wawancara yn
label values jk jk
label values fak fak
label values dept dept
label values prodi prodi
label values angkatan angk
label values pend_ayah pend_ibu pend_wali pend
label values pengasuh asuh
label values hub_wali hubwali
label values aset* aset
label values rumah rumah
label values lantai lantai
label values air air
label values listrik listrik
label values mrni* mrni
label values mfq* mfq
label values kenal kenal
label values frek frek

* --- 5. Label variabel -----------------------------------------------------
label var jk          "Jenis kelamin"
label var aktif       "Mahasiswa S1 aktif UGM"
label var usia        "Usia (tahun)"
label var fak         "Fakultas"
label var fak_lain    "Nama fakultas lain (khusus pilot)"
label var dept        "Departemen (strata sampling)"
label var prodi       "Program studi (otomatis bila departemen hanya punya satu prodi)"
label var angkatan    "Angkatan"
label var pend_ayah   "Pendidikan terakhir ayah"
label var pend_ibu    "Pendidikan terakhir ibu"
label var pengasuh    "Dibesarkan oleh"
label var hub_wali    "Hubungan dengan wali"
label var pend_wali   "Pendidikan terakhir wali"
label var teman       "Punya teman dekat laki-laki"
label var inisial     "Inisial teman yang dinilai"
label var kenal       "Tempat berkenalan dengan teman"
label var frek        "Frekuensi bertemu/berkomunikasi"
label var teman_ugm   "Teman adalah mahasiswa UGM"
label var wawancara   "Bersedia diwawancarai"
gen lama_teman = lama_teman_th + lama_teman_bl / 12
gen lama_dekat = lama_dekat_th + lama_dekat_bl / 12
label var lama_teman  "Lama berteman (tahun)"
label var lama_dekat  "Lama dianggap teman terdekat (tahun)"

local a 1 "Tabung gas >=5,5 kg" 2 "Kulkas" 3 "AC" 4 "Pemanas air" 5 "Komputer/laptop" ///
        6 "TV layar datar >=30 inci" 7 "Emas >=10 gram" 8 "Sepeda motor" 9 "Mobil" ///
        10 "Lahan lain" 11 "Rumah lain"
forvalues i = 1/11 {
    local nm : word `=2*`i'' of `a'
    label var aset`: display %02.0f `i'' "Aset: `nm'"
}

* Teks butir MRNI-SF (nomor asli Levant dkk., 2013) dan MFQ-FF (urutan kuesioner)
local m1  "RE Tidak boleh mengakui perasaan disakiti"
local m2  "RE Tidak terbawa perasaan saat situasi emosional"
local m3  "RE Tidak terlalu cepat menunjukkan kepedulian"
local m4  "SR Punya keterampilan pertukangan"
local m5  "SR Mampu memperbaiki barang di rumah"
local m6  "SR Tahu memperbaiki kendaraan sendiri"
local m7  "NT Kaum homoseksual tidak boleh menikah"
local m8  "NT Tidak ada tempat berkumpul khusus homoseksual"
local m9  "NT Kaum homoseksual tidak boleh berciuman di tempat umum"
local m10 "AF Menonton olahraga, bukan sinetron/drama"
local m11 "AF Film laga daripada novel romantis"
local m12 "AF Mobil-mobilan daripada boneka"
local m13 "IS Selalu suka berhubungan seks"
local m14 "IS Tidak menolak ajakan seks"
local m15 "IS Selalu siap berhubungan seks"
local m16 "Do Presiden Indonesia selalu laki-laki"
local m17 "Do Pemimpin dalam kelompok apa pun"
local m18 "Do Selalu menjadi pimpinan/atasan"
local m19 "T Berani mengambil risiko"
local m20 "T Lebih tangguh saat keadaan sulit"
local m21 "T Tangguh secara fisik"
forvalues i = 1/21 {
    label var mrni`: display %02.0f `i'' "MRNI `i' `m`i''"
}

* --- 6. Skor MRNI-SF --------------------------------------------------------
* Aturan (usulan, belum disepakati pembimbing): rerata butir terjawab,
* dihitung bila minimal 2 dari 3 butir terjawab (97 = missing).
local re mrni01 mrni02 mrni03
local sr mrni04 mrni05 mrni06
local nt mrni07 mrni08 mrni09
local af mrni10 mrni11 mrni12
local is mrni13 mrni14 mrni15
local do mrni16 mrni17 mrni18
local t  mrni19 mrni20 mrni21
foreach s in re sr nt af is do t {
    egen mrni_`s' = rowmean(``s'')
    egen n_`s'    = rownonmiss(``s'')
    replace mrni_`s' = . if n_`s' < 2
    drop n_`s'
}
label var mrni_re "MRNI Restrictive emotionality"
label var mrni_sr "MRNI Self-reliance (mechanical skills)"
label var mrni_nt "MRNI Negativity toward sexual minorities"
label var mrni_af "MRNI Avoidance of femininity"
label var mrni_is "MRNI Importance of sex"
label var mrni_do "MRNI Dominance"
label var mrni_t  "MRNI Toughness"
egen mrni_total = rowmean(mrni_re mrni_sr mrni_nt mrni_af mrni_is mrni_do mrni_t)
egen n_sub      = rownonmiss(mrni_re mrni_sr mrni_nt mrni_af mrni_is mrni_do mrni_t)
replace mrni_total = . if n_sub < 7
drop n_sub
label var mrni_total "MRNI-SF total (rerata 7 subskala)"
gen mrni_n97 = 0
forvalues i = 1/21 {
    replace mrni_n97 = mrni_n97 + (mrni`: display %02.0f `i'' == .a)
}
label var mrni_n97 "Jumlah butir MRNI dijawab 97"

* --- 7. Skor MFQ-FF (kunci: Appendix B, Mendelson dan Aboud, 1997) ----------
local help mfq01 mfq09 mfq13 mfq24 mfq27
local es   mfq02 mfq11 mfq14 mfq23 mfq30
local int  mfq03 mfq08 mfq15 mfq21 mfq29
local sc   mfq04 mfq07 mfq18 mfq22 mfq28
local ra   mfq05 mfq12 mfq16 mfq20 mfq26
local sv   mfq06 mfq10 mfq17 mfq19 mfq25
foreach s in help es int sc ra sv {
    egen mfq_`s' = rowmean(``s'') if teman == 1
}
label var mfq_help "MFQ Help"
label var mfq_es   "MFQ Emotional security"
label var mfq_int  "MFQ Intimacy"
label var mfq_sc   "MFQ Stimulating companionship"
label var mfq_ra   "MFQ Reliable alliance"
label var mfq_sv   "MFQ Self-validation"
egen mfq_total = rowmean(mfq01-mfq30) if teman == 1
label var mfq_total "MFQ-FF total (rerata 30 butir)"

* --- 8. Reliabilitas --------------------------------------------------------
foreach s in re sr nt af is do t {
    display as text _n "Alfa MRNI `s':"
    alpha ``s''
}
foreach s in help es int sc ra sv {
    display as text _n "Alfa MFQ `s':"
    alpha ``s''
}

* --- 9. Indeks aset (W) — DRAF, sesuaikan sebelum analisis ------------------
gen rumah_milik    = rumah == 1 if !missing(rumah)
gen lantai_keramik = lantai == 1 if !missing(lantai)
gen listrik_1300   = listrik >= 3 if !missing(listrik)
pca aset01-aset11 rumah_milik lantai_keramik listrik_1300, components(1)
predict indeks_aset, score
label var indeks_aset "Indeks aset rumah tangga (PCA komponen 1)"
xtile aset_tertil = indeks_aset, nq(3)
label define tertil 1 "Rendah" 2 "Menengah" 3 "Tinggi"
label values aset_tertil tertil
label var aset_tertil "Tertil indeks aset"

* --- 10. Pendidikan pengasuh (kontrol) — DRAF -------------------------------
* Usulan: pendidikan tertinggi di antara ayah dan ibu; pakai wali bila dibesarkan wali.
egen pend_pengasuh = rowmax(pend_ayah pend_ibu)
replace pend_pengasuh = pend_wali if pengasuh == 4 & !missing(pend_wali)
label values pend_pengasuh pend
label var pend_pengasuh "Pendidikan tertinggi pengasuh"

* --- Simpan ----------------------------------------------------------------
order resp_id gelombang versi status diterima t_mulai t_selesai durasi_detik durasi_menit
compress
save "kuesioner_bersih.dta", replace
display as result "Selesai: " _N " responden disimpan ke kuesioner_bersih.dta"
