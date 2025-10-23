import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart'; // Pastikan import ini ada
import '../../../controllers/config_controller.dart';
import '../../../models/siswa_model.dart';

class DaftarSiswaController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isLoading = true.obs;
  final RxList<SiswaModel> _semuaSiswa = <SiswaModel>[].obs;
  final RxList<SiswaModel> daftarSiswaFiltered = <SiswaModel>[].obs;
  
  final TextEditingController searchC = TextEditingController();
  final searchQuery = "".obs;
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>();

  // --- [DIUBAH] GETTER HAK AKSES UTAMA (CRUD SISWA) ---
  // Getter ini sekarang secara ketat hanya mengizinkan peran yang Anda tentukan.
  bool get canManageSiswa {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    if (user['peranSistem'] == 'superadmin') return true;

    // Daftar peran yang diizinkan untuk CRUD data siswa
    const allowedRoles = ['Kepala Sekolah', 'TU', 'Tata Usaha', 'Bendahara']; 
    return allowedRoles.contains(user['role']);
  }

  // --- [BARU] GETTER BANTUAN UNTUK LOGIKA YANG LEBIH BERSIH ---
  bool get isKepalaSekolah => configC.infoUser['role'] == 'Kepala Sekolah';
  bool get isKesiswaan => (configC.infoUser['tugas'] as List? ?? []).contains('Kesiswaan');
  
  @override
  void onInit() {
    super.onInit();
    initializeData();
    ever(searchQuery, (_) => _filterData());
    ever(selectedKelasId, (_) => _filterData());
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }

  Future<void> initializeData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchSiswa(),
        _fetchDaftarKelas(),
      ]);
      _filterData();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchSiswa() async {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').orderBy('namaLengkap').get();
    _semuaSiswa.assignAll(snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
  }

  Future<void> _fetchDaftarKelas() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaran)
        .orderBy('namaKelas').get();

    daftarKelas.assignAll(snapshot.docs.map((doc) {
      final data = doc.data();
      final String namaTampilan = data['namaKelas'] ?? doc.id.split('-').first;
      return {'id': doc.id, 'nama': namaTampilan};
    }).toList());
  }

  void _filterData() {
    List<SiswaModel> filteredList = List<SiswaModel>.from(_semuaSiswa);

    if (selectedKelasId.value != null) {
      filteredList = filteredList.where((siswa) => siswa.kelasId == selectedKelasId.value).toList();
    }

    String query = searchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      filteredList = filteredList.where((siswa) {
        return siswa.namaLengkap.toLowerCase().contains(query) || siswa.nisn.contains(query);
      }).toList();
    }
    
    daftarSiswaFiltered.assignAll(filteredList);
  }
  
  // --- [BARU] Fungsi untuk mengecek apakah ada aksi yang bisa dilakukan pada siswa ---
  // Ini akan digunakan di View untuk menentukan apakah ListTile bisa di-tap atau tidak.
  bool canPerformAnyActionOnSiswa(SiswaModel siswa) {
    // Aksi CRUD bisa dilakukan?
    if (canManageSiswa) return true;

    // Cek hak akses untuk Catatan BK
    final isWaliKelasSiswa = configC.infoUser['waliKelasDari'] == siswa.kelasId;
    if (isWaliKelasSiswa || isKepalaSekolah || isKesiswaan) return true;

    return false; // Tidak ada aksi yang bisa dilakukan
  }

  // --- [DIUBAH] Fungsi Menu Aksi menjadi lebih cerdas ---
  void showAksiSiswaMenu(SiswaModel siswa) {
    // Cek hak akses spesifik untuk siswa ini
    final isWaliKelasSiswa = configC.infoUser['waliKelasDari'] == siswa.kelasId;
    final canAccessBk = isWaliKelasSiswa || isKepalaSekolah || isKesiswaan;
    
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(bottom: Get.mediaQuery.viewPadding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Wrap(
          children: <Widget>[
            ListTile(
              title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(siswa.kelasId?.split('-').first ?? 'Belum ada kelas'),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
            const Divider(height: 1),

            // Opsi Catatan BK hanya muncul jika memenuhi syarat
            if (canAccessBk)
              ListTile(
                leading: const Icon(Icons.note_alt_outlined, color: Colors.indigo),
                title: const Text('Catatan Bimbingan Konseling'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.CATATAN_BK_LIST, arguments: {
                    'siswaId': siswa.uid,
                    'siswaNama': siswa.namaLengkap,
                  });
                },
              ),

            // Opsi Edit Siswa hanya muncul jika memenuhi syarat CRUD
            if (canManageSiswa)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Data Siswa'),
                onTap: () {
                  Get.back();
                  goToEditSiswa(siswa);
                },
              ),
          ],
        ),
      ),
    );
  }

  void goToImportSiswa() => Get.toNamed(Routes.IMPORT_SISWA);
  
  void goToTambahSiswa() async {
    final result = await Get.toNamed(Routes.UPSERT_SISWA);
    if (result == true) initializeData();
  }

  void goToEditSiswa(SiswaModel siswa) async {
    final result = await Get.toNamed(Routes.UPSERT_SISWA, arguments: siswa);
    if (result == true) initializeData();
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../controllers/config_controller.dart';
// import '../../../models/siswa_model.dart';
// import '../../../routes/app_pages.dart';

// class DaftarSiswaController extends GetxController {
//   final ConfigController configC = Get.find<ConfigController>();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // State Utama
//   final isLoading = true.obs;
//   final RxList<SiswaModel> _semuaSiswa = <SiswaModel>[].obs;
//   final RxList<SiswaModel> daftarSiswaFiltered = <SiswaModel>[].obs;
  
//   // State untuk Filter
//   final TextEditingController searchC = TextEditingController();
//   final searchQuery = "".obs;
//   final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
//   final Rxn<String> selectedKelasId = Rxn<String>(); // null artinya "Semua Kelas"

//   // Hak Akses
//   bool get canManageSiswa {
//     final user = configC.infoUser;
//     if (user.isEmpty) return false;
//     if (user['peranSistem'] == 'superadmin') return true;

//     // Daftar peran yang diizinkan untuk CRUD data siswa
//     const allowedRoles = ['Kepala Sekolah', 'TU', 'Tata Usaha', 'Bendahara']; 
//     return allowedRoles.contains(user['role']);
//   }

//   // --- [BARU] GETTER BANTUAN UNTUK LOGIKA YANG LEBIH BERSIH ---
//   bool get isKepalaSekolah => configC.infoUser['role'] == 'Kepala Sekolah';
//   bool get isKesiswaan => (configC.infoUser['tugas'] as List? ?? []).contains('Kesiswaan');

//   @override
//   void onInit() {
//     super.onInit();
//     initializeData();
//     // Listener untuk memfilter secara reaktif
//     ever(searchQuery, (_) => _filterData());
//     ever(selectedKelasId, (_) => _filterData());
//   }

//   @override
//   void onClose() {
//     searchC.dispose();
//     super.onClose();
//   }

//   Future<void> initializeData() async {
//     isLoading.value = true;
//     try {
//       // Ambil data siswa dan kelas secara bersamaan untuk efisiensi
//       await Future.wait([
//         _fetchSiswa(),
//         _fetchDaftarKelas(),
//       ]);
//       _filterData(); // Terapkan filter awal (tampilkan semua)
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat data awal: ${e.toString()}");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> _fetchSiswa() async {
//     final snapshot = await _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('siswa').orderBy('namaLengkap').get();
//     _semuaSiswa.assignAll(snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
//   }

//   Future<void> _fetchDaftarKelas() async {
//     final tahunAjaran = configC.tahunAjaranAktif.value;
//     final snapshot = await _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaran)
//         .orderBy('namaKelas').get();

//     // --- [PERBAIKAN] Pastikan nama kelas selalu pendek dan bersih ---
//     daftarKelas.assignAll(snapshot.docs.map((doc) {
//       final data = doc.data();
//       // Ambil 'namaKelas' dari data, jika tidak ada, ambil dari ID dokumen dan potong.
//       final String namaTampilan = data['namaKelas'] ?? doc.id.split('-').first;
//       return {'id': doc.id, 'nama': namaTampilan};
//     }).toList());
//     // --- AKHIR PERBAIKAN ---
//   }

//   void _filterData() {
//     List<SiswaModel> filteredList = List<SiswaModel>.from(_semuaSiswa);

//     // --- FILTER LAPIS 1: KELAS ---
//     if (selectedKelasId.value != null) {
//       filteredList = filteredList.where((siswa) => siswa.kelasId == selectedKelasId.value).toList();
//     }

//     // --- FILTER LAPIS 2: PENCARIAN (NAMA/NISN) ---
//     String query = searchQuery.value.toLowerCase();
//     if (query.isNotEmpty) {
//       filteredList = filteredList.where((siswa) {
//         return siswa.namaLengkap.toLowerCase().contains(query) || siswa.nisn.contains(query);
//       }).toList();
//     }
    
//     daftarSiswaFiltered.assignAll(filteredList);
//   }

//   void goToImportSiswa() => Get.toNamed(Routes.IMPORT_SISWA);
  
//   void goToTambahSiswa() async {
//     final result = await Get.toNamed(Routes.UPSERT_SISWA);
//     if (result == true) initializeData();
//   }

//   void goToEditSiswa(SiswaModel siswa) async {
//     final result = await Get.toNamed(Routes.UPSERT_SISWA, arguments: siswa);
//     if (result == true) initializeData();
//   }

//   void showAksiSiswaMenu(SiswaModel siswa) {
//     // Cek apakah pengguna saat ini adalah wali kelas dari siswa yang dipilih
//     final isWaliKelasSiswa = configC.infoUser['waliKelasDari'] == siswa.kelasId;

//     Get.bottomSheet(
//       Container(
//         padding: EdgeInsets.only(bottom: Get.mediaQuery.viewPadding.bottom),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: Wrap(
//           children: <Widget>[
//             ListTile(
//               title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//               subtitle: Text(siswa.kelasId?.split('-').first ?? 'Belum ada kelas'),
//               contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//             ),
//             const Divider(height: 1),

//             // Opsi ini hanya muncul jika pengguna adalah Wali Kelas siswa tersebut
//             if (isWaliKelasSiswa)
//               ListTile(
//                 leading: const Icon(Icons.note_alt_outlined, color: Colors.indigo),
//                 title: const Text('Catatan Bimbingan Konseling'),
//                 onTap: () {
//                   Get.back(); // Tutup bottom sheet
//                   Get.toNamed(Routes.CATATAN_BK_LIST, arguments: {
//                     'siswaId': siswa.uid,
//                     'siswaNama': siswa.namaLengkap,
//                   });
//                 },
//               ),

//             // Opsi lain yang relevan
//             if (canManageSiswa) // Menggunakan getter yang sudah ada
//               ListTile(
//                 leading: const Icon(Icons.edit_outlined),
//                 title: const Text('Edit Data Siswa'),
//                 onTap: () {
//                   Get.back();
//                   goToEditSiswa(siswa); // Memanggil fungsi yang sudah ada
//                 },
//               ),
            
//             // Contoh opsi lain di masa depan
//             // ListTile(
//             //   leading: Icon(Icons.account_balance_wallet_outlined),
//             //   title: Text('Lihat Detail Keuangan'),
//             //   onTap: () { ... },
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }