import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/dashboard_controller.dart'; // Pastikan path ini benar
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart'; // Pastikan path ini benar
import 'auth_controller.dart';

enum AppStatus { loading, unauthenticated, needsNewPassword, authenticated }

class ConfigController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Gunakan Get.find di sini juga untuk memastikan AuthController sudah terdaftar
  final AuthController _authController = Get.find<AuthController>(); 
  final GetStorage _box = GetStorage();

  late final String idSekolah;
  final RxMap<String, dynamic> infoUser = <String, dynamic>{}.obs;
  final Rx<AppStatus> status = AppStatus.loading.obs; 
  final RxBool isUserDataReady = false.obs; // Sinyal data pengguna sudah lengkap
  
  final RxString tahunAjaranAktif = "".obs;
  final RxString semesterAktif = "".obs;
  final RxList<String> daftarRoleTersedia = <String>[].obs;
  final RxList<String> daftarTugasTersedia = <String>[].obs;
  final RxBool isRoleManagementLoading = true.obs;

  final RxMap<String, dynamic> konfigurasiDashboard = <String, dynamic>{}.obs;

  StreamSubscription? _tahunAjaranSubscription;
  final Rxn<DateTime> tanggalMulaiSemester2 = Rxn<DateTime>();
  final Rxn<DateTime> tanggalMulaiTahunAjaranBaru = Rxn<DateTime>();

  final RxBool isCreatingNewUser = false.obs;
  StreamSubscription<User?>? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    print("🚀 [ConfigController] onInit called.");
    idSekolah = dotenv.env['ID_SEKOLAH']!;
    print("⚙️ [ConfigController] ID_SEKOLAH loaded: $idSekolah");
    _loadProfileFromCache(); // Coba muat profil dari cache lebih awal
    
    _userSubscription = _authController.authStateChanges.listen((user) async {
      print("🔑 [ConfigController] Auth state changed: User is ${user == null ? 'null (unauthenticated)' : 'authenticated'}.");
      
      // Reset isUserDataReady saat auth state berubah, karena data perlu disinkronkan ulang
      isUserDataReady.value = false; 

      if (isCreatingNewUser.value) {
        print("[AUTH] Mode Senyap Aktif. Perubahan auth diabaikan.");
        return;
      }
      
      if (user == null) {
        print("🗑️ [ConfigController] User is null. Clearing config.");
        await clearUserConfig();
        status.value = AppStatus.unauthenticated;
        print("➡️ [ConfigController] Status set to AppStatus.unauthenticated.");
      } else {
        print("✅ [ConfigController] User is authenticated (${user.uid}). Syncing all user data.");
        // Set status loading di awal sinkronisasi data pengguna
        status.value = AppStatus.loading; 
        await _syncAllUserData(user.uid);
        print("➡️ [ConfigController] _syncAllUserData finished. Final status set to ${status.value}.");
      }
    });
    print("✅ [ConfigController] onInit finished. _userSubscription initialized.");
  }
  
  @override
  void onClose() {
    print("🗑️ [ConfigController] onClose called.");
    _userSubscription?.cancel();
    _tahunAjaranSubscription?.cancel();
    super.onClose();
  }

  /// Metode utama untuk menyinkronkan semua data pengguna dan konfigurasi.
  /// Dilingkupi try-catch untuk memastikan status selalu mencapai akhir.
  Future<void> _syncAllUserData(String uid) async {
    print("🔄 [ConfigController] _syncAllUserData started for $uid.");
    isUserDataReady.value = false; // Reset flag di awal setiap kali sinkronisasi dimulai
    status.value = AppStatus.loading; // Pastikan status loading saat sinkronisasi

    try {
      bool profileSynced = await _syncProfileWithFirestore(uid);
      if (!profileSynced) {
        print("🛑 [ConfigController] Profile sync failed, stopping _syncAllUserData. isUserDataReady remains false. User might be logged out.");
        // Jika profil gagal disinkronkan, _syncProfileWithFirestore sudah menangani logout.
        // authStateChanges listener akan memicu penanganan unauthenticated.
        return; 
      }

      await _syncTahunAjaranAktif();
      print("📅 [ConfigController] Tahun Ajaran Active: ${tahunAjaranAktif.value}");

      // Jalankan operasi sinkronisasi paralel
      await Future.wait([
        _syncRoleManagementDataIfAllowed(),
        _checkIsWaliKelas(uid),
        _syncKonfigurasiDashboard(), 
      ]);
      print("🎉 [ConfigController] All parallel sync tasks finished.");
        
      final bool mustChange = infoUser['mustChangePassword'] ?? false;
      if (mustChange) {
        status.value = AppStatus.needsNewPassword;
      } else {
        status.value = AppStatus.authenticated;
      }
      isUserDataReady.value = true; // Set flag true setelah SEMUA sinkronisasi berhasil
      print("✅ [ConfigController] _syncAllUserData finished. Status: ${status.value}. isUserDataReady: ${isUserDataReady.value}");

    } on FirebaseAuthException catch (e) {
      print("❌ [ConfigController] FirebaseAuthException in _syncAllUserData: ${e.code} - ${e.message}");
      Get.snackbar("Error Autentikasi", "Sesi bermasalah. Silakan login kembali. [Code: ${e.code}]", 
                   snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      await _authController.logout();
      status.value = AppStatus.unauthenticated;
      isUserDataReady.value = false;
    } catch (e) {
      print("❌ [ConfigController] General ERROR in _syncAllUserData: $e");
      Get.snackbar("Error Data", "Gagal memuat data pengguna. Silakan coba lagi. ${e.toString()}", 
                   snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      
      // Pada kasus error yang tidak terduga saat sinkronisasi data,
      // ada baiknya mengarahkan pengguna ke status unauthenticated (logout).
      await _authController.logout(); 
      
      // Pastikan status juga unauthenticated jika logout tidak mengubahnya secara langsung
      if (status.value != AppStatus.unauthenticated) {
          status.value = AppStatus.unauthenticated;
      }
      isUserDataReady.value = false; // Pastikan ini juga false
    }
  }

  Future<void> _checkIsWaliKelas(String uid) async {
    print("🔍 [ConfigController] Checking if $uid is a homeroom teacher.");
    if (tahunAjaranAktif.value.isEmpty || tahunAjaranAktif.value.contains("TIDAK")) {
      print(">> DEBUG WALI KELAS: Stop, tahun ajaran tidak aktif.");
      infoUser.remove('kelasDiampu');
      return;
    }
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif.value)
          .collection('kelastahunajaran')
          .where('idWaliKelas', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        infoUser['kelasDiampu'] = snapshot.docs.first.id;
        print(">> DEBUG WALI KELAS: Kelas diampu ditemukan: ${infoUser['kelasDiampu']}");
      } else {
        print(">> DEBUG WALI KELAS: TIDAK DITEMUKAN. Tidak ada kelas yang diampu.");
        infoUser.remove('kelasDiampu');
      }
    } catch (e) {
      print(">> DEBUG WALI KELAS: ERROR SAAT QUERY! $e");
      // Tidak perlu throw, cukup log error
    }
  }

  Future<void> _syncKonfigurasiDashboard() async {
    print("📊 [ConfigController] Syncing dashboard configuration.");
    try {
      final doc = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('pengaturan').doc('konfigurasi_dashboard')
          .get();
      if (doc.exists && doc.data() != null) {
        konfigurasiDashboard.value = doc.data()!;
        print("📊 [ConfigController] Dashboard config loaded.");
      } else {
        konfigurasiDashboard.clear();
        print("📊 [ConfigController] Dashboard config not found or empty.");
      }
    } catch (e) {
      print("### Gagal mengambil konfigurasi dashboard: $e");
      konfigurasiDashboard.clear();
    }
  }
  
  // Future<bool> _syncProfileWithFirestore(String uid) async {
  //   print("👤 [ConfigController] _syncProfileWithFirestore started for $uid.");
  //   try {
  //     final userDoc = await _firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(uid).get();
  //     if (userDoc.exists && userDoc.data() != null) {
  //       final Map<String, dynamic> firestoreData = userDoc.data()!;
        
  //       infoUser.value = firestoreData;
  //       print("👤 [ConfigController] User profile loaded from Firestore: ${infoUser['nama']}.");
  
  //       // Buat salinan data untuk cache, lalu iterasi untuk konversi Timestamp
  //       final Map<String, dynamic> dataForCache = Map<String, dynamic>.from(firestoreData);
        
  //       dataForCache.forEach((key, value) {
  //         if (value is Timestamp) {
  //           // Konversi SETIAP Timestamp yang ditemukan menjadi String ISO8601
  //           dataForCache[key] = value.toDate().toIso8601String();
  //         }
  //       });
        
  //       await _box.write('userProfile', dataForCache);
  //       print("💾 [ConfigController] User profile cached.");
  
  //       // TAMBAHAN BARU: SIMPAN ID SEKOLAH DI KOLEKSI USERS
  //       // Ini penting untuk aturan keamanan yang baru
  //       final userRef = _firestore.collection('users').doc(uid);
  //       await userRef.set({ 'idSekolah': idSekolah }, SetOptions(merge: true));
  //       print("🌐 [ConfigController] User's school ID synced for security rules.");
  
  //       return true;
  //     } else {
  //       print("🛑 [ConfigController] Profile for $uid not found in Firestore. Logging out.");
  //       Get.snackbar("Profil Tidak Ditemukan", "Profil pengguna tidak ditemukan di database. Silakan hubungi administrator.", 
  //                    snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
  //       await _authController.logout(); // Memaksa logout
  //       return false;
  //     }
  //   } catch (e) {
  //     print("❌ [ConfigController] Error syncing profile: $e. Logging out.");
  //     Get.snackbar("Error Profil", "Gagal memuat profil pengguna: ${e.toString()}. Silakan login kembali.", 
  //                  snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
  //     await _authController.logout(); // Memaksa logout
  //     return false;
  //   }
  // }

  Future<bool> _syncProfileWithFirestore(String uid) async {
    print("👤 [ConfigController] _syncProfileWithFirestore started for $uid.");
    try {
      final userDoc = await _firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final Map<String, dynamic> firestoreData = userDoc.data()!;

        // [PERBAIKAN KUNCI DI SINI]
        // Secara manual tambahkan ID dokumen ke dalam map data.
        firestoreData['uid'] = uid;

        infoUser.value = firestoreData;
        print("👤 [ConfigController] User profile loaded from Firestore: ${infoUser['nama']}. UID: ${infoUser['uid']}");

        // Buat salinan data untuk cache, lalu iterasi untuk konversi Timestamp
        final Map<String, dynamic> dataForCache = Map<String, dynamic>.from(firestoreData);

        dataForCache.forEach((key, value) {
          if (value is Timestamp) {
            dataForCache[key] = value.toDate().toIso8601String();
          }
        });

        await _box.write('userProfile', dataForCache);
        print("💾 [ConfigController] User profile cached.");

        final userRef = _firestore.collection('users').doc(uid);
        await userRef.set({ 'idSekolah': idSekolah }, SetOptions(merge: true));
        print("🌐 [ConfigController] User's school ID synced for security rules.");

        return true;
      } else {
        print("🛑 [ConfigController] Profile for $uid not found in Firestore. Logging out.");
        Get.snackbar("Profil Tidak Ditemukan", "Profil pengguna tidak ditemukan di database. Silakan hubungi administrator.", 
                     snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        await _authController.logout();
        return false;
      }
    } catch (e) {
      print("❌ [ConfigController] Error syncing profile: $e. Logging out.");
      Get.snackbar("Error Profil", "Gagal memuat profil pengguna: ${e.toString()}. Silakan login kembali.", 
                   snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      await _authController.logout();
      return false;
    }
  }

  Future<void> _syncRoleManagementDataIfAllowed() async {
    print("👮 [ConfigController] Checking role management access.");
    const allowedRoles = ['Admin', 'Operator', 'TU', 'Tata Usaha', 'Kepala Sekolah'];
    const allowedTugas = ['Koordinator Kurikulum'];
    
    final List<String> userTugas = List<String>.from(infoUser['tugas'] ?? []);
    final String userRole = infoUser['role']?.toString() ?? '';

    // Perbaiki logika: apakah userRole ada di allowedRoles ATAU ada tugas yang diizinkan
    final bool hasAllowedAccess = allowedRoles.contains(userRole) || userTugas.any((task) => allowedTugas.contains(task)); 
    
    bool canManage = infoUser['peranSistem'] == 'superadmin' || hasAllowedAccess;
    
    if (canManage) {
      await _syncRoleManagementData();
    } else {
      print("👮 [ConfigController] User does not have privileges for role management data.");
      daftarRoleTersedia.clear();
      daftarTugasTersedia.clear();
      isRoleManagementLoading.value = false;
    }
  }

  Future<void> _syncRoleManagementData() async {
    print("🛠️ [ConfigController] Syncing role management data.");
    try {
      isRoleManagementLoading.value = true;
      final doc = await _firestore.collection('Sekolah').doc(idSekolah).collection('pengaturan').doc('manajemen_peran').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        daftarRoleTersedia.assignAll(List<String>.from(data['daftar_role'] ?? []));
        daftarTugasTersedia.assignAll(List<String>.from(data['daftar_tugas'] ?? []));
        print("🛠️ [ConfigController] Role management data loaded.");
      } else {
        daftarRoleTersedia.clear();
        daftarTugasTersedia.clear();
        print("🛠️ [ConfigController] Role management data not found or empty.");
      }
    } catch (e) {
      print("### Gagal memuat data peran dan tugas: $e");
      // Get.snackbar("Error Konfigurasi", "Gagal memuat data peran dan tugas.");
    } finally {
      isRoleManagementLoading.value = false;
    }
  }
  
  Future<void> _syncTahunAjaranAktif() async {
    print("📆 [ConfigController] _syncTahunAjaranAktif started.");
    await _tahunAjaranSubscription?.cancel();
    
    final query = _firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').where('isAktif', isEqualTo: true).limit(1);

    // [PERBAIKAN KRUSIAL] Gunakan Completer untuk menunggu event pertama dari stream
    final Completer<void> _tahunAjaranCompleter = Completer<void>();

    _tahunAjaranSubscription = query.snapshots().listen((snapshot) {
      print("🔔 [ConfigController] _tahunAjaranSubscription data received.");
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        tahunAjaranAktif.value = doc.id;
        semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
        print(">>> [REALTIME] Tahun Ajaran: ${doc.id}, Semester: ${semesterAktif.value}");
      } else {
        tahunAjaranAktif.value = "TIDAK DITEMUKAN"; // Secara eksplisit set jika tidak ditemukan
        semesterAktif.value = "0"; 
        print("⚠️ [ConfigController] No active tahunajaran found.");
      }
      _checkAcademicTimeline(); // Panggil timeline setelah tahun ajaran diupdate
      if (!_tahunAjaranCompleter.isCompleted) {
        _tahunAjaranCompleter.complete(); // Selesaikan Completer setelah event pertama diproses
      }
    }, onError: (error) {
      tahunAjaranAktif.value = "ERROR";
      semesterAktif.value = "0"; 
      print("### Error sync Tahun Ajaran: $error");
      if (!_tahunAjaranCompleter.isCompleted) {
        _tahunAjaranCompleter.completeError(error); // Selesaikan dengan error jika terjadi
      }
    });

    // [PERBAIKAN KRUSIAL] Tunggu hingga Completer selesai (event stream pertama diterima)
    // Ini memastikan tahunAjaranAktif memiliki nilai sebelum _syncTahunAjaranAktif() selesai.
    try {
      await _tahunAjaranCompleter.future.timeout(const Duration(seconds: 10)); // Tambah timeout
    } catch (e) {
      print("❌ [ConfigController] Timeout or Error waiting for first Tahun Ajaran stream event: $e");
      tahunAjaranAktif.value = "ERROR";
      semesterAktif.value = "0";
      // Melemparkan kembali error untuk ditangkap di _syncAllUserData jika perlu,
      // atau cukup log dan lanjutkan dengan nilai error.
    }


    try {
      final configDoc = await _firestore.collection('Sekolah').doc(idSekolah).collection('pengaturan').doc('konfigurasi_akademik').get();
      if (configDoc.exists) {
        tanggalMulaiSemester2.value = (configDoc.data()?['tanggalMulaiSemester2'] as Timestamp?)?.toDate();
        tanggalMulaiTahunAjaranBaru.value = (configDoc.data()?['tanggalMulaiTahunAjaranBaru'] as Timestamp?)?.toDate();
        print("⏱️ [ConfigController] Academic config dates loaded.");
      } else {
        tanggalMulaiSemester2.value = null;
        tanggalMulaiTahunAjaranBaru.value = null;
        print("⏱️ [ConfigController] Academic config not found.");
      }
    } catch (e) {
      print("### Gagal mengambil konfigurasi tanggal akademik: $e");
    }
  }

  void _checkAcademicTimeline() {
    Future.delayed(const Duration(seconds: 3), () {
      if (Get.isDialogOpen ?? false) return;

      // Pastikan DashboardController terdaftar sebelum mencoba mengaksesnya
      if (!Get.isRegistered<DashboardController>()) {
        print("DashboardController belum terdaftar, tidak bisa cek timeline akademik.");
        return;
      }
      final dashboardC = Get.find<DashboardController>();
      if (!dashboardC.isPimpinan) return; // Hanya pimpinan yang melihat notifikasi ini

      final now = DateTime.now();
      
      if (tanggalMulaiTahunAjaranBaru.value != null && now.isAfter(tanggalMulaiTahunAjaranBaru.value!)) {
        // Cek apakah tahun ajaran aktif saat ini TIDAK mengandung tahun sekarang
        // Ini adalah asumsi bahwa format tahun ajaran adalah YYYY-YYYY+1 atau serupa
        if (!tahunAjaranAktif.value.contains(now.year.toString())) { 
          Get.dialog(
            AlertDialog(
              title: const Text("Pemberitahuan Tahun Ajaran"),
              content: Text("Menurut sistem, sudah waktunya untuk memulai Tahun Ajaran ${now.year}-${now.year + 1}. Status saat ini masih di Tahun Ajaran ${tahunAjaranAktif.value}. Disarankan untuk melakukan proses Penutupan Tahun Ajaran."),
              actions: [
                TextButton(onPressed: Get.back, child: const Text("Nanti Saja")),
                ElevatedButton(onPressed: () { Get.back(); Get.toNamed(Routes.PENGATURAN_AKADEMIK); }, child: const Text("Buka Pengaturan")),
              ]
            )
          );
          return;
        }
      }

      if (semesterAktif.value == "1" && tanggalMulaiSemester2.value != null && now.isAfter(tanggalMulaiSemester2.value!)) {
        Get.dialog(
          AlertDialog(
            title: const Text("Pemberitahuan Semester"),
            content: const Text("Menurut sistem, saat ini sudah memasuki Semester 2, namun semester aktif masih Semester 1. Disarankan untuk memperbarui status semester."),
            actions: [
              TextButton(onPressed: Get.back, child: const Text("Nanti Saja")),
              ElevatedButton(onPressed: () { Get.back(); Get.toNamed(Routes.PENGATURAN_AKADEMIK); }, child: const Text("Buka Pengaturan")),
            ]
          )
        );
      }
    });
  }

  Future<void> reloadRoleManagementData() async {
    print("🔄 [ConfigController] Reloading role management data.");
    await _syncRoleManagementData();
  }

  void _loadProfileFromCache() {
    print("📦 [ConfigController] _loadProfileFromCache called.");
    final cachedProfile = _box.read<Map<String, dynamic>>('userProfile');
    
    if (cachedProfile != null) {
      final Map<String, dynamic> processedProfile = Map<String, dynamic>.from(cachedProfile);

      // Konversi kembali String ke Timestamp jika ada
      if (processedProfile['tglgabung'] is String) {
        try {
          final DateTime parsedDate = DateTime.parse(processedProfile['tglgabung']);
          processedProfile['tglgabung'] = Timestamp.fromDate(parsedDate);
        } catch (e) {
          processedProfile.remove('tglgabung');
          print("### Peringatan: Gagal mem-parsing 'tglgabung' dari cache: $e");
        }
      }
      infoUser.value = processedProfile;
      print("📦 [ConfigController] Profile loaded from cache: ${infoUser['nama']}.");
    } else {
      print("📦 [ConfigController] No profile found in cache.");
    }
  }
  
  Future<void> clearUserConfig() async {
    print("🧹 [ConfigController] clearUserConfig called.");
    await _box.remove('userProfile');
    infoUser.clear();
    daftarRoleTersedia.clear();
    daftarTugasTersedia.clear();
    
    tahunAjaranAktif.value = "";
    semesterAktif.value = "";
    konfigurasiDashboard.clear();

    isUserDataReady.value = false; // Reset flag
    _tahunAjaranSubscription?.cancel();
    _tahunAjaranSubscription = null; // Set ke null setelah dibatalkan
    print("🧹 [ConfigController] User config cleared. isUserDataReady: ${isUserDataReady.value}");
  }

  Future<void> reloadKonfigurasiDashboard() async {
    print("🔄 [ConfigController] Reloading dashboard configuration.");
    await _syncKonfigurasiDashboard();
  }

  Future<void> forceSyncProfile() async {
    print("💪 [ConfigController] forceSyncProfile called.");
    final user = _authController.auth.currentUser;
    if (user != null) {
      // Panggil _syncProfileWithFirestore, tetapi tidak perlu mengubah isUserDataReady atau status global
      // karena forceSyncProfile ini biasanya dipanggil setelah update profil.
      await _syncProfileWithFirestore(user.uid); 
    } else {
      print("💪 [ConfigController] forceSyncProfile: No current user, will not sync.");
    }
  }
}