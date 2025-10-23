// lib/app/controllers/dashboard_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';
import 'package:mi_alhuda_yogyakarta/app/models/carousel_item_model.dart';

import '../modules/home/pages/dashboard_page.dart';

class DashboardController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Properti Carousel ---
  final RxBool isCarouselLoading = true.obs;
  final RxList<CarouselItemModel> daftarCarousel = <CarouselItemModel>[].obs;

  StreamSubscription? _infoDashboardSubscription;
  final RxList<DocumentSnapshot> daftarInfoSekolah = <DocumentSnapshot>[].obs;

  final RxList<Map<String, dynamic>> quickAccessMenus = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> additionalMenus = <Map<String, dynamic>>[].obs;


  bool get isPimpinan {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final role = user['role'] ?? '';
    final tugas = List<String>.from(user['tugas'] ?? []);
    final peranSistem = user['peranSistem'] ?? '';
    return ['Kepala Sekolah', 'Koordinator Kurikulum', 'TU', 'Tata Usaha'].contains(role) || 
           tugas.contains('Admin') || 
           peranSistem == 'superadmin';
  }

  bool get isBendaharaOrPimpinan {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final role = user['role'] ?? '';
    final peranSistem = user['peranSistem'] ?? '';
    return ['Kepala Sekolah', 'Bendahara'].contains(role) || 
           peranSistem == 'superadmin';
  }

  bool get kepalaSekolah {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final role = user['role'] ?? '';
    return ['Kepala Sekolah'].contains(role);
  }

  bool get canManageHalaqah {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final String peranSistem = user['peranSistem'] ?? '';
    // final String role = user['role'] ?? '';
    final List<String> tugas = List<String>.from(user['tugas'] ?? []);
    // final bool hasRequiredRole = ['Kepala Sekolah', 'TU', 'Tata Usaha', 'Admin'].contains(role);
    final bool hasRequiredTugas = tugas.any((t) => ['Koordinator Halaqah Ikhwan', 'Koordinator Halaqah Akhwat', 'Koordinator Halaqah', 'Koordinator Kurikulum'].contains(t));
    // return peranSistem == 'superadmin' || hasRequiredRole || hasRequiredTugas;
    return peranSistem == 'superadmin' || hasRequiredTugas;
  }

  bool get isPengujiUmmi {
    final user = configC.infoUser;
    final List<String> tugas = List<String>.from(user['tugas'] ?? []);
    if (user.isEmpty) return false;
    // Kita akan membuat logic ini lebih dinamis nanti,
    // untuk sekarang kita asumsikan pimpinan juga penguji
    final bool hasRequiredTugas = tugas.any((t) => ['Koordinator Halaqah Ikhwan', 'Koordinator Halaqah Akhwat', 'Koordinator Halaqah'].contains(t));
    return isBendaharaOrPimpinan || hasRequiredTugas; 
  }

  bool get isPengampuHalaqah {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    return user.containsKey('grupHalaqahDiampu') && (user['grupHalaqahDiampu'] as Map).isNotEmpty;
  }

  bool get canManageEkskul {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final String peranSistem = user['peranSistem'] ?? '';
    final String role = user['role'] ?? '';
    final List<String> tugas = List<String>.from(user['tugas'] ?? []);
    final bool hasRequiredRole = ['Kepala Sekolah', 'TU', 'Tata Usaha'].contains(role);
    final bool hasRequiredTugas = tugas.contains('Koordinator Kurikulum');
    return peranSistem == 'superadmin' || hasRequiredRole || hasRequiredTugas;
  }

  bool get canManageKbm {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final String peranSistem = user['peranSistem'] ?? '';
    final String role = user['role'] ?? '';
    return ['Kepala Sekolah', 'Koordinator Kurikulum'].contains(role) || peranSistem == 'superadmin';
  }

  bool get canManageKomite {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final String peran = user['role'] ?? '';
    final String? kelasWali = user['waliKelasDari'] as String?;
    final String? peranKomite = user['peranKomite']?['jabatan'] as String?;

    return peran == 'Kepala Sekolah' || (kelasWali != null && kelasWali.isNotEmpty) || peranKomite == 'Ketua Komite Sekolah';
  }

  bool get isGuru {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final String role = user['role'] ?? '';
    return ['Guru Kelas', 'Guru Mapel'].contains(role);
  } 
  

   @override
  void onReady() {
    super.onReady();
    ever(configC.infoUser, (_) => _updateMenuLists());
    ever(configC.status, (AppStatus status) {
      if (status == AppStatus.authenticated) {
        fetchCarouselData();
        _listenToInfoDashboard();
        _updateMenuLists();
      } else {
        _infoDashboardSubscription?.cancel();
        _infoDashboardSubscription = null;
        daftarInfoSekolah.clear();
        _updateMenuLists();
      }
    });
    if (configC.status.value == AppStatus.authenticated) {
      fetchCarouselData();
      _listenToInfoDashboard();
      _updateMenuLists();
    }
  }

  @override
  void onClose() {
    _infoDashboardSubscription?.cancel();
    super.onClose();
  }

  void _updateMenuLists() {

    final bool canAccessBkDashboard = (configC.infoUser['waliKelasDari'] != null && (configC.infoUser['waliKelasDari'] as String).isNotEmpty) ||
                                 ['Kepala Sekolah'].contains(configC.infoUser['role']) ||
                                 (configC.infoUser['tugas'] as List? ?? []).contains('Kesiswaan');

    quickAccessMenus.clear();
    additionalMenus.clear();

    if (kepalaSekolah) {
        quickAccessMenus.add({'image': 'akademik_1.png', 'title': 'Laporan Akademik', 'route': Routes.LAPORAN_AKADEMIK});
        // quickAccessMenus.add({'image': 'akademik_2.png', 'title': 'Laporan Halaqah', 'route': Routes.LAPORAN_HALAQAH});
        quickAccessMenus.add({'image': 'akademik_2.png', 'title': 'Laporan Halaqah', 'route': Routes.HALAQAH_UMMI_DASHBOARD_KOORDINATOR});
        quickAccessMenus.add({'image': 'papan_list.png', 'title': 'Rekap Absensi', 'onTap': goToRekapAbsensiSekolah});
        quickAccessMenus.add({'image': 'kamera_layar.png', 'title': 'Jurnal Kelas', 'route': Routes.LAPORAN_JURNAL_KELAS});
    } else {
        quickAccessMenus.add({'image': 'daftar_tes.png', 'title': 'Guru Akademik', 'route': Routes.GURU_AKADEMIK});
        quickAccessMenus.add({'image': 'daftar_tes.png', 'title': 'Dashboard Halaqah', 'onTap': goToHalaqahDashboard});
        quickAccessMenus.add({'image': 'play.png', 'title': 'Jurnal Ajar', 'route': Routes.JURNAL_HARIAN_GURU});
        quickAccessMenus.add({'image': 'jurnal_ajar.png', 'title': 'Jurnal Pribadi', 'route': Routes.LAPORAN_JURNAL_PRIBADI});
    }

    if (isBendaharaOrPimpinan) {
      quickAccessMenus.add({'image': 'buku_uang.png', 'title': 'Pembayaran', 'route': Routes.CARI_SISWA_KEUANGAN});
    } else if (isGuru) {
      quickAccessMenus.add({'image': 'abc_papan.png', 'title': 'Perangkat Ajar', 'route': Routes.PERANGKAT_AJAR});
    }
    // quickAccessMenus.add({'image': 'daftar_list.png', 'title': 'Daftar Pegawai', 'route': Routes.PEGAWAI});
    // quickAccessMenus.add({'image': 'daftar_list.png', 'title': 'Daftar Siswa', 'route': Routes.DAFTAR_SISWA});

    quickAccessMenus.add({'image': 'layar.png', 'title': 'Jadwal Pelajaran', 'route': Routes.JADWAL_PELAJARAN});
    quickAccessMenus.add({'image': 'kamera_layar.png', 'title': 'Master Ekskul', 'route': Routes.MASTER_EKSKUL_MANAGEMENT});
    // quickAccessMenus.add({'image': 'akademik_2.png', 'title': 'Kalender Akademik', 'route': Routes.MANAJEMEN_KALENDER_AKADEMIK});
    quickAccessMenus.add({'image': 'faq.png', 'title': 'Lainnya', 'onTap': () => _showAllMenusInView(Get.context!)});

    if (canAccessBkDashboard) {
      additionalMenus.add({'image': 'jurnal_ajar.png', 'title': 'Dashboard BK', 'route': Routes.DASHBOARD_BK});
    }

    if (canManageKbm) {
      additionalMenus.add({'image': 'toga_lcd.png', 'title': 'Pemberian Kelas', 'route': Routes.PEMBERIAN_KELAS_SISWA});
      additionalMenus.add({'image': 'akademik_1.png', 'title': 'Manajemen Buku', 'route': Routes.MANAJEMEN_PENAWARAN_BUKU});
    }
    if (canManageHalaqah) {
      // additionalMenus.add({'image': 'daftar_tes.png', 'title': 'Manajemen Halaqah', 'route': Routes.HALAQAH_MANAGEMENT});
      // additionalMenus.add({'image': 'daftar_tes.png', 'title': 'Manajemen Halaqah', 'route': Routes.HALAQAH_UMMI_MANAGEMENT});
      // additionalMenus.add({'image': 'ktp.png', 'title': 'Kelola Penguji Ummi', 'route': Routes.HALAQAH_UMMI_MANAJEMEN_PENGUJI});
      // additionalMenus.add({'image': 'papan_list.png', 'title': 'Dashboard Ummi', 'route': Routes.HALAQAH_UMMI_DASHBOARD_KOORDINATOR});
    }
    if (isPengujiUmmi) {
      additionalMenus.add({'image': 'papan_list.png', 'title': 'Jadwal Ujian Ummi', 'route': Routes.HALAQAH_UMMI_JADWAL_PENGUJI});
    }
    additionalMenus.add({'image': 'daftar_list.png', 'title': 'Daftar Pegawai', 'route': Routes.PEGAWAI});
    additionalMenus.add({'image': 'pengumuman.png', 'title': 'Info Sekolah', 'route': Routes.INFO_SEKOLAH});
    // additionalMenus.add({'image': 'uang.png', 'title': 'Bayar SPP', 'route': null});
    // additionalMenus.add({'image': 'ktp.png', 'title': 'Tahsin/Tahfidz', 'route': null});
    // additionalMenus.add({'image': 'kamera_layar.png', 'title': 'Master Ekskul', 'route': Routes.MASTER_EKSKUL_MANAGEMENT});
    additionalMenus.add({'image': 'akademik_2.png', 'title': 'Kalender Akademik', 'route': Routes.MANAJEMEN_KALENDER_AKADEMIK});
    additionalMenus.add({'image': 'ktp.png', 'title': 'Laporan Pengganti', 'route': Routes.PUSAT_INFORMASI_PENGGANTIAN});
    // additionalMenus.add({'image': 'jurnal_ajar.png', 'title': 'Jurnal Pribadi', 'route': Routes.LAPORAN_JURNAL_PRIBADI});
    if (isPimpinan) {
      // additionalMenus.add({'image': 'kamera_layar.png', 'title': 'Jurnal Kelas', 'route': Routes.LAPORAN_JURNAL_KELAS});
    }
    // additionalMenus.add({'image': 'abc_papan.png', 'title': 'Perangkat Ajar', 'route': Routes.PERANGKAT_AJAR});
    if (canManageKbm) {
      additionalMenus.add({'image': 'emc2.png', 'title': 'Bobot Nilai', 'route': Routes.PENGATURAN_BOBOT_NILAI});
    }
    if (isPimpinan) {
      additionalMenus.add({'image': 'pengumuman.png', 'title': 'Pengaturan Akademik', 'route': Routes.PENGATURAN_AKADEMIK});
      // additionalMenus.add({'image': 'buku_uang.png', 'title': 'Pengaturan Biaya', 'route': Routes.PENGATURAN_AKADEMIK});
    }
    if (isBendaharaOrPimpinan) {
      // additionalMenus.add({'image': 'buku_uang.png', 'title': 'Pengaturan Biaya', 'route': Routes.PENGATURAN_BIAYA});
      // additionalMenus.add({'image': 'buku_uang.png', 'title': 'Buat tagihan', 'route': Routes.BUAT_TAGIHAN_TAHUNAN});
      // additionalMenus.add({'image': 'buku_uang.png', 'title': 'Pembayaran', 'route': Routes.CARI_SISWA_KEUANGAN});
      // additionalMenus.add({'image': 'buku_uang.png', 'title': 'Laporan Keuangan', 'route': Routes.LAPORAN_KEUANGAN});
    }

    if (canManageKomite) {
      // additionalMenus.add({'image': 'ktp.png', 'title': 'Manajemen Komite', 'route': Routes.MANAJEMEN_KOMITE});
    }
  }

  void _showAllMenusInView(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const Text("Semua Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: additionalMenus.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final menu = additionalMenus[index];
                  // [PERBAIKAN] Panggil static method dari DashboardView
                  return DashboardView.buildMenuItem(
                    imagePath: menu['image'],
                    title: menu['title'],
                    onTap: menu['route'] != null ? () => Get.toNamed(menu['route']) : menu['onTap'], // Use onTap if route is null
                  );
                },
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }


  void showPesanEditorDialog() {
    final Map<String, dynamic> config = configC.konfigurasiDashboard;
    final _pesanPimpinanC = TextEditingController(text: config['pesanPimpinan']?['pesan'] ?? '');
    final _pesanLiburC = TextEditingController(text: config['pesanDefaultLibur'] ?? '');
    final _pesanSelesaiC = TextEditingController(text: config['pesanDefaultSetelahKBM'] ?? '');
    
    final Rx<DateTime> berlakuHingga = Rx<DateTime>((config['pesanPimpinan']?['berlakuHingga'] as Timestamp?)?.toDate() ?? DateTime.now());
    final RxBool isMenyimpan = false.obs;

    Get.defaultDialog(
      title: "Edit Pesan Dasbor",
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      content: SizedBox(
        width: Get.width,
        height: Get.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pesan Pengumuman Penting (Prioritas #0)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _pesanPimpinanC,
                decoration: const InputDecoration(labelText: 'Isi Pesan', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Obx(() => ListTile(
                title: const Text("Berlaku Sampai"),
                subtitle: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(berlakuHingga.value)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: Get.context!,
                    initialDate: berlakuHingga.value,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    berlakuHingga.value = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                  }
                },
              )),
              const Divider(height: 24),

              const Text("Pesan Default Saat Libur (Prioritas #2)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _pesanLiburC,
                decoration: const InputDecoration(labelText: 'Isi Pesan Libur', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const Divider(height: 24),
              
              const Text("Pesan Default Setelah KBM Usai (Prioritas #6)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _pesanSelesaiC,
                decoration: const InputDecoration(labelText: 'Isi Pesan Selesai KBM', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isMenyimpan.value ? null : () {
          _simpanKonfigurasiDashboard(
            pesanPimpinan: _pesanPimpinanC.text,
            berlakuHingga: berlakuHingga.value,
            pesanLibur: _pesanLiburC.text,
            pesanSelesai: _pesanSelesaiC.text,
            isSaving: isMenyimpan,
          );
        },
        child: Text(isMenyimpan.value ? "Menyimpan..." : "Simpan Perubahan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  Future<void> _simpanKonfigurasiDashboard({
    required String pesanPimpinan,
    required DateTime berlakuHingga,
    required String pesanLibur,
    required String pesanSelesai,
    required RxBool isSaving,
  }) async {
    isSaving.value = true;
    try {
      final ref = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('konfigurasi_dashboard');

      await ref.set({
        'pesanPimpinan': {
          'pesan': pesanPimpinan,
          'berlakuHingga': Timestamp.fromDate(berlakuHingga),
        },
        'pesanDefaultLibur': pesanLibur,
        'pesanDefaultSetelahKBM': pesanSelesai,
      }, SetOptions(merge: true));

      Get.back();
      Get.snackbar("Berhasil", "Pesan dasbor berhasil diperbarui.");
      
      await configC.reloadKonfigurasiDashboard();
      await fetchCarouselData();

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan perubahan: $e");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchCarouselData() async {
    isCarouselLoading.value = true;
    try {
      final now = DateTime.now();
      final todayWithoutTime = DateTime(now.year, now.month, now.day);
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final String semester = configC.semesterAktif.value;
      final String namaHari = DateFormat('EEEE', 'id_ID').format(now);  

      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        daftarCarousel.clear();
        isCarouselLoading.value = false;
        return;
      } 

      final pesanPimpinan = configC.konfigurasiDashboard['pesanPimpinan'] as Map<String, dynamic>?;
      if (pesanPimpinan != null) {
        final berlakuHingga = (pesanPimpinan['berlakuHingga'] as Timestamp?)?.toDate();
        if (berlakuHingga != null && now.isBefore(berlakuHingga)) {
          daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Semua Staf & Guru", tipe: CarouselContentType.Prioritas, judul: "PENGUMUMAN PENTING", isi: pesanPimpinan['pesan'] as String? ?? '', ikon: Icons.campaign_rounded, warna: Colors.red.shade700) ]);
          isCarouselLoading.value = false; return;
        }
      } 

      final kalenderSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('kalender_akademik').where('tanggalMulai', isLessThanOrEqualTo: now).get();
      for (var doc in kalenderSnap.docs) {
        final data = doc.data();
        final tglSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
        if (todayWithoutTime.isBefore(tglSelesai.add(const Duration(days: 1)))) {
          final isLibur = data['isLibur'] as bool? ?? false;
          daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Info Sekolah", tipe: CarouselContentType.Info, judul: isLibur ? "HARI LIBUR" : "INFO KEGIATAN", isi: data['namaKegiatan'] as String? ?? 'Tanpa Judul', ikon: isLibur ? Icons.weekend_rounded : Icons.event_note_rounded, warna: isLibur ? Colors.red.shade400 : Colors.teal.shade700) ]);
          isCarouselLoading.value = false; return;
        }
      } 

      if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
        final String pesanLiburDariDb = configC.konfigurasiDashboard['pesanDefaultLibur'] as String? ?? "";
        final String pesanLiburFinal = pesanLiburDariDb.trim().isEmpty ? "Tetap semangat belajar dan muroja'ah yaa.." : pesanLiburDariDb;
        daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Info Sekolah", tipe: CarouselContentType.Default, judul: "SELAMAT BERAKHIR PEKAN", isi: pesanLiburFinal, ikon: Icons.beach_access_rounded, warna: Colors.blue.shade700) ]);
        isCarouselLoading.value = false; return;
      } 

      final Map<String, Map<String, dynamic>?> petaAbsensiRekap = {};  

      if (isPimpinan) {
        try {
          if (configC.infoUser.isEmpty) throw Exception("Profil belum siap.");
          
          final absensiRekapSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('tahunajaran').doc(tahunAjaran)
              .collection('kelastahunajaran').get()
              .then((snap) => Future.wait(snap.docs.map((doc) => 
                  doc.reference.collection('semester').doc(semester).collection('absensi').doc(DateFormat('yyyy-MM-dd').format(now)).get()
              )));
          
          for (var doc in absensiRekapSnap) {
            if (doc.exists) {
              petaAbsensiRekap[doc.reference.parent!.parent!.id] = doc.data() as Map<String, dynamic>?;
            }
          }
        } catch (e) {
          print("Info: Pengambilan data rekap absensi kelas dilewati untuk peran ini atau karena error: $e");
        }
      }

      final List<CarouselItemModel> carouselItems = [];
      final jadwalSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('jadwalkelas').get();
      final List<String> daftarKelas = jadwalSnap.docs.map((doc) => doc.id).toList()..sort();
      final nowTime = DateFormat("HH:mm").parse(DateFormat("HH:mm").format(now)); 

      for (String idKelas in daftarKelas) {
        final jadwalDoc = jadwalSnap.docs.firstWhere((doc) => doc.id == idKelas);
        final jadwalData = jadwalDoc.data() as Map<String, dynamic>;
        final listSlot = (jadwalData[namaHari] ?? jadwalData[namaHari.toLowerCase()]) as List? ?? [];
        listSlot.sort((a,b) => (a['jam'] as String).compareTo(b['jam'] as String)); 

        Map<String, dynamic>? slotBerlangsung;
        Map<String, dynamic>? slotBerikutnya;
        for (var slot in listSlot) { try { final timeParts = (slot['jam'] as String? ?? "00:00-00:00").split('-'); final startTime = DateFormat("HH:mm").parse(timeParts[0].trim()); final endTime = DateFormat("HH:mm").parse(timeParts[1].trim()); if (nowTime.isAtSameMomentAs(startTime) || (nowTime.isAfter(startTime) && nowTime.isBefore(endTime))) { slotBerlangsung = slot; break; } if (nowTime.isBefore(startTime) && slotBerikutnya == null) { slotBerikutnya = slot; } } catch(e) {} } 

        CarouselItemModel itemForThisClass;
        if (slotBerlangsung != null) {
          itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.KBM, judul: "Saat Ini Berlangsung", isi: slotBerlangsung['namaMapel'] ?? 'N/A', subJudul: "Oleh: ${slotBerlangsung['namaGuru'] ?? 'N/A'}", ikon: Icons.school_rounded, warna: Colors.indigo.shade700);
        } else if (slotBerikutnya != null) {
          itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.KBM, judul: "Pelajaran Berikutnya", isi: slotBerikutnya['namaMapel'] ?? 'N/A', subJudul: "Jam: ${slotBerikutnya['jam'] ?? 'N/A'}", ikon: Icons.update_rounded, warna: Colors.blue.shade700);
        } else {
          final absensiData = petaAbsensiRekap[idKelas];
          if (absensiData != null && absensiData['rekap'] != null) {
            final rekap = absensiData['rekap'];
            itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.Info, judul: "Kehadiran Hari Ini", isi: "H:${rekap['hadir']??0}, S:${rekap['sakit']??0}, I:${rekap['izin']??0}, A:${rekap['alfa']??0}", ikon: Icons.checklist_rtl_rounded, warna: Colors.green.shade800);
          } else {
            final String pesanSelesaiDariDb = configC.konfigurasiDashboard['pesanDefaultSetelahKBM'] as String? ?? ""; 
            final String pesanSelesaiFinal = pesanSelesaiDariDb.trim().isEmpty ? "Untuk Ustadz/Ustadzah, Selamat Beristirahat" : pesanSelesaiDariDb;
            itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.Default, judul: "KBM Selesai", isi: pesanSelesaiFinal, ikon: Icons.check_circle_outline_rounded, warna: Colors.indigo.shade400);
          }
        }
        carouselItems.add(itemForThisClass);
      }
      daftarCarousel.assignAll(carouselItems);  

    } catch (e) {
      print("### Gagal membangun carousel: $e");
      daftarCarousel.assignAll([ CarouselItemModel(namaKelas: "Error", tipe: CarouselContentType.Default, judul: "GAGAL MEMUAT DATA", isi: "Silakan muat ulang halaman.", ikon: Icons.error_outline_rounded, warna: Colors.grey.shade700) ]);
    } finally {
      isCarouselLoading.value = false;
    }
  }

  void _listenToInfoDashboard() {
    _infoDashboardSubscription?.cancel();
    
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    if (configC.status.value != AppStatus.authenticated || tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
      daftarInfoSekolah.clear();
      _infoDashboardSubscription = null;
      return;
    }

    _infoDashboardSubscription = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('info_sekolah')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots().listen((snapshot) {
            daftarInfoSekolah.assignAll(snapshot.docs);
        }, onError: (error) {
            print("Error listening to info_sekolah stream in DashboardController: $error");
            daftarInfoSekolah.clear();
        });
  }

  void cancelDashboardStreams() {
    _infoDashboardSubscription?.cancel();
    _infoDashboardSubscription = null;
    daftarInfoSekolah.clear();
  }

  void goToEkskulPendaftaran() => Get.toNamed(Routes.EKSKUL_PENDAFTARAN_MANAGEMENT);
  
  // void goToHalaqahManagement() => Get.toNamed(Routes.HALAQAH_MANAGEMENT); --> METODE AL-HUSNA
  void goToHalaqahManagement() => Get.toNamed(Routes.HALAQAH_UMMI_MANAGEMENT); // --> METODE UMMI
  void goToHalaqahDashboard() => Get.toNamed(Routes.HALAQAH_UMMI_DASHBOARD_PENGAMPU);
  
  void goToRekapAbsensiSekolah() {
    Get.toNamed(Routes.REKAP_ABSENSI, arguments: {'scope': 'sekolah'});
  }

  void goToAturGuruPengganti() {
    Get.toNamed(Routes.ATUR_GURU_PENGGANTI);
  }
}



////==========================================================

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
// import 'package:mi_alhuda_yogyakarta/app/models/dashboard_menu_model.dart';
// import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';
// import 'package:mi_alhuda_yogyakarta/app/models/carousel_item_model.dart';

// class DashboardController extends GetxController {
//   final ConfigController configC = Get.find<ConfigController>();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // --- Properti Carousel ---
//   final RxBool isCarouselLoading = true.obs;
//   final RxList<CarouselItemModel> daftarCarousel = <CarouselItemModel>[].obs;

//   // --- Properti Info Sekolah ---
//   StreamSubscription? _infoDashboardSubscription;
//   final RxList<DocumentSnapshot> daftarInfoSekolah = <DocumentSnapshot>[].obs;

//   // --- [PROPERTI BARU] untuk menu dinamis ---
//   final RxList<DashboardGroup> menuGroups = <DashboardGroup>[].obs;

//   // --- Getter umum yang masih relevan ---
//   bool get isPimpinan {
//     final user = configC.infoUser;
//     if (user.isEmpty) return false;
//     final role = user['role'] ?? '';
//     final tugas = List<String>.from(user['tugas'] ?? []);
//     final peranSistem = user['peranSistem'] ?? '';
//     return ['Kepala Sekolah'].contains(role) ||
//            tugas.contains('Koordinator Kurikulum') ||
//            peranSistem == 'superadmin';
//   }

//   bool get kepalaSekolah {
//     final user = configC.infoUser;
//     if (user.isEmpty) return false;
//     final role = user['role'] ?? '';
//     return ['Kepala Sekolah'].contains(role);
//   }

//   bool get isBendaharaOrPimpinan {
//     final user = configC.infoUser;
//     if (user.isEmpty) return false;
//     final role = user['role'] ?? '';
//     final peranSistem = user['peranSistem'] ?? '';
//     return ['Kepala Sekolah', 'Bendahara'].contains(role) ||
//            peranSistem == 'superadmin';
//   }

//   bool get canManageKbm {
//     final user = configC.infoUser;
//     if (user.isEmpty) return false;
//     final String peranSistem = user['peranSistem'] ?? '';
//     final String role = user['role'] ?? '';
//     final List<String> tugas = List<String>.from(user['tugas'] ?? []);
//     final bool hasRequiredRole = ['Kepala Sekolah'].contains(role);
//     final bool hasRequiredTugas = tugas.contains('Koordinator Kurikulum');
//     return peranSistem == 'superadmin' || hasRequiredRole || hasRequiredTugas;
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     // Gunakan 'ever' untuk mereaksi perubahan pada data pengguna atau konfigurasi
//     ever(configC.infoUser, (_) => _updateMenuLists());
//     ever(configC.konfigurasiDashboard, (_) => _updateMenuLists());

//     ever(configC.status, (AppStatus status) {
//       if (status == AppStatus.authenticated) {
//         fetchCarouselData();
//         _listenToInfoDashboard();
//         _updateMenuLists();
//       } else {
//         cancelDashboardStreams();
//         menuGroups.clear();
//       }
//     });

//     // Panggilan awal jika sudah authenticated
//     if (configC.status.value == AppStatus.authenticated) {
//       fetchCarouselData();
//       _listenToInfoDashboard();
//       _updateMenuLists();
//     }
//   }

//   @override
//   void onClose() {
//     cancelDashboardStreams();
//     super.onClose();
//   }

//   // --- [METODE UTAMA YANG DIUBAH] ---
//   void _updateMenuLists() {
//     final Map<String, dynamic> user = configC.infoUser;
//     final Map<String, dynamic> config = configC.konfigurasiDashboard;

//     if (user.isEmpty || config.isEmpty) {
//       menuGroups.clear();
//       return;
//     }

//     final String userRole = user['role']?.toString() ?? '';
//     final List<String> userTugas = List<String>.from(user['tugas'] ?? []);
//     final bool isSuperAdmin = user['peranSistem'] == 'superadmin';

//     final List<Map<String, dynamic>> groupConfigs = List<Map<String, dynamic>>.from(config['menu_groups'] ?? []);
//     final Map<String, dynamic> itemConfigs = Map<String, dynamic>.from(config['menu_items'] ?? {});

//     // Urutkan grup berdasarkan 'order'
//     groupConfigs.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

//     List<DashboardGroup> newMenuGroups = [];

//     for (var groupConfig in groupConfigs) {
//       String groupId = groupConfig['groupId'];
//       String groupTitle = groupConfig['title'];
//       List<DashboardItem> visibleItems = [];

//       // Filter item yang sesuai dengan groupId
//       itemConfigs.forEach((itemId, itemData) {
//         if (itemData['groupId'] == groupId) {
//           final List<String> allowedRoles = List<String>.from(itemData['roles'] ?? []);
//           final List<String> allowedTugas = List<String>.from(itemData['tugas'] ?? []);
          
//           bool hasAccess = isSuperAdmin || 
//                            allowedRoles.contains(userRole) || 
//                            userTugas.any((tugas) => allowedTugas.contains(tugas));

//           if (hasAccess) {
//             VoidCallback? onTapAction;
//             if (itemData['route'] == null) {
//               // Contoh penanganan onTap kustom jika diperlukan di masa depan
//             } else {
//               onTapAction = () => Get.toNamed(itemData['route'], arguments: itemData['args']);
//             }

//             visibleItems.add(DashboardItem(
//               id: itemId,
//               title: itemData['title'],
//               icon: itemData['icon'],
//               route: itemData['route'],
//               onTap: onTapAction,
//             ));
//           }
//         }
//       });
      
//       // Hanya tambahkan grup jika memiliki item yang terlihat
//       if (visibleItems.isNotEmpty) {
//         newMenuGroups.add(DashboardGroup(
//           title: groupTitle,
//           items: visibleItems,
//         ));
//       }
//     }
//     menuGroups.value = newMenuGroups;
//   }

//   // --- ( METODE LAIN TETAP SAMA: showPesanEditorDialog, _simpanKonfigurasiDashboard, fetchCarouselData, dll. ) ---
//   // ... (Salin semua metode lain dari file dashboard_controller.dart lama Anda ke sini)
//   // --- ( Pastikan Anda menyalin: ) ---
//   // void showPesanEditorDialog() { ... }
//   // Future<void> _simpanKonfigurasiDashboard(...) { ... }
//   // Future<void> fetchCarouselData() { ... }
//   // void _listenToInfoDashboard() { ... }
//   // void cancelDashboardStreams() { ... }
//   // --- ( JANGAN SALIN METODE LAMA SEPERTI goTo...() KARENA SUDAH TIDAK DIPERLUKAN ) ---
  
//   void showPesanEditorDialog() {
//     final Map<String, dynamic> config = configC.konfigurasiDashboard;
//     final _pesanPimpinanC = TextEditingController(text: config['pesanPimpinan']?['pesan'] ?? '');
//     final _pesanLiburC = TextEditingController(text: config['pesanDefaultLibur'] ?? '');
//     final _pesanSelesaiC = TextEditingController(text: config['pesanDefaultSetelahKBM'] ?? '');
    
//     final Rx<DateTime> berlakuHingga = Rx<DateTime>((config['pesanPimpinan']?['berlakuHingga'] as Timestamp?)?.toDate() ?? DateTime.now());
//     final RxBool isMenyimpan = false.obs;

//     Get.defaultDialog(
//       title: "Edit Pesan Dasbor",
//       titlePadding: const EdgeInsets.all(20),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 20),
//       content: SizedBox(
//         width: Get.width,
//         height: Get.height * 0.6,
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text("Pesan Pengumuman Penting (Prioritas #0)", style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _pesanPimpinanC,
//                 decoration: const InputDecoration(labelText: 'Isi Pesan', border: OutlineInputBorder()),
//                 maxLines: 3,
//               ),
//               const SizedBox(height: 8),
//               Obx(() => ListTile(
//                 title: const Text("Berlaku Sampai"),
//                 subtitle: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(berlakuHingga.value)),
//                 trailing: const Icon(Icons.calendar_today),
//                 onTap: () async {
//                   final picked = await showDatePicker(
//                     context: Get.context!,
//                     initialDate: berlakuHingga.value,
//                     firstDate: DateTime.now(),
//                     lastDate: DateTime.now().add(const Duration(days: 30)),
//                   );
//                   if (picked != null) {
//                     berlakuHingga.value = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
//                   }
//                 },
//               )),
//               const Divider(height: 24),

//               const Text("Pesan Default Saat Libur (Prioritas #2)", style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _pesanLiburC,
//                 decoration: const InputDecoration(labelText: 'Isi Pesan Libur', border: OutlineInputBorder()),
//                 maxLines: 2,
//               ),
//               const Divider(height: 24),
              
//               const Text("Pesan Default Setelah KBM Usai (Prioritas #6)", style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _pesanSelesaiC,
//                 decoration: const InputDecoration(labelText: 'Isi Pesan Selesai KBM', border: OutlineInputBorder()),
//                 maxLines: 2,
//               ),
//             ],
//           ),
//         ),
//       ),
//       confirm: Obx(() => ElevatedButton(
//         onPressed: isMenyimpan.value ? null : () {
//           _simpanKonfigurasiDashboard(
//             pesanPimpinan: _pesanPimpinanC.text,
//             berlakuHingga: berlakuHingga.value,
//             pesanLibur: _pesanLiburC.text,
//             pesanSelesai: _pesanSelesaiC.text,
//             isSaving: isMenyimpan,
//           );
//         },
//         child: Text(isMenyimpan.value ? "Menyimpan..." : "Simpan Perubahan"),
//       )),
//       cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
//     );
//   }

//   Future<void> _simpanKonfigurasiDashboard({
//     required String pesanPimpinan,
//     required DateTime berlakuHingga,
//     required String pesanLibur,
//     required String pesanSelesai,
//     required RxBool isSaving,
//   }) async {
//     isSaving.value = true;
//     try {
//       final ref = _firestore.collection('Sekolah').doc(configC.idSekolah)
//           .collection('pengaturan').doc('konfigurasi_dashboard');

//       await ref.set({
//         'pesanPimpinan': {
//           'pesan': pesanPimpinan,
//           'berlakuHingga': Timestamp.fromDate(berlakuHingga),
//         },
//         'pesanDefaultLibur': pesanLibur,
//         'pesanDefaultSetelahKBM': pesanSelesai,
//       }, SetOptions(merge: true));

//       Get.back();
//       Get.snackbar("Berhasil", "Pesan dasbor berhasil diperbarui.");
      
//       await configC.reloadKonfigurasiDashboard();
//       await fetchCarouselData();

//     } catch (e) {
//       Get.snackbar("Error", "Gagal menyimpan perubahan: $e");
//     } finally {
//       isSaving.value = false;
//     }
//   }

//   Future<void> fetchCarouselData() async {
//     isCarouselLoading.value = true;
//     try {
//       final now = DateTime.now();
//       final todayWithoutTime = DateTime(now.year, now.month, now.day);
//       final String tahunAjaran = configC.tahunAjaranAktif.value;
//       final String semester = configC.semesterAktif.value;
//       final String namaHari = DateFormat('EEEE', 'id_ID').format(now);  

//       if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
//         daftarCarousel.clear();
//         isCarouselLoading.value = false;
//         return;
//       } 

//       final pesanPimpinan = configC.konfigurasiDashboard['pesanPimpinan'] as Map<String, dynamic>?;
//       if (pesanPimpinan != null) {
//         final berlakuHingga = (pesanPimpinan['berlakuHingga'] as Timestamp?)?.toDate();
//         if (berlakuHingga != null && now.isBefore(berlakuHingga)) {
//           daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Semua Staf & Guru", tipe: CarouselContentType.Prioritas, judul: "PENGUMUMAN PENTING", isi: pesanPimpinan['pesan'] as String? ?? '', ikon: Icons.campaign_rounded, warna: Colors.red.shade700) ]);
//           isCarouselLoading.value = false; return;
//         }
//       } 

//       final kalenderSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('kalender_akademik').where('tanggalMulai', isLessThanOrEqualTo: now).get();
//       for (var doc in kalenderSnap.docs) {
//         final data = doc.data();
//         final tglSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
//         if (todayWithoutTime.isBefore(tglSelesai.add(const Duration(days: 1)))) {
//           final isLibur = data['isLibur'] as bool? ?? false;
//           daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Info Sekolah", tipe: CarouselContentType.Info, judul: isLibur ? "HARI LIBUR" : "INFO KEGIATAN", isi: data['namaKegiatan'] as String? ?? 'Tanpa Judul', ikon: isLibur ? Icons.weekend_rounded : Icons.event_note_rounded, warna: isLibur ? Colors.red.shade400 : Colors.teal.shade700) ]);
//           isCarouselLoading.value = false; return;
//         }
//       } 

//       if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
//         final String pesanLiburDariDb = configC.konfigurasiDashboard['pesanDefaultLibur'] as String? ?? "";
//         final String pesanLiburFinal = pesanLiburDariDb.trim().isEmpty ? "Tetap semangat belajar dan muroja'ah yaa.." : pesanLiburDariDb;
//         daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Info Sekolah", tipe: CarouselContentType.Default, judul: "SELAMAT BERAKHIR PEKAN", isi: pesanLiburFinal, ikon: Icons.beach_access_rounded, warna: Colors.blue.shade700) ]);
//         isCarouselLoading.value = false; return;
//       } 

//       final Map<String, Map<String, dynamic>?> petaAbsensiRekap = {};  

//       if (isPimpinan) {
//         try {
//           if (configC.infoUser.isEmpty) throw Exception("Profil belum siap.");
          
//           final absensiRekapSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//               .collection('tahunajaran').doc(tahunAjaran)
//               .collection('kelastahunajaran').get()
//               .then((snap) => Future.wait(snap.docs.map((doc) => 
//                   doc.reference.collection('semester').doc(semester).collection('absensi').doc(DateFormat('yyyy-MM-dd').format(now)).get()
//               )));
          
//           for (var doc in absensiRekapSnap) {
//             if (doc.exists) {
//               petaAbsensiRekap[doc.reference.parent!.parent!.id] = doc.data() as Map<String, dynamic>?;
//             }
//           }
//         } catch (e) {
//           print("Info: Pengambilan data rekap absensi kelas dilewati untuk peran ini atau karena error: $e");
//         }
//       }

//       final List<CarouselItemModel> carouselItems = [];
//       final jadwalSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('jadwalkelas').get();
//       final List<String> daftarKelas = jadwalSnap.docs.map((doc) => doc.id).toList()..sort();
//       final nowTime = DateFormat("HH:mm").parse(DateFormat("HH:mm").format(now)); 

//       for (String idKelas in daftarKelas) {
//         final jadwalDoc = jadwalSnap.docs.firstWhere((doc) => doc.id == idKelas);
//         final jadwalData = jadwalDoc.data() as Map<String, dynamic>;
//         final listSlot = (jadwalData[namaHari] ?? jadwalData[namaHari.toLowerCase()]) as List? ?? [];
//         listSlot.sort((a,b) => (a['jam'] as String).compareTo(b['jam'] as String)); 

//         Map<String, dynamic>? slotBerlangsung;
//         Map<String, dynamic>? slotBerikutnya;
//         for (var slot in listSlot) { try { final timeParts = (slot['jam'] as String? ?? "00:00-00:00").split('-'); final startTime = DateFormat("HH:mm").parse(timeParts[0].trim()); final endTime = DateFormat("HH:mm").parse(timeParts[1].trim()); if (nowTime.isAtSameMomentAs(startTime) || (nowTime.isAfter(startTime) && nowTime.isBefore(endTime))) { slotBerlangsung = slot; break; } if (nowTime.isBefore(startTime) && slotBerikutnya == null) { slotBerikutnya = slot; } } catch(e) {} } 

//         CarouselItemModel itemForThisClass;
//         if (slotBerlangsung != null) {
//           itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.KBM, judul: "Saat Ini Berlangsung", isi: slotBerlangsung['namaMapel'] ?? 'N/A', subJudul: "Oleh: ${slotBerlangsung['namaGuru'] ?? 'N/A'}", ikon: Icons.school_rounded, warna: Colors.indigo.shade700);
//         } else if (slotBerikutnya != null) {
//           itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.KBM, judul: "Pelajaran Berikutnya", isi: slotBerikutnya['namaMapel'] ?? 'N/A', subJudul: "Jam: ${slotBerikutnya['jam'] ?? 'N/A'}", ikon: Icons.update_rounded, warna: Colors.blue.shade700);
//         } else {
//           final absensiData = petaAbsensiRekap[idKelas];
//           if (absensiData != null && absensiData['rekap'] != null) {
//             final rekap = absensiData['rekap'];
//             itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.Info, judul: "Kehadiran Hari Ini", isi: "H:${rekap['hadir']??0}, S:${rekap['sakit']??0}, I:${rekap['izin']??0}, A:${rekap['alfa']??0}", ikon: Icons.checklist_rtl_rounded, warna: Colors.green.shade800);
//           } else {
//             final String pesanSelesaiDariDb = configC.konfigurasiDashboard['pesanDefaultSetelahKBM'] as String? ?? ""; 
//             final String pesanSelesaiFinal = pesanSelesaiDariDb.trim().isEmpty ? "Untuk Ustadz/Ustadzah, Selamat Beristirahat" : pesanSelesaiDariDb;
//             itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.Default, judul: "KBM Selesai", isi: pesanSelesaiFinal, ikon: Icons.check_circle_outline_rounded, warna: Colors.indigo.shade400);
//           }
//         }
//         carouselItems.add(itemForThisClass);
//       }
//       daftarCarousel.assignAll(carouselItems);  

//     } catch (e) {
//       print("### Gagal membangun carousel: $e");
//       daftarCarousel.assignAll([ CarouselItemModel(namaKelas: "Error", tipe: CarouselContentType.Default, judul: "GAGAL MEMUAT DATA", isi: "Silakan muat ulang halaman.", ikon: Icons.error_outline_rounded, warna: Colors.grey.shade700) ]);
//     } finally {
//       isCarouselLoading.value = false;
//     }
//   }

//   void _listenToInfoDashboard() {
//     _infoDashboardSubscription?.cancel();
    
//     final String tahunAjaran = configC.tahunAjaranAktif.value;
//     if (configC.status.value != AppStatus.authenticated || tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
//       daftarInfoSekolah.clear();
//       _infoDashboardSubscription = null;
//       return;
//     }

//     _infoDashboardSubscription = _firestore.collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaran)
//         .collection('info_sekolah')
//         .orderBy('timestamp', descending: true)
//         .limit(5)
//         .snapshots().listen((snapshot) {
//             daftarInfoSekolah.assignAll(snapshot.docs);
//         }, onError: (error) {
//             print("Error listening to info_sekolah stream in DashboardController: $error");
//             daftarInfoSekolah.clear();
//         });
//   }

//   void cancelDashboardStreams() {
//     _infoDashboardSubscription?.cancel();
//     _infoDashboardSubscription = null;
//     daftarInfoSekolah.clear();
//   }
// }