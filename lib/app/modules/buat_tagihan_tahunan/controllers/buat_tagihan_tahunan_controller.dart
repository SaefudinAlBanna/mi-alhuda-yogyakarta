// lib/app/modules/buat_tagihan_tahunan/controllers/buat_tagihan_tahunan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/siswa_keuangan_model.dart';
import '../../../routes/app_pages.dart'; // [BARU] Import untuk navigasi

class BuatTagihanTahunanController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // State
  final isLoading = true.obs;
  final isProcessingSPP = false.obs;
  final isProcessingDU = false.obs;
  final isProcessingUK = false.obs;
  final isProcessingUP = false.obs;
  final isProcessingBuku = false.obs;

  // Variabel untuk melacak progres
  final RxString progressMessage = "".obs;

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

  // Data Master Biaya
  final RxMap<String, int> masterBiaya = <String, int>{}.obs;

  // [PEROMBAKAN UTAMA] Mengganti daftar statis kelas 1 dengan daftar dinamis
  // final RxList<SiswaKeuanganModel> daftarSiswaKelas1 = <SiswaKeuanganModel>[].obs; // <-- DIHAPUS
  final RxList<SiswaKeuanganModel> siswaUntukDitagihUP = <SiswaKeuanganModel>[].obs; // <-- DIGANTI DENGAN INI
  final RxMap<String, TextEditingController> uangPangkalControllers = <String, TextEditingController>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await _fetchMasterBiaya();
      // await _fetchSiswaKelas1(); // <-- DIHAPUS, tidak perlu lagi fetch otomatis
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchMasterBiaya() async {
    final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranAktif)
        .collection('pengaturan').doc('master_biaya');
    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        masterBiaya['daftarUlang'] = data['daftarUlang'] ?? 0;
        masterBiaya['uangKegiatan'] = data['uangKegiatan'] ?? 0;
        masterBiaya['uangPangkal'] = data['uangPangkal'] ?? 0; // Ini dipakai sebagai default
      }
    } catch (e) {
      Get.snackbar( "Peringatan", "Gagal memuat nominal biaya default.");
    }
  }

  // Future<void> _fetchSiswaKelas1() async { ... } // <-- FUNGSI INI DIHAPUS SELURUHNYA

  // [FUNGSI BARU] Untuk membuka halaman pencarian siswa
  Future<void> bukaPencarianSiswa() async {
    // 1. Dapatkan daftar siswa yang SUDAH punya tagihan UP
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('keuangan_sekolah').doc('tagihan_uang_pangkal')
        .collection('tagihan')
        .get();
    
    final Set<String> siswaSudahPunyaTagihan = snapshot.docs.map((doc) => doc.id).toSet();

    // 2. Kirim daftar pengecualian ini ke halaman pencarian
    // Kita akan memodifikasi CariSiswaKeuanganView untuk menerima argumen ini
    final result = await Get.toNamed(Routes.CARI_SISWA_KEUANGAN, arguments: {
      'mode': 'pilih', // Mode baru untuk memilih siswa
      'excludeUIDs': siswaSudahPunyaTagihan.toList(), // Daftar siswa yang disembunyikan
    });

    // 3. Tambahkan siswa yang dipilih ke dalam daftar tagihan
    if (result is SiswaKeuanganModel) {
      tambahSiswaKeDaftar(result);
    }
  }

  // [FUNGSI BARU] Untuk menambahkan siswa ke daftar tagih secara aman
  void tambahSiswaKeDaftar(SiswaKeuanganModel siswaBaru) {
    // Cek duplikasi
    if (siswaUntukDitagihUP.any((s) => s.uid == siswaBaru.uid)) {
      Get.snackbar("Info", "${siswaBaru.namaLengkap} sudah ada dalam daftar.");
      return;
    }

    siswaUntukDitagihUP.add(siswaBaru);
    // Set nominal default dari master biaya
    uangPangkalControllers[siswaBaru.uid] = TextEditingController(text: masterBiaya['uangPangkal'].toString());
  }

  // [FUNGSI BARU] Untuk menghapus siswa dari daftar
  void hapusSiswaDariDaftar(String uid) {
    siswaUntukDitagihUP.removeWhere((s) => s.uid == uid);
    uangPangkalControllers.remove(uid)?.dispose();
  }

  // ... (fungsi _showConfirmationDialog dan _showProgressDialog tetap sama) ...
  void _showConfirmationDialog({required String title, required String middleText, required RxBool processingFlag, required Future<void> Function() onConfirm}) {
    Get.defaultDialog(
      title: title,
      middleText: middleText,
      textConfirm: "Ya, Lanjutkan",
      confirmTextColor: Colors.white,
      textCancel: "Batal",
      onConfirm: () {
        Get.back();
        onConfirm();
      }
    );
  }

  void _showProgressDialog() {
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Obx(() => Text(
                progressMessage.value,
                textAlign: TextAlign.center,
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  
  void konfirmasiBuatTagihanSPP() {
    _showConfirmationDialog(
      title: "Konfirmasi Buat Tagihan SPP",
      middleText: "Anda akan membuat 12 tagihan SPP untuk semua siswa aktif. Proses ini tidak dapat dibatalkan. Lanjutkan?",
      processingFlag: isProcessingSPP,
      onConfirm: _prosesBuatTagihanSPP
    );
  }

  Future<void> _prosesBuatTagihanSPP() async {
    isProcessingSPP.value = true;
    progressMessage.value = "Mempersiapkan data...";
    _showProgressDialog();

    try {
      final siswaSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where('statusSiswa', isEqualTo: 'Aktif').get();
      final daftarSiswa = siswaSnap.docs.map((d) => SiswaKeuanganModel.fromFirestore(d)).toList();

      // [PERUBAHAN KUNCI #1] Mengambil dan memetakan tagihan yang ada per siswa
      final existingTagihanSnap = await _firestore.collectionGroup('tagihan')
          .where('idTahunAjaran', isEqualTo: tahunAjaranAktif)
          .where('jenisPembayaran', isEqualTo: 'SPP').get();
      
      final Map<String, Set<String>> existingTagihanMap = {};
      for (var doc in existingTagihanSnap.docs) {
        final data = doc.data();
        final idSiswa = data['idSiswa'] as String?;
        if (idSiswa != null) {
          if (!existingTagihanMap.containsKey(idSiswa)) {
            existingTagihanMap[idSiswa] = <String>{};
          }
          existingTagihanMap[idSiswa]!.add(doc.id);
        }
      }

      final WriteBatch batch = _firestore.batch();
      final tahun = int.parse(tahunAjaranAktif.split('-').first);
      final bulanMulai = 7;
      
      int siswaDiproses = 0;
      final int totalSiswa = daftarSiswa.length;

      for (var siswa in daftarSiswa) {
        siswaDiproses++;
        progressMessage.value = "Memproses siswa: $siswaDiproses dari $totalSiswa\n(${siswa.namaLengkap})";
        await Future.delayed(const Duration(milliseconds: 10));

        if (siswa.spp <= 0) continue; 

        final keuanganSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(tahunAjaranAktif)
            .collection('keuangan_siswa').doc(siswa.uid);

        for (int i = 0; i < 12; i++) {
          final bulan = (bulanMulai + i - 1) % 12 + 1;
          final tahunTagihan = (bulanMulai + i > 12) ? tahun + 1 : tahun;
          final namaBulan = DateFormat('MMMM', 'id_ID').format(DateTime(tahunTagihan, bulan));
          final tagihanId = 'SPP-$tahunTagihan-$bulan';
          
          final tagihanRef = keuanganSiswaRef.collection('tagihan').doc(tagihanId);

          // [PERUBAHAN KUNCI #2] Pengecekan yang sekarang spesifik per siswa
          if (existingTagihanMap[siswa.uid]?.contains(tagihanId) ?? false) {
            // Hanya update jika nominal SPP siswa berbeda dari yang tercatat
            // (Ini adalah optimasi tambahan, bisa di-skip jika tidak perlu)
            batch.update(tagihanRef, {'jumlahTagihan': siswa.spp});
          } else {
            // Buat dokumen baru jika tidak ada untuk siswa ini
            batch.set(tagihanRef, {
              'jenisPembayaran': 'SPP', 'deskripsi': 'SPP Bulan $namaBulan $tahunTagihan',
              'jumlahTagihan': siswa.spp, 'jumlahTerbayar': 0, 'status': 'Belum Lunas',
              'tanggalTerbit': Timestamp.now(), 'tanggalJatuhTempo': Timestamp.fromDate(DateTime(tahunTagihan, bulan, 10)),
              'metadata': {'bulan': bulan, 'tahun': tahunTagihan}, 'idTahunAjaran': tahunAjaranAktif,
              'isTunggakan': false, 'idSiswa': siswa.uid, 'namaSiswa': siswa.namaLengkap,
              'kelasSaatDitagih': siswa.kelasId,
            });
          }
        }
      }
      
      progressMessage.value = "Menyimpan data ke server...";
      await batch.commit();
      
      Get.back();
      Get.snackbar("Berhasil", "Tagihan SPP telah diperbarui untuk ${daftarSiswa.length} siswa.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal membuat tagihan SPP: ${e.toString()}");
    } finally {
      isProcessingSPP.value = false;
    }
  }
  
  void konfirmasiBuatTagihanUmum(String jenis) {
    String jenisLengkap = jenis == 'DU' ? 'Daftar Ulang' : 'Uang Kegiatan';
    int nominal = jenis == 'DU' ? masterBiaya['daftarUlang'] ?? 0 : masterBiaya['uangKegiatan'] ?? 0;
    
    _showConfirmationDialog(
      title: "Konfirmasi Buat Tagihan $jenisLengkap",
      middleText: "Anda akan membuat tagihan $jenisLengkap sebesar Rp $nominal untuk semua siswa aktif. Lanjutkan?",
      processingFlag: jenis == 'DU' ? isProcessingDU : isProcessingUK,
      onConfirm: () => _prosesBuatTagihanUmum(jenis, nominal)
    );
  }

  Future<void> _prosesBuatTagihanUmum(String jenis, int nominal) async {
    final flag = jenis == 'DU' ? isProcessingDU : isProcessingUK;
    flag.value = true;
    progressMessage.value = "Mempersiapkan data...";
    _showProgressDialog();

    try {
      if (nominal <= 0) {
        Get.back();
        Get.snackbar("Info", "Nominal biaya belum diatur di Pengaturan Biaya.");
        return;
      }

      final jenisPembayaran = jenis == 'DU' ? 'Daftar Ulang' : 'Uang Kegiatan';
      final tagihanId = jenis == 'DU' ? 'DU-$tahunAjaranAktif' : 'UK-$tahunAjaranAktif';

      final siswaSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where('statusSiswa', isEqualTo: 'Aktif').get();
      final daftarSiswa = siswaSnap.docs.map((d) => SiswaKeuanganModel.fromFirestore(d)).toList();

      final existingTagihanSnap = await _firestore.collectionGroup('tagihan')
          .where('idTahunAjaran', isEqualTo: tahunAjaranAktif)
          .where('jenisPembayaran', isEqualTo: jenisPembayaran)
          .get();
      final Set<String> existingSiswaIds = existingTagihanSnap.docs.map((d) => d.data()['idSiswa'] as String).toSet();

      final WriteBatch batch = _firestore.batch();
      
      int siswaDiproses = 0;
      final int totalSiswa = daftarSiswa.length;

      for (var siswa in daftarSiswa) {
        siswaDiproses++;
        progressMessage.value = "Memproses siswa: $siswaDiproses dari $totalSiswa\n(${siswa.namaLengkap})";
        await Future.delayed(const Duration(milliseconds: 10));

        final keuanganSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(tahunAjaranAktif)
            .collection('keuangan_siswa').doc(siswa.uid);
        
        final tagihanRef = keuanganSiswaRef.collection('tagihan').doc(tagihanId);

        if (existingSiswaIds.contains(siswa.uid)) {
          batch.update(tagihanRef, {'jumlahTagihan': nominal});
        } else {
          batch.set(tagihanRef, {
            'jenisPembayaran': jenisPembayaran, 'deskripsi': '$jenisPembayaran $tahunAjaranAktif',
            'jumlahTagihan': nominal, 'jumlahTerbayar': 0, 'status': 'Belum Lunas',
            'tanggalTerbit': Timestamp.now(), 'idTahunAjaran': tahunAjaranAktif, 'isTunggakan': false,
            'idSiswa': siswa.uid, 'namaSiswa': siswa.namaLengkap, 'kelasSaatDitagih': siswa.kelasId, 'tanggalJatuhTempo': null,
          });
        }
      }
      
      progressMessage.value = "Menyimpan data ke server...";
      await batch.commit();

      Get.back();
      Get.snackbar("Berhasil", "Tagihan $jenisPembayaran telah diperbarui.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal membuat tagihan: ${e.toString()}");
    } finally {
      flag.value = false;
    }
  }

  void konfirmasiBuatTagihanUangPangkal() {
    // [PERUBAHAN VALIDASI] Cek apakah ada siswa di daftar
    if (siswaUntukDitagihUP.isEmpty) {
      Get.snackbar("Peringatan", "Tidak ada siswa yang ditambahkan ke dalam daftar tagihan.");
      return;
    }
    _showConfirmationDialog(
      title: "Konfirmasi Buat Tagihan Uang Pangkal",
      middleText: "Anda akan membuat tagihan Uang Pangkal untuk siswa yang ada di daftar. Pastikan nominal sudah benar. Lanjutkan?",
      processingFlag: isProcessingUP,
      onConfirm: _prosesBuatTagihanUangPangkal
    );
  }

  // [PEROMBAKAN FUNGSI INI]
  Future<void> _prosesBuatTagihanUangPangkal() async {
    isProcessingUP.value = true;
    progressMessage.value = "Mempersiapkan data...";
    _showProgressDialog();

    try {
        final WriteBatch batch = _firestore.batch();
        int siswaDiproses = 0;
        final int totalSiswa = siswaUntukDitagihUP.length;

        for (var siswa in siswaUntukDitagihUP) {
            siswaDiproses++;
            progressMessage.value = "Memproses siswa: $siswaDiproses dari $totalSiswa\n(${siswa.namaLengkap})";
            await Future.delayed(const Duration(milliseconds: 10));

            final nominal = int.tryParse(uangPangkalControllers[siswa.uid]!.text) ?? 0;
            if (nominal <= 0) continue;

            // Update dokumen siswa
            final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
            batch.set(siswaRef, {
                'uangPangkal': {
                  'jumlahTagihan': nominal,
                  'jumlahTerbayar': 0,
                  'status': 'Belum Lunas'
                }
            }, SetOptions(merge: true));

            // Buat dokumen tagihan
            final tagihanUPRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
                .collection('keuangan_sekolah').doc('tagihan_uang_pangkal').collection('tagihan').doc(siswa.uid);
            batch.set(tagihanUPRef, {
                'idSiswa': siswa.uid,
                'namaSiswa': siswa.namaLengkap,
                'kelasSaatDitagih': siswa.kelasId, // [PERBAIKAN] Gunakan kelasId saat ini
                'jenisPembayaran': 'Uang Pangkal',
                'deskripsi': 'Uang Pangkal T.A ${configC.tahunAjaranAktif.value}',
                'jumlahTagihan': nominal,
                'jumlahTerbayar': 0,
                'status': 'Belum Lunas',
                'tanggalTerbit': Timestamp.now(), // [PERBAIKAN] Ganti nama field
            });
        }

        if (siswaDiproses == 0) {
          Get.back();
          Get.snackbar("Info", "Tidak ada data Uang Pangkal untuk diproses (nominal 0).");
          isProcessingUP.value = false;
          return;
        }

        progressMessage.value = "Menyimpan data ke server...";
        await batch.commit();

        Get.back();
        Get.snackbar("Berhasil", "Tagihan Uang Pangkal untuk $siswaDiproses siswa telah dibuat.", backgroundColor: Colors.green, colorText: Colors.white);
        
        // Kosongkan daftar setelah berhasil
        siswaUntukDitagihUP.clear();
        uangPangkalControllers.values.forEach((c) => c.dispose());
        uangPangkalControllers.clear();

    } catch (e) {
        Get.back();
        Get.snackbar("Error", "Gagal membuat tagihan Uang Pangkal: ${e.toString()}");
    } finally {
        isProcessingUP.value = false;
    }
  }

  void konfirmasiBuatTagihanBuku() {
    _showConfirmationDialog(
      title: "Konfirmasi Buat Tagihan Buku",
      middleText: "Anda akan membuat tagihan Uang Buku untuk semua siswa yang sudah mendaftar. Pendaftaran yang sudah diproses tidak akan diproses ulang. Lanjutkan?",
      processingFlag: isProcessingBuku,
      onConfirm: _prosesBuatTagihanBuku
    );
  }
  
  Future<void> _prosesBuatTagihanBuku() async {
    isProcessingBuku.value = true;
    progressMessage.value = "Mempersiapkan data...";
    _showProgressDialog();

    try {
      final pendaftaranSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif)
          .collection('pendaftaran_buku')
          .where('sudahJadiTagihan', isEqualTo: false)
          .get();

      if (pendaftaranSnap.docs.isEmpty) {
        Get.back();
        Get.snackbar("Informasi", "Tidak ada pendaftaran buku baru yang perlu dibuatkan tagihan.",
          backgroundColor: Colors.blueAccent, colorText: Colors.white,
        );
        isProcessingBuku.value = false;
        return;
      }

      final existingTagihanSnap = await _firestore.collectionGroup('tagihan')
          .where('idTahunAjaran', isEqualTo: tahunAjaranAktif)
          .where('jenisPembayaran', isEqualTo: 'Uang Buku')
          .get();
      final Map<String, Map<String, dynamic>> existingTagihanMap = {
        for (var doc in existingTagihanSnap.docs) doc.data()['idSiswa'] as String : doc.data()
      };

      final WriteBatch batch = _firestore.batch();
      int siswaDiproses = 0;
      final int totalSiswa = pendaftaranSnap.docs.length;

      for (var doc in pendaftaranSnap.docs) {
        siswaDiproses++;
        final data = doc.data();
        progressMessage.value = "Memproses: $siswaDiproses dari $totalSiswa\n(${data['namaSiswa']})";
        await Future.delayed(const Duration(milliseconds: 10));

        final uidSiswa = doc.id;
        final totalTagihanBaru = (data['totalTagihanBuku'] as num?)?.toInt() ?? 0;

        if (totalTagihanBaru > 0) {
          final tagihanRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('tahunajaran').doc(tahunAjaranAktif)
              .collection('keuangan_siswa').doc(uidSiswa)
              .collection('tagihan').doc('BUKU-$tahunAjaranAktif');

          if (existingTagihanMap.containsKey(uidSiswa)) {
            batch.update(tagihanRef, {'jumlahTagihan': totalTagihanBaru});
          } else {
            batch.set(tagihanRef, {
              'jenisPembayaran': 'Uang Buku',
              'deskripsi': 'Pembelian Buku $tahunAjaranAktif',
              'jumlahTagihan': totalTagihanBaru,
              'jumlahTerbayar': 0,
              'status': 'Belum Lunas',
              'tanggalTerbit': Timestamp.now(),
              'idTahunAjaran': tahunAjaranAktif,
              'isTunggakan': false,
              'idSiswa': uidSiswa,
              'namaSiswa': data['namaSiswa'],
              'kelasSaatDitagih': data['kelasSiswa'],
            });
          }

          batch.update(doc.reference, {'sudahJadiTagihan': true});
        }
      }

      progressMessage.value = "Menyimpan data ke server...";
      await batch.commit();
      
      Get.back();
      Get.snackbar("Berhasil", "Tagihan Uang Buku untuk $siswaDiproses siswa telah berhasil dibuat/diperbarui.",
        backgroundColor: Colors.green, colorText: Colors.white,
      );

    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal membuat tagihan buku: ${e.toString()}");
    } finally {
      isProcessingBuku.value = false;
    }
  }

  @override
  void onClose() {
    uangPangkalControllers.values.forEach((c) => c.dispose());
    super.onClose();
  }
}