// lib/app/modules/jurnal_harian_guru/controllers/jurnal_harian_guru_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/jadwal_tugas_item_model.dart';

class JurnalHarianGuruController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxList<JadwalTugasItem> daftarTugasHariIni = <JadwalTugasItem>[].obs;
  
  final TextEditingController materiC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final RxList<JadwalTugasItem> tugasTerpilih = <JadwalTugasItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTugasHarian();
  }

  Future<void> loadTugasHarian() async {
    isLoading.value = true;
    daftarTugasHariIni.clear(); // Selalu kosongkan daftar di awal untuk refresh yang bersih
    try {
      final uid = authC.auth.currentUser!.uid;
      final idSekolah = configC.idSekolah;
      final tahunAjaran = configC.tahunAjaranAktif.value;
      
      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        isLoading.value = false;
        return;
      }
  
      final now = DateTime.now();
      final tanggalStr = DateFormat('yyyy-MM-dd').format(now);
      final namaHari = DateFormat('EEEE', 'id_ID').format(now);
  
      // [LANGKAH 1: QUERY AMAN & SPESIFIK]
      // Menjalankan semua query yang dibutuhkan secara paralel untuk efisiensi.
      final results = await Future.wait([
        // [0] Sesi pengganti insidental HARI INI
        _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(tahunAjaran)
                  .collection('sesi_pengganti_kbm').where('tanggal', isEqualTo: tanggalStr).get(),
        // [1] Jurnal yang sudah terisi HARI INI
        _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(tahunAjaran)
                  .collection('jurnal').where('tanggal', isEqualTo: tanggalStr).get(),
        // [2] SEMUA jadwal kelas untuk tahun ajaran aktif
        _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(tahunAjaran)
                  .collection('jadwalkelas').get(),
        // [3] Mandat di mana SAYA adalah GURU PENGGANTI (Query Aman)
        _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(tahunAjaran)
                  .collection('penggantianAkademik').where('idGuruPengganti', isEqualTo: uid)
                  .where('status', isEqualTo: 'aktif').get(),
        // [4] Mandat di mana SAYA adalah GURU ASLI (Query Aman)
        _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(tahunAjaran)
                  .collection('penggantianAkademik').where('idGuruAsli', isEqualTo: uid)
                  .where('status', isEqualTo: 'aktif').get(),
      ]);
  
      // Unpack hasil query
      final sesiPenggantiSnap = results[0] as QuerySnapshot;
      final jurnalSnap = results[1] as QuerySnapshot;
      final semuaJadwalKelasSnap = results[2] as QuerySnapshot;
      final penggantianSebagaiPenggantiSnap = results[3] as QuerySnapshot;
      final penggantianSebagaiGuruAsliSnap = results[4] as QuerySnapshot;
      
      // [LANGKAH 2: MEMBUAT PETA CONTEKAN]
      // Peta ini akan digunakan untuk memeriksa status setiap sesi dengan cepat.
      
      final Map<String, Map<String, dynamic>> jurnalTerisiMap = {};
      for (var doc in jurnalSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['idKelas'] != null && data['jamKe'] != null) {
          jurnalTerisiMap["${data['idKelas']}_${data['jamKe']}"] = data;
        }
      }
  
      final Map<String, Map<String, dynamic>> sesiPenggantiMap = {};
      for (var doc in sesiPenggantiSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['idKelas'] != null && data['jamKe'] != null) {
          sesiPenggantiMap["${data['idKelas']}_${data['jamKe']}"] = data;
        }
      }
  
      // Peta Pengganti Rentang Waktu
      final Map<String, Map<String, dynamic>> petaPenggantiRentang = {};
      final allPenggantianRentang = [...penggantianSebagaiPenggantiSnap.docs, ...penggantianSebagaiGuruAsliSnap.docs];
  
      for (var doc in allPenggantianRentang) {
        final data = doc.data() as Map<String, dynamic>;
        final tanggalMulai = (data['tanggalMulai'] as Timestamp).toDate();
        final tanggalSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
        // Periksa apakah 'hari ini' berada dalam rentang tanggal mandat
        if ((now.isAfter(tanggalMulai) || now.isAtSameMomentAs(tanggalMulai)) && 
            (now.isBefore(tanggalSelesai) || now.isAtSameMomentAs(tanggalSelesai))) {
          petaPenggantiRentang[data['idGuruAsli']] = data;
        }
      }
      
      // [LANGKAH 3: PEMROSESAN LOGIKA UTAMA]
      // Iterasi melalui semua jadwal dan terapkan aturan untuk setiap sesi.
      
      final List<JadwalTugasItem> tugasDitemukan = [];
  
      for (var doc in semuaJadwalKelasSnap.docs) {
        final idKelas = doc.id;
        final jadwalData = doc.data() as Map<String, dynamic>?;
  
        if (jadwalData != null) {
          final listSlot = (jadwalData[namaHari] ?? jadwalData[namaHari.toLowerCase()]) as List? ?? [];
          for (var slot in listSlot) {
            if (slot is Map<String, dynamic>) {
              final String sesiKey = "${idKelas}_${slot['jam']}";
              final String? idGuruAsliSlot = slot['idGuru'] as String?;
  
              if (idGuruAsliSlot == null) continue; // Lewati jika tidak ada guru asli di jadwal
  
              final Map<String, dynamic>? penggantiInsidental = sesiPenggantiMap[sesiKey];
              final Map<String, dynamic>? penggantiRentang = petaPenggantiRentang[idGuruAsliSlot];
  
              // SKENARIO 1: SAYA ADALAH GURU PENGGANTI UNTUK SESI INI
              if ((penggantiInsidental != null && penggantiInsidental['idGuruPengganti'] == uid) ||
                  (penggantiRentang != null && penggantiRentang['idGuruPengganti'] == uid)) {
                  
                final status = jurnalTerisiMap.containsKey(sesiKey) ? StatusJurnal.SudahDiisi : StatusJurnal.TugasPengganti;
                final namaPengganti = penggantiInsidental?['namaGuruPengganti'] ?? penggantiRentang?['namaGuruPengganti'] ?? 'Pengganti';
                
                tugasDitemukan.add(JadwalTugasItem(
                  jamKe: slot['jam'] ?? 'N/A',
                  idMapel: slot['idMapel'] ?? '',
                  namaMapel: slot['namaMapel'] ?? 'N/A',
                  idKelas: idKelas,
                  tingkatanKelas: idKelas.split('-').first,
                  idGuru: uid,
                  namaGuru: namaPengganti,
                  status: status,
                  materiDiisi: jurnalTerisiMap[sesiKey]?['materi'],
                  catatanDiisi: jurnalTerisiMap[sesiKey]?['catatan'],
                ));
              }
              // SKENARIO 2: SAYA ADALAH GURU ASLI DAN TIDAK ADA YANG MENGGANTIKAN SAYA
              else if (idGuruAsliSlot == uid && penggantiInsidental == null && penggantiRentang == null) {
                
                final status = jurnalTerisiMap.containsKey(sesiKey) ? StatusJurnal.SudahDiisi : StatusJurnal.BelumDiisi;
                
                tugasDitemukan.add(JadwalTugasItem(
                  jamKe: slot['jam'] ?? 'N/A',
                  idMapel: slot['idMapel'] ?? '',
                  namaMapel: slot['namaMapel'] ?? 'N/A',
                  idKelas: idKelas,
                  tingkatanKelas: idKelas.split('-').first,
                  idGuru: uid,
                  namaGuru: slot['namaGuru'] ?? 'N/A',
                  status: status,
                  materiDiisi: jurnalTerisiMap[sesiKey]?['materi'],
                  catatanDiisi: jurnalTerisiMap[sesiKey]?['catatan'],
                ));
              }
            }
          }
        }
      }
      
      // [LANGKAH 4: FINALISASI]
      // Urutkan dan tampilkan hasilnya.
      tugasDitemukan.sort((a, b) => a.jamKe.compareTo(b.jamKe));
      daftarTugasHariIni.assignAll(tugasDitemukan);
  
    } catch (e) {
      Get.snackbar("Error", "Gagal membangun dasbor jurnal: ${e.toString()}");
      print("### JURNAL ERROR ###\n$e");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleTugasSelection(JadwalTugasItem tugas) {
    if (tugasTerpilih.contains(tugas)) {
      tugasTerpilih.remove(tugas);
    } else {
      if (tugas.status == StatusJurnal.BelumDiisi) {
        tugasTerpilih.add(tugas);
      } else {
        Get.snackbar("Info", "Jurnal untuk tugas ini sudah diisi.");
      }
    }
  }

  void openJurnalDialog({JadwalTugasItem? targetTugas}) {
    final List<JadwalTugasItem> tugasUntukDiisi = (targetTugas != null) ? [targetTugas] : tugasTerpilih;
    if (tugasUntukDiisi.isEmpty) return;

    // --- [VALIDASI CERDAS] ---
    if (tugasUntukDiisi.length > 1) {
      final firstMapel = tugasUntukDiisi.first.idMapel;
      final firstTingkatan = tugasUntukDiisi.first.tingkatanKelas;
      
      if (!tugasUntukDiisi.every((t) => t.idMapel == firstMapel)) {
        Get.snackbar("Validasi Gagal", "Input massal hanya bisa untuk mata pelajaran yang sama."); return;
      }
      if (!tugasUntukDiisi.every((t) => t.tingkatanKelas == firstTingkatan)) {
        Get.snackbar("Validasi Gagal", "Input massal hanya bisa untuk tingkatan kelas yang sama (misal: semua kelas 1)."); return;
      }
    }

    final isSingleMode = tugasUntukDiisi.length == 1;
    materiC.text = isSingleMode ? (tugasUntukDiisi.first.materiDiisi ?? '') : '';
    catatanC.text = isSingleMode ? (tugasUntukDiisi.first.catatanDiisi ?? '') : '';

    Get.defaultDialog(
      title: isSingleMode ? "Input Jurnal" : "Input Jurnal Massal",
      content: Column(
        children: [
          TextField(controller: materiC, decoration: const InputDecoration(labelText: 'Materi yang Diajarkan')),
          if (isSingleMode) ...[
            const SizedBox(height: 16),
            TextField(controller: catatanC, decoration: const InputDecoration(labelText: 'Catatan (Opsional)')),
          ]
        ],
      ),
      confirm: ElevatedButton(onPressed: () => simpanJurnal(tugasUntukDiisi), child: const Text("Simpan")),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  Future<void> simpanJurnal(List<JadwalTugasItem> listTugas) async {
    if (materiC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Materi pelajaran wajib diisi."); return;
    }
    isSaving.value = true;
    Get.back(); // Tutup dialog
    try {
      final WriteBatch batch = _firestore.batch();
      final now = DateTime.now();
      final tanggalStr = DateFormat('yyyy-MM-dd').format(now);
      
      for (var tugas in listTugas) {
        final jurnalId = "$tanggalStr\_${tugas.idKelas}\_${tugas.jamKe}";
        final jurnalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('jurnal').doc(jurnalId);
        
        // --- [MODIFIKASI KUNCI] Fungsikan flag 'isPengganti' ---
        final bool adalahTugasPengganti = tugas.status == StatusJurnal.TugasPengganti;

        batch.set(jurnalRef, {
          'materi': materiC.text.trim(),
          'catatan': listTugas.length == 1 ? catatanC.text.trim() : '',
          'idGuru': tugas.idGuru, 'namaGuru': tugas.namaGuru,
          'jamKe': tugas.jamKe, 'idMapel': tugas.idMapel, 'namaMapel': tugas.namaMapel,
          'idKelas': tugas.idKelas,
          'tanggal': tanggalStr, 'timestamp': now,
          'isPengganti': adalahTugasPengganti, // <-- Di sini perubahannya
        });
      }
      await batch.commit();
      Get.snackbar("Berhasil", "Jurnal untuk ${listTugas.length} tugas berhasil disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
      
      // Gunakan manipulasi state lokal untuk UI reaktif, sama seperti di Misi 1.1
      for (var tugas in listTugas) {
        final index = daftarTugasHariIni.indexOf(tugas);
        if (index != -1) {
          // Asumsi model JadwalTugasItem punya copyWith
          // Jika belum, perlu ditambahkan
          // final updatedTugas = daftarTugasHariIni[index].copyWith(status: StatusJurnal.SudahDiisi, materiDiisi: materiC.text.trim(), ...);
          // daftarTugasHariIni[index] = updatedTugas;
        }
      }
      // Untuk sementara, muat ulang sederhana lebih aman sampai model diperbarui
      loadTugasHarian(); 
      tugasTerpilih.clear();
    } catch (e) { Get.snackbar("Gagal Menyimpan", "Terjadi kesalahan: ${e.toString()}"); } 
    finally { isSaving.value = false; }
  }

  @override
  void onClose() {
    materiC.dispose();
    catatanC.dispose();
    super.onClose();
  }
}