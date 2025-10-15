// lib/app/modules/daftar_siswa_permapel/controllers/daftar_siswa_permapel_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/siswa_model.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';

class DaftarSiswaPermapelController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String idKelas, idMapel, namaMapel, idGuru, namaGuru;
  late bool isPengganti;

  final isLoading = true.obs;
  final isDialogLoading = false.obs;
  final RxList<SiswaModel> daftarSiswa = <SiswaModel>[].obs;
  
  final TextEditingController judulTugasC = TextEditingController();
  final TextEditingController deskripsiTugasC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    idKelas = args['idKelas'] ?? '';
    idMapel = args['idMapel'] ?? '';
    namaMapel = args['namaMapel'] ?? 'Mata Pelajaran';
    idGuru = args['idGuru'] ?? '';
    namaGuru = args['namaGuru'] ?? '';
    isPengganti = args['isPengganti'] ?? false;
    
    _fetchDaftarSiswa();
  }

  @override
  void onClose() {
    judulTugasC.dispose();
    deskripsiTugasC.dispose();
    super.onClose();
  }

  Future<void> _fetchDaftarSiswa() async {
    isLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        throw Exception("Tahun ajaran aktif tidak valid.");
      }
      
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa').orderBy('namaLengkap').get();

      final List<String> siswaUids = snapshot.docs.map((doc) => doc.id).toList();

      if (siswaUids.isNotEmpty) {
        final siswaDetailSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').where(FieldPath.documentId, whereIn: siswaUids).get();
        
        final allSiswa = siswaDetailSnap.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
        allSiswa.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));
        daftarSiswa.assignAll(allSiswa);
      } else {
        daftarSiswa.clear();
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar siswa: ${e.toString()}");
      print("[DaftarSiswaPermapelController] Error fetching students: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void goToInputNilaiSiswa(SiswaModel siswa) {
    Get.toNamed(
      Routes.INPUT_NILAI_SISWA,
      arguments: {
        'idKelas': idKelas,
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
        'namaGuru': namaGuru,
        'siswa': siswa,
      },
    );
  }

  void showBuatTugasDialog(BuildContext context) {
    judulTugasC.clear();
    deskripsiTugasC.clear();
    Get.defaultDialog(
      title: "Buat Tugas / Ulangan Baru",
      content: Column(
        children: [
          TextField(controller: judulTugasC, decoration: const InputDecoration(labelText: 'Judul (Contoh: PR Bab 1)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: deskripsiTugasC, decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)', border: OutlineInputBorder()), maxLines: 3),
        ],
      ),
      actions: [
        OutlinedButton(onPressed: isDialogLoading.value ? null : () => buatTugasBaru("Ulangan"), child: isDialogLoading.value ? const CircularProgressIndicator() : const Text("Simpan Ulangan")),
        ElevatedButton(onPressed: isDialogLoading.value ? null : () => buatTugasBaru("PR"), child: isDialogLoading.value ? const CircularProgressIndicator() : const Text("Simpan PR")),
      ],
    );
  }

  Future<void> buatTugasBaru(String kategori) async {
    if (judulTugasC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Judul tidak boleh kosong."); return;
    }
    isDialogLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final String semester = configC.semesterAktif.value;
      final WriteBatch batch = _firestore.batch();

      // 1. Buat Dokumen Tugas Baru
      final refTugas = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(semester)
        .collection('tugas_ulangan');

      final newTugasRef = refTugas.doc(); // Dapatkan referensi dokumen baru
      batch.set(newTugasRef, {
        'judul': judulTugasC.text.trim(),
        'kategori': kategori,
        'deskripsi': deskripsiTugasC.text.trim(),
        'tanggal_dibuat': Timestamp.now(),
        'status': 'diumumkan',
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
        'namaGuru': namaGuru,
      });

      // 2. Kirim Notifikasi & Inisialisasi Data Mapel Siswa
      final String judulNotif = (kategori == "PR") ? "PR Baru: $namaMapel" : "Ulangan Baru: $namaMapel";
      final String isiNotif = "Ananda mendapatkan tugas baru: '${judulTugasC.text.trim()}'.";

      for (var siswa in daftarSiswa) {
        // A. Inisialisasi data mata pelajaran untuk siswa
        final siswaMapelRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(tahunAjaran)
            .collection('kelastahunajaran').doc(idKelas)
            .collection('daftarsiswa').doc(siswa.uid)
            .collection('semester').doc(semester)
            .collection('matapelajaran').doc(idMapel);

        batch.set(siswaMapelRef, {
          'idMapel': idMapel,
          'namaMapel': namaMapel,
          'idGuru': idGuru,
          'namaGuru': namaGuru,
          'aliasGuruPencatatAkhir': configC.infoUser['alias'] ?? configC.infoUser['nama'],
        }, SetOptions(merge: true)); // <-- SANGAT PENTING MENGGUNAKAN MERGE

        // B. Tambahkan notifikasi
        final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        batch.set(siswaDocRef.collection('notifikasi').doc(), {
          'judul': judulNotif,
          'isi': isiNotif,
          'tipe': (kategori == "PR") ? 'TUGAS_BARU' : 'ULANGAN_BARU',
          'tanggal': FieldValue.serverTimestamp(),
          'isRead': false,
          'deepLink': '/akademik/tugas/${newTugasRef.id}',
        });

        final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
        batch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));
      }
      
      await batch.commit();
      
      Get.back();
      Get.snackbar("Berhasil", "$kategori baru telah dibuat dan notifikasi dikirim.");
    } catch(e) {
      Get.snackbar("Error", "Gagal membuat tugas: ${e.toString()}"); 
      print("[DaftarSiswaPermapelController] Error creating assignment: $e");
    } finally { 
      isDialogLoading.value = false; 
      judulTugasC.clear(); 
      deskripsiTugasC.clear(); 
    }
  }

  // [PERBAIKAN] Fungsi ini akan mengarahkan ke halaman baru manajemen tugas
  void goToManajemenTugas() {
    Get.toNamed(
      Routes.MANAJEMEN_TUGAS,
      arguments: {
        'idKelas': idKelas,
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
        'namaGuru': namaGuru,
        'daftarSiswa': daftarSiswa.toList(), // <-- [PERBAIKAN] Kirim daftar siswa
      },
    );
  }
}