// lib/app/modules/manajemen_tugas/controllers/manajemen_tugas_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/siswa_model.dart';
import '../../../models/tugas_model.dart';
import '../../../routes/app_pages.dart';

class ManajemenTugasController extends GetxController with GetSingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late String idKelas, idMapel, namaMapel, idGuru, namaGuru;
  late List<SiswaModel> daftarSiswa;
  late TabController tabController;
  late DocumentReference _semesterRef;

  final isLoading = true.obs;
  final isDialogLoading = false.obs;
  final RxList<TugasModel> daftarTugasPR = <TugasModel>[].obs;
  final RxList<TugasModel> daftarTugasUlangan = <TugasModel>[].obs;
  final TextEditingController judulC = TextEditingController();
  final TextEditingController deskripsiC = TextEditingController();
  final RxString kategoriTugas = "PR".obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    idKelas = args['idKelas'] ?? '';
    idMapel = args['idMapel'] ?? '';
    namaMapel = args['namaMapel'] ?? 'Mata Pelajaran';
    idGuru = args['idGuru'] ?? '';
    namaGuru = args['namaGuru'] ?? '';
    daftarSiswa = args['daftarSiswa'] ?? <SiswaModel>[];
    _semesterRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(configC.semesterAktif.value);
    fetchTugas();
  }

  @override
  void onClose() {
    tabController.dispose();
    judulC.dispose();
    deskripsiC.dispose();
    super.onClose();
  }

  Future<void> fetchTugas() async {
    isLoading.value = true;
    try {
      final snapshot = await _semesterRef
          .collection('tugas_ulangan')
          .where('idMapel', isEqualTo: idMapel)
          .orderBy('tanggal_dibuat', descending: true)
          .get();
      daftarTugasPR.clear();
      daftarTugasUlangan.clear();
      for (var doc in snapshot.docs) {
        final tugas = TugasModel.fromFirestore(doc);
        if (tugas.kategori == "PR") {
          daftarTugasPR.add(tugas);
        } else if (tugas.kategori == "Ulangan") {
          daftarTugasUlangan.add(tugas);
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar tugas: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void showBuatTugasDialog({String? kategori}) {
    isDialogLoading.value = false;
    judulC.clear();
    deskripsiC.clear();
    kategoriTugas.value = kategori ?? "PR";
    _showFormDialog(isEdit: false);
  }

  void showEditTugasDialog(TugasModel tugas) {
    isDialogLoading.value = false;
    judulC.text = tugas.judul;
    deskripsiC.text = tugas.deskripsi;
    kategoriTugas.value = tugas.kategori;
    _showFormDialog(isEdit: true, tugasId: tugas.id, judulTugasLama: tugas.judul);
  }

  void _showFormDialog({required bool isEdit, String? tugasId, String? judulTugasLama}) {
    Get.defaultDialog(
      title: isEdit ? "Edit Tugas" : "Buat Tugas Baru",
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: judulC, decoration: const InputDecoration(labelText: 'Judul Tugas', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: deskripsiC, decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)', border: OutlineInputBorder()), maxLines: 4),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
              value: kategoriTugas.value,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: ["PR", "Ulangan"].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) kategoriTugas.value = newValue;
              },
            )),
          ],
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isDialogLoading.value ? null : () {
          if (isEdit) {
            _updateTugas(tugasId!, judulTugasLama!);
          } else {
            _buatTugasBaruInternal();
          }
        },
        child: Text(isDialogLoading.value ? "Menyimpan..." : "Simpan"),
      )),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  Future<void> _buatTugasBaruInternal() async {
    if (judulC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Judul tidak boleh kosong.");
      return;
    }
    isDialogLoading.value = true;
    try {
      final WriteBatch batch = _firestore.batch();
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final String semester = configC.semesterAktif.value;
      final newTugasRef = _semesterRef.collection('tugas_ulangan').doc();
      batch.set(newTugasRef, {
        'judul': judulC.text.trim(), 'kategori': kategoriTugas.value,
        'deskripsi': deskripsiC.text.trim(), 'tanggal_dibuat': Timestamp.now(),
        'status': 'diumumkan', 'idMapel': idMapel, 'namaMapel': namaMapel,
        'idGuru': idGuru, 'namaGuru': namaGuru,
      });
      final String judulNotif = (kategoriTugas.value == "PR") ? "PR Baru: $namaMapel" : "Ulangan Baru: $namaMapel";
      final String isiNotif = "Ananda mendapatkan tugas baru: '${judulC.text.trim()}'.";
      for (var siswa in daftarSiswa) {
        final DocumentReference siswaMapelRef = _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(tahunAjaran)
            .collection('kelastahunajaran').doc(idKelas)
            .collection('daftarsiswa').doc(siswa.uid)
            .collection('semester').doc(semester)
            .collection('matapelajaran').doc(idMapel);
        batch.set(siswaMapelRef, {
          'idMapel': idMapel, 'namaMapel': namaMapel, 'idGuru': idGuru, 'namaGuru': namaGuru,
          'aliasGuruPencatatAkhir': configC.infoUser['alias'] ?? configC.infoUser['nama'],
        }, SetOptions(merge: true));
        final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        batch.set(siswaDocRef.collection('notifikasi').doc(), {
          'judul': judulNotif, 'isi': isiNotif,
          'tipe': (kategoriTugas.value == "PR") ? 'TUGAS_BARU' : 'ULANGAN_BARU',
          'tanggal': FieldValue.serverTimestamp(), 'isRead': false,
          'deepLink': '/akademik/tugas/${newTugasRef.id}',
          'idSekolah': configC.idSekolah,
        });
        final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
        batch.set(metaRef, {'unreadCount': FieldValue.increment(1), 'idSekolah': configC.idSekolah}, 
        SetOptions(merge: true));
      }
      await batch.commit();
      Get.back();
      await fetchTugas();
      Get.snackbar("Berhasil", "${kategoriTugas.value} baru telah dibuat.");
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat tugas: ${e.toString()}");
      print("### ERROR BUAT TUGAS BARU: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

  Future<void> _updateTugas(String tugasId, String judulTugasLama) async {
    if (judulC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Judul tidak boleh kosong.");
      return;
    }
    isDialogLoading.value = true;
    try {
      final WriteBatch batch = _firestore.batch();
      batch.update(_semesterRef.collection('tugas_ulangan').doc(tugasId), {
        'judul': judulC.text.trim(),
        'deskripsi': deskripsiC.text.trim(),
        'kategori': kategoriTugas.value,
      });
      final String judulNotif = "Tugas Diperbarui: $namaMapel";
      final String isiNotif = "Tugas '${judulTugasLama}' telah diperbarui menjadi '${judulC.text.trim()}'.";
      for (var siswa in daftarSiswa) {
        final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        batch.set(siswaDocRef.collection('notifikasi').doc(), {
          'judul': judulNotif, 'isi': isiNotif, 'tipe': 'TUGAS_UPDATE',
          'tanggal': FieldValue.serverTimestamp(), 'isRead': false,
          'deepLink': '/akademik/tugas/$tugasId',
          'idSekolah': configC.idSekolah,
        });
        final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
        batch.set(metaRef, {'unreadCount': FieldValue.increment(1), 'idSekolah': configC.idSekolah}, 
        SetOptions(merge: true));
      }
      await batch.commit();
      Get.back();
      await fetchTugas();
      Get.snackbar("Berhasil", "Tugas berhasil diperbarui.");
    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui tugas: ${e.toString()}");
    } finally {
      isDialogLoading.value = false;
    }
  }

  Future<void> confirmDeleteTugas(TugasModel tugas) async {
    isDialogLoading.value = true;
    try {
      final snapshot = await _firestore.collectionGroup('nilai_harian')
          .where('idSekolah', isEqualTo: configC.idSekolah)
          .where('idTugasUlangan', isEqualTo: tugas.id)
          .limit(1) // Query ini sangat efisien, hanya untuk memeriksa keberadaan
          .get();
          
      isDialogLoading.value = false;

      if (snapshot.docs.isEmpty) {
        // [ALUR BERHASIL] Tidak ada nilai terkait, tampilkan dialog konfirmasi hapus.
        Get.defaultDialog(
          title: "Hapus Tugas?",
          middleText: "Anda yakin ingin menghapus tugas '${tugas.judul}'? Aksi ini tidak dapat dibatalkan.",
          confirm: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _deleteTugasDanNilai(tugas, []), // Kirim list kosong
            child: const Text("Ya, Hapus"),
          ),
          cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
        );
      } else {
        // [SOLUSI SEMENTARA] Ada nilai terkait, tampilkan snackbar informatif dan jangan lakukan apa-apa.
        Get.snackbar(
          "Tidak Dapat Menghapus",
          "Tugas '${tugas.judul}' tidak dapat dihapus karena sudah ada nilai siswa yang diinput. Anda masih bisa mengedit tugas ini.",
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isDialogLoading.value = false;
      print("### ERROR CONFIRM DELETE: $e");
      // Jika query gagal (karena masalah rules yang masih ada), berikan pesan error yang jelas.
      Get.snackbar("Error", "Gagal memeriksa data nilai. Silakan coba lagi.",
        backgroundColor: Colors.red, colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteTugasDanNilai(TugasModel tugas, List<QueryDocumentSnapshot> nilaiDocs) async {
    // Fungsi ini sekarang HANYA akan terpanggil jika nilaiDocs kosong.
    Get.back(); // Tutup dialog konfirmasi
    isDialogLoading.value = true;
    try {
      final WriteBatch batch = _firestore.batch();
      
      // 1. Hapus dokumen tugas
      batch.delete(_semesterRef.collection('tugas_ulangan').doc(tugas.id));
      
      // Tidak perlu loop untuk nilaiDocs karena akan selalu kosong.
      // Tidak perlu kirim notifikasi karena tidak ada nilai yang dihapus.

      await batch.commit();
      await fetchTugas();
      Get.snackbar("Berhasil", "Tugas telah dihapus.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus tugas: ${e.toString()}");
    } finally {
      isDialogLoading.value = false;
    }
  }

  void goToInputNilaiMassal(TugasModel tugas) {
    Get.toNamed(
      Routes.INPUT_NILAI_MASSAL_AKADEMIK,
      arguments: {
        'idKelas': idKelas, 'idMapel': idMapel, 'namaMapel': namaMapel,
        'judulTugas': tugas.judul, 'kategoriTugas': tugas.kategori,
        'idTugasUlangan': tugas.id,
      },
    );
  }
}