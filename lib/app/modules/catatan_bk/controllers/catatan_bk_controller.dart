import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/catatan_bk_model.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';

class CatatanBkController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String siswaId;
  late String siswaNama;
  late DocumentReference siswaDocRef;

  final RxBool isListLoading = true.obs;
  final RxList<CatatanBkModel> daftarCatatan = <CatatanBkModel>[].obs;

  final RxBool isDetailLoading = true.obs;
  final Rxn<CatatanBkModel> catatanDetail = Rxn<CatatanBkModel>();
  final RxList<DocumentSnapshot> komentarList = <DocumentSnapshot>[].obs;
  StreamSubscription? _komentarSubscription;

  final TextEditingController komentarController = TextEditingController();
  final RxBool isSendingKomentar = false.obs;

  final TextEditingController judulCatatanController = TextEditingController();
  final TextEditingController isiCatatanController = TextEditingController();

  final RxBool canCreateNote = false.obs;


  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    siswaId = args['siswaId'];
    siswaNama = args['siswaNama'];
    siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswaId);
    
    // --- PRINT DEBUG #1: Verifikasi data awal ---
    print("================ DEBUG-BK-INIT ================");
    print("Siswa yang dibuka: $siswaNama (ID: $siswaId)");
    print("Profil Wali Kelas Login: ${configC.infoUser['nama']}");
    print("=============================================");
  }

  @override
  void onClose() {
    _komentarSubscription?.cancel();
    komentarController.dispose();
    judulCatatanController.dispose();
    isiCatatanController.dispose();
    super.onClose();
  }

  Future<void> checkPermissions() async {
    final userProfile = configC.infoUser;
    final siswaDoc = await siswaDocRef.get();
    
    if (!siswaDoc.exists) {
      canCreateNote.value = false;
      print("🚫 DEBUG-BK-PERMISSIONS: Dokumen siswa TIDAK DITEMUKAN.");
      return;
    }
    
    final siswaData = siswaDoc.data() as Map<String, dynamic>?;
    final kelasIdSiswa = siswaData?['kelasId'];
    final waliKelasDari = userProfile['waliKelasDari'];

    // --- PRINT DEBUG #2: Titik Pengecekan Kritis ---
    print("\n=============== DEBUG-BK-PERMISSIONS ===============");
    print("MEMBANDINGKAN DATA UNTUK MENAMPILKAN TOMBOL (+):");
    print("1. ID Kelas Perwalian (dari Profil Wali Kelas): ->'$waliKelasDari'<-");
    print("2. ID Kelas Siswa (dari Profil Siswa):         ->'$kelasIdSiswa'<-");

    // Lakukan perbandingan dan cetak hasilnya
    final bool isMatch = waliKelasDari == kelasIdSiswa;
    print("\nAPAKAH KEDUA NILAI DI ATAS SAMA PERSIS? -> $isMatch <-");
    print("====================================================\n");

    canCreateNote.value = isMatch;
  }

  Future<void> fetchCatatanList() async {
    isListLoading.value = true;
    await checkPermissions();
    try {
      final snapshot = await siswaDocRef.collection('catatan_bk').orderBy('tanggalDibuat', descending: true).get();
      daftarCatatan.value = snapshot.docs.map((doc) => CatatanBkModel.fromFirestore(doc)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: ${e.toString()}');
    } finally {
      isListLoading.value = false;
    }
  }

  Future<void> fetchDetailAndKomentar(String catatanId) async {
    isDetailLoading.value = true;
    _komentarSubscription?.cancel();
    try {
      final doc = await siswaDocRef.collection('catatan_bk').doc(catatanId).get();
      if (doc.exists) {
        catatanDetail.value = CatatanBkModel.fromFirestore(doc);
        _listenToKomentar(catatanId);
      } else {
         Get.snackbar('Error', 'Catatan tidak ditemukan.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat detail catatan: ${e.toString()}');
    } finally {
      isDetailLoading.value = false;
    }
  }

  void _listenToKomentar(String catatanId) {
    _komentarSubscription = siswaDocRef.collection('catatan_bk').doc(catatanId).collection('komentar').orderBy('timestamp').snapshots().listen((snapshot) {
      komentarList.value = snapshot.docs;
    });
  }

  Future<void> addKomentar(String catatanId) async {
    if (komentarController.text.trim().isEmpty) return;
    isSendingKomentar.value = true;
    try {
      final user = configC.infoUser;
      final namaPenulis = user['alias'] != null && (user['alias'] as String).isNotEmpty 
                           ? user['alias'] 
                           : user['nama'];
      final peranPenulis = user['role'] ?? user['tugas']?.first ?? 'Staf';
      final newKomentarRef = siswaDocRef.collection('catatan_bk').doc(catatanId).collection('komentar').doc();
      
      WriteBatch batch = _firestore.batch();
      
      batch.set(newKomentarRef, {
        'isi': komentarController.text.trim(),
        'penulisId': user['uid'],
        'penulisNama': namaPenulis,
        'penulisPeran': peranPenulis,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Kirim notifikasi ke orang tua
      _sendNotificationToParent(
        batch: batch,
        judul: "Balasan Baru di Catatan Perkembangan",
        isi: "${user['nama']} telah membalas catatan '${catatanDetail.value?.judul}'.",
        catatanId: catatanId
      );

      await batch.commit();
      komentarController.clear();
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengirim komentar: ${e.toString()}');
    } finally {
      isSendingKomentar.value = false;
    }
  }

  void showCreateNoteForm() {
    judulCatatanController.clear();
    isiCatatanController.clear();
    Get.dialog(
      AlertDialog(
        title: Text('Buat Catatan BK Baru'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: judulCatatanController, decoration: InputDecoration(labelText: 'Judul Catatan')),
            SizedBox(height: 16),
            TextField(controller: isiCatatanController, decoration: InputDecoration(labelText: 'Isi Catatan'), maxLines: 5),
          ]),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('Batal')),
          ElevatedButton(onPressed: _createNote, child: Text('Simpan')),
        ],
      ),
    );
  }

  Future<void> _createNote() async {
    if (judulCatatanController.text.isEmpty || isiCatatanController.text.isEmpty) {
      Get.snackbar('Input Tidak Lengkap', 'Judul dan Isi catatan tidak boleh kosong.');
      return;
    }
    Get.back(); // Tutup dialog
    isListLoading.value = true; // Tampilkan loading di list view
    try {
      final user = configC.infoUser;
      final namaPenulis = user['alias'] != null && (user['alias'] as String).isNotEmpty 
                           ? user['alias'] 
                           : user['nama'];

      final newCatatanRef = siswaDocRef.collection('catatan_bk').doc();
      
      WriteBatch batch = _firestore.batch();

      // Operasi 1: Buat catatan baru
      batch.set(newCatatanRef, {
        'judul': judulCatatanController.text.trim(),
        'isi': isiCatatanController.text.trim(),
        'pembuatId': user['uid'],
        'pembuatNama': namaPenulis,
        'tanggalDibuat': FieldValue.serverTimestamp(),
        'status': 'Dibuka',
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // --- [PERUBAHAN KRUSIAL DI SINI] ---
      // Operasi 2: Update dokumen siswa untuk menandai bahwa ia punya catatan
      batch.update(siswaDocRef, {'memilikiCatatanBk': true});
      // ------------------------------------

      // Operasi 3: Kirim notifikasi ke orang tua
      _sendNotificationToParent(
        batch: batch,
        judul: "Catatan Perkembangan Baru",
        isi: "Wali Kelas telah menambahkan catatan baru untuk Ananda.",
        catatanId: newCatatanRef.id
      );

      await batch.commit();

      Get.snackbar('Berhasil', 'Catatan baru berhasil dibuat.');
      await fetchCatatanList(); // Muat ulang daftar catatan
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuat catatan: ${e.toString()}');
       isListLoading.value = false;
    }
  }

  // --- [FUNGSI BARU UNTUK NOTIFIKASI] ---
  void _sendNotificationToParent({
    required WriteBatch batch,
    required String judul,
    required String isi,
    required String catatanId,
  }) {
    // Referensi ke subkoleksi notifikasi di dokumen siswa
    final notifRef = siswaDocRef.collection('notifikasi').doc();
    final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');

    // Buat data notifikasi
    batch.set(notifRef, {
      'judul': judul,
      'isi': isi,
      'tipe': 'CATATAN_BK', // Tipe baru untuk notifikasi
      'tanggal': FieldValue.serverTimestamp(),
      'isRead': false,
      'deepLink': '${Routes.CATATAN_BK_DETAIL}?catatanId=$catatanId', // Deep link
    });

    // Increment unreadCount
    batch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  void goToDetail(CatatanBkModel catatan) {
    Get.toNamed(Routes.CATATAN_BK_DETAIL, arguments: {
      'siswaId': siswaId,
      'siswaNama': siswaNama,
      'catatanId': catatan.id,
    });
  }
}