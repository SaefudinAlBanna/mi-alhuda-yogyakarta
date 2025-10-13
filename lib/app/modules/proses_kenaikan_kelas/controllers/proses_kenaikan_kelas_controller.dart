import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/kenaikan_siswa_model.dart';
import '../../../models/tagihan_model.dart';
import '../../../routes/app_pages.dart';

class ProsesKenaikanKelasController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State UI
  final isLoading = true.obs;
  final isProcessing = false.obs;

  // State Data
  final RxMap<String, List<KenaikanSiswaModel>> siswaPerKelas = <String, List<KenaikanSiswaModel>>{}.obs;
  final RxList<Map<String, String>> pilihanKelasBaru = <Map<String, String>>[].obs;

  String get tahunAjaranLama => configC.tahunAjaranAktif.value;

  @override
  void onInit() {
    super.onInit();
    // Pemicu fetch data hanya jika ConfigController sudah authenticated
    ever(configC.status, (AppStatus status) {
      if (status == AppStatus.authenticated && isLoading.value) {
        _initializeData();
      }
    });
    // Jika sudah authenticated saat onInit dipanggil, jalankan langsung
    if (configC.status.value == AppStatus.authenticated) {
      _initializeData();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    try {
      await _generatePilihanKelasBaru();
      await _fetchSiswaUntukKenaikan();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data siswa: ${e.toString()}");
      print("[ProsesKenaikanKelasController] Error initializing data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _generatePilihanKelasBaru() async {
    final masterKelasSnap = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('master_kelas').orderBy('urutan').get();
    
    final tahun = int.parse(tahunAjaranLama.split('-').first);
    final tahunAjaranBaru = "${tahun + 1}-${tahun + 2}";

    pilihanKelasBaru.add({'id': 'LULUS', 'nama': 'Lulus'});
    for (var doc in masterKelasSnap.docs) {
      final nama = doc.data()['namaKelas'];
      pilihanKelasBaru.add({'id': '$nama-$tahunAjaranBaru', 'nama': 'Naik ke $nama'});
    }
  }

  Future<void> _fetchSiswaUntukKenaikan() async {
    final siswaSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').where('kelasId', isNull: false).get();

    final Map<String, List<KenaikanSiswaModel>> tempMap = {};

    for (var doc in siswaSnapshot.docs) {
      final data = doc.data();
      final kelasId = data['kelasId'] as String?;
      if (kelasId != null && kelasId.contains(tahunAjaranLama)) {
        final kelasNama = kelasId.split('-').first;
        if (tempMap[kelasNama] == null) tempMap[kelasNama] = [];
        
        final tingkatKelas = int.tryParse(kelasNama.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        String statusDefault = 'Naik';
        String? targetDefault = pilihanKelasBaru.firstWhereOrNull((p) => p['nama'] == 'Naik ke ${tingkatKelas + 1}${kelasNama.replaceAll(RegExp(r'[0-9]'), '')}')?['id'];

        if (tingkatKelas >= 6) { // Asumsi kelas 6 adalah kelas akhir
          statusDefault = 'Lulus';
          targetDefault = 'LULUS';
        }

        tempMap[kelasNama]!.add(KenaikanSiswaModel(
          uid: doc.id,
          nama: data['namaLengkap'],
          nisn: data['nisn'], // Tambahkan nisn
          kelasAsalId: kelasId,
          kelasAsalNama: kelasNama,
          status: statusDefault,
          targetKelasId: targetDefault,
        ));
      }
    }
    siswaPerKelas.value = tempMap;
  }

  void updateStatusSiswa(String uid, String kelasAsal, String newTargetId) {
    final siswa = siswaPerKelas[kelasAsal]?.firstWhere((s) => s.uid == uid);
    if (siswa != null) {
      if (newTargetId == siswa.kelasAsalId) {
        siswa.status = 'Tinggal';
      } else if (newTargetId == 'LULUS') {
        siswa.status = 'Lulus';
      } else {
        siswa.status = 'Naik';
      }
      siswa.targetKelasId = newTargetId;
      siswaPerKelas.refresh();
    }
  }

  void updateStatusSatuKelas(String kelasAsal, String newTargetId) {
    siswaPerKelas[kelasAsal]?.forEach((siswa) {
      updateStatusSiswa(siswa.uid, kelasAsal, newTargetId);
    });
  }

  void konfirmasiDanJalankanProses() {
    Get.defaultDialog(
      title: "Konfirmasi Akhir",
      middleText: "Ini adalah langkah final. Proses ini akan menutup tahun ajaran lama dan memindahkan semua siswa ke status baru. Anda yakin ingin melanjutkan?",
      textConfirm: "Ya, Jalankan Proses",
      confirmTextColor: Colors.white,
      onConfirm: _jalankanProsesKenaikan,
    );
  }

  Future<void> _jalankanProsesKenaikan() async {
    isProcessing.value = true;
    Get.back(); // Tutup dialog konfirmasi
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      final tahun = int.parse(tahunAjaranLama.split('-').first);
      final tahunAjaranBaruId = "${tahun + 1}-${tahun + 2}";
      
      WriteBatch batch = _firestore.batch();
      
      // 1. Buat Tahun Ajaran Baru (Jika belum ada)
      final tahunAjaranBaruRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranBaruId);
      batch.set(tahunAjaranBaruRef, {'isAktif': true, 'semesterAktif': '1'}, SetOptions(merge: true));

      // 2. Buat dokumen kelas & kelastahunajaran baru
      final Set<String> kelasBaruDiProses = {}; // Untuk melacak kelas yang akan dibuat/diperbarui
      siswaPerKelas.forEach((kelasAsalNama, daftarSiswa) {
        for (var siswa in daftarSiswa) {
          if (siswa.status != 'Lulus' && siswa.targetKelasId != null && !kelasBaruDiProses.contains(siswa.targetKelasId!)) {
            final idKelasBaru = siswa.targetKelasId!;
            final namaKelas = idKelasBaru.split('-').first;
            final fase = _getFaseFromNamaKelas(namaKelas);

            // Dokumen kelas level Sekolah/{idSekolah}/kelas/
            batch.set(_firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').doc(idKelasBaru), {
              'namaKelas': namaKelas, 'fase': fase, 'tahunAjaran': tahunAjaranBaruId, 'siswaUids': FieldValue.arrayUnion([]) // Initialize as empty array
            }, SetOptions(merge: true)); // Use merge:true in case it already exists (e.g. from previous student's processing)

            // Dokumen kelas level Sekolah/{idSekolah}/tahunajaran/{tahunAjaranBaruId}/kelastahunajaran/
            batch.set(_firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranBaruId).collection('kelastahunajaran').doc(idKelasBaru), {
              'namaKelas': namaKelas,
            }, SetOptions(merge: true));
            kelasBaruDiProses.add(idKelasBaru);
          }
        }
      });


      // 3. Proses setiap siswa
      siswaPerKelas.forEach((kelasAsal, daftarSiswa) {
        for (var siswa in daftarSiswa) {
          final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
          
          if (siswa.status == 'Lulus') {
            batch.update(siswaRef, {
              'statusSiswa': 'Lulus', 
              'kelasId': null,
              'tahunLulus': tahunAjaranLama, // [PERBAIKAN] Tambahkan tahun lulus
            });
          } else { // Naik atau Tinggal Kelas
            batch.update(siswaRef, {
              'kelasId': siswa.targetKelasId, 
              'statusSiswa': 'Aktif'
            });
            
            // Tambahkan ke daftar siswa di /kelas/{kelasBaru}
            final kelasBaruRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').doc(siswa.targetKelasId!);
            batch.update(kelasBaruRef, {'siswaUids': FieldValue.arrayUnion([siswa.uid])});

            // [PERBAIKAN KRUSIAL] Tambahkan siswa ke kelastahunajaran/{kelasBaruId}/daftarsiswa/{siswa.uid}
            final daftarSiswaKelasBaruRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
                .collection('tahunajaran').doc(tahunAjaranBaruId)
                .collection('kelastahunajaran').doc(siswa.targetKelasId!)
                .collection('daftarsiswa').doc(siswa.uid);
            batch.set(daftarSiswaKelasBaruRef, {
              'uid': siswa.uid,
              'nisn': siswa.nisn, // Menggunakan nisn dari model
              'namaLengkap': siswa.nama,
              'kelasId': siswa.targetKelasId, // Referensi ke kelas baru
              // Tambahkan data lain yang relevan seperti nama, dll.
            });
          }
        }
      });
      
      // 4. Tutup Tahun Ajaran Lama
      final tahunAjaranLamaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
                                .collection('tahunajaran').doc(tahunAjaranLama);

      batch.update(tahunAjaranLamaRef, {'isAktif': false, 'status': 'ditutup'});

      // [LANGKAH INTEGRASI BARU]
      // 5. Proses dan Pindahkan Tunggakan Keuangan
      await _prosesTunggakanKeuangan(batch, tahunAjaranLama, tahunAjaranBaruId);

      // 6. Jalankan semua operasi secara atomik
      await batch.commit();

      Get.back(); // Tutup loading
      Get.defaultDialog(
        title: "Proses Selesai!",
        middleText: "Tahun ajaran $tahunAjaranLama berhasil ditutup. Siswa dan data tunggakan keuangan telah dipindahkan ke tahun ajaran $tahunAjaranBaruId. Aplikasi akan me-refresh data.",
        textConfirm: "OK",
        onConfirm: () => Get.offAllNamed(AppPages.INITIAL),
        barrierDismissible: false,
      );

    } catch (e) {
      Get.back();
      Get.snackbar("PROSES GAGAL!", "Terjadi kesalahan kritis: ${e.toString()}. Segera hubungi administrator.", duration: const Duration(seconds: 10), backgroundColor: Colors.red, colorText: Colors.white);
      print("[ProsesKenaikanKelasController] CRITICAL ERROR during class promotion: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _prosesTunggakanKeuangan(WriteBatch batch, String taLama, String taBaru) async {
    // Cari semua tagihan di semua siswa dari tahun ajaran lama yang belum lunas
    final tunggakanSnap = await _firestore.collectionGroup('tagihan')
        .where('idTahunAjaran', isEqualTo: taLama)
        .where('status', isNotEqualTo: 'Lunas')
        .get();

    if (tunggakanSnap.docs.isEmpty) {
      print("Tidak ada tunggakan keuangan yang perlu dipindahkan.");
      return; // Tidak ada yang perlu dilakukan
    }

    for (var doc in tunggakanSnap.docs) {
      final tagihanLama = TagihanModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      
      // Path untuk tagihan baru di tahun ajaran baru
      final refTagihanBaru = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taBaru)
          .collection('keuangan_siswa').doc(tagihanLama.metadata['idSiswa']) // Ambil idSiswa dari data
          .collection('tagihan').doc("TUNGGAKAN-${tagihanLama.id}"); // Buat ID unik

      // Siapkan data untuk tagihan baru
      final dataTagihanBaru = {
        'jenisPembayaran': tagihanLama.jenisPembayaran,
        'deskripsi': "Tunggakan ${tagihanLama.deskripsi}", // Tambahkan prefix "Tunggakan"
        'jumlahTagihan': tagihanLama.sisaTagihan, // Tagihan baru sebesar sisa yang belum dibayar
        'jumlahTerbayar': 0,
        'status': 'Belum Lunas',
        'tanggalTerbit': Timestamp.now(),
        'tanggalJatuhTempo': tagihanLama.tanggalJatuhTempo, // Bawa tanggal jatuh tempo lama
        'metadata': tagihanLama.metadata,
        'idTahunAjaran': taBaru, // Set ke tahun ajaran baru
        'isTunggakan': true, // <-- TANDAI SEBAGAI TUNGGAKAN
        'idSiswa': tagihanLama.metadata['idSiswa'],
        'namaSiswa': tagihanLama.metadata['namaSiswa'],
        'kelasSaatDitagih': tagihanLama.metadata['kelasSaatDitagih'],
      };
      
      batch.set(refTagihanBaru, dataTagihanBaru);
    }
    print("Memproses ${tunggakanSnap.docs.length} tagihan tunggakan untuk dipindahkan ke tahun ajaran baru.");
  }

  String _getFaseFromNamaKelas(String namaKelas) {
    if (namaKelas.startsWith('1') || namaKelas.startsWith('2')) return "Fase A";
    if (namaKelas.startsWith('3') || namaKelas.startsWith('4')) return "Fase B";
    if (namaKelas.startsWith('5') || namaKelas.startsWith('6')) return "Fase C";
    return "Fase Tidak Diketahui";
  }
}