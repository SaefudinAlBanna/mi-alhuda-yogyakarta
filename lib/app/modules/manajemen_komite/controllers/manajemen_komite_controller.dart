// lib/app/modules/manajemen_komite/controllers/manajemen_komite_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/dashboard_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/komite_anggota_model.dart';
import 'package:mi_alhuda_yogyakarta/app/models/siswa_selection_model.dart';

class ManajemenKomiteController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final DashboardController dashboardC = Get.find<DashboardController>();

  final isLoading = true.obs;
  final isProcessing = false.obs;

  final canManageSekolah = false.obs;
  final canManageKelas = false.obs;
  final isKetuaKomiteSekolah = false.obs;

  final RxList<KomiteAnggotaModel> anggotaKomiteSekolah = <KomiteAnggotaModel>[].obs;
  final RxList<KomiteAnggotaModel> anggotaKomiteKelas = <KomiteAnggotaModel>[].obs;
  final RxnString kelasDiampuId = RxnString();

  final RxList<SiswaSelectionModel> _daftarSiswaMaster = <SiswaSelectionModel>[].obs;
  final RxList<SiswaSelectionModel> hasilPencarian = <SiswaSelectionModel>[].obs;
  final searchC = TextEditingController();

  bool get ketuaKomiteSudahAda => anggotaKomiteSekolah.any((p) => p.jabatan == 'Ketua Komite Sekolah');

  @override
  void onReady() {
    super.onReady();
    _initialize();
  }

  Future<void> _initialize() async {
    isLoading.value = true;
    _determineAccessRights();
    await _fetchDaftarSiswaMaster();
    await fetchData();
    isLoading.value = false;
  }

  Future<void> _fetchDaftarSiswaMaster() async {
    try {
      Query query = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where('statusSiswa', isEqualTo: 'Aktif');

      if (canManageKelas.value && !canManageSekolah.value && kelasDiampuId.value != null) {
        query = query.where('kelasId', isEqualTo: kelasDiampuId.value);
      }
      
      final snap = await query.get();
      
      _daftarSiswaMaster.assignAll(snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>?;
        return SiswaSelectionModel(
          uid: d.id,
          nama: data?['namaLengkap'] ?? 'Tanpa Nama',
          namaOrangTua: data?['namaOrangTuaTampil'] ?? 'Wali ${data?['namaLengkap'] ?? ''}',
          kelasId: data?['kelasId'] ?? 'N/A',
        );
      }));
    } catch (e) {
      Get.snackbar("Peringatan", "Gagal memuat daftar siswa untuk pencarian: ${e.toString()}");
    }
  }

  void _determineAccessRights() {
    final userProfile = configC.infoUser;
    final String peran = userProfile['role'] ?? '';
    canManageSekolah.value = peran == 'Kepala Sekolah';
    isKetuaKomiteSekolah.value = userProfile['peranKomite']?['jabatan'] == 'Ketua Komite Sekolah';
    final kelasWali = userProfile['waliKelasDari'] as String?;
    if (kelasWali != null && kelasWali.isNotEmpty) {
      canManageKelas.value = true;
      kelasDiampuId.value = kelasWali;
    }
  }

  Future<void> fetchData() async {
    isProcessing.value = true;
    try {
      final taAktif = configC.tahunAjaranAktif.value;
      if (canManageSekolah.value || isKetuaKomiteSekolah.value) {
        final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(taAktif)
            .collection('komite').doc('sekolah')
            .collection('anggota').orderBy('jabatan').get();
        final futures = snap.docs.map((d) async {
          final uidSiswa = d.id;
          final anggotaData = d.data();
          final siswaDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('siswa').doc(uidSiswa).get();
          final peranKomite = siswaDoc.data()?['peranKomite'] as Map<String, dynamic>?;
          return KomiteAnggotaModel(
            uidSiswa: uidSiswa,
            namaSiswa: anggotaData['namaSiswa'],
            namaOrangTua: peranKomite?['namaOrangTua'] ?? anggotaData['namaOrangTua'],
            jabatan: anggotaData['jabatan'],
            komiteId: 'sekolah',
          );
        }).toList();
        anggotaKomiteSekolah.assignAll(await Future.wait(futures));
      }
      if (canManageKelas.value && kelasDiampuId.value != null) {
        final namaKelas = kelasDiampuId.value!.split('-').first;
        final komiteId = namaKelas;
        final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(taAktif)
            .collection('komite').doc(komiteId)
            .collection('anggota').orderBy('jabatan').get();
        final futures = snap.docs.map((d) async {
          final uidSiswa = d.id;
          final anggotaData = d.data();
          final siswaDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('siswa').doc(uidSiswa).get();
          final peranKomite = siswaDoc.data()?['peranKomite'] as Map<String, dynamic>?;
          return KomiteAnggotaModel(
            uidSiswa: uidSiswa,
            namaSiswa: anggotaData['namaSiswa'],
            namaOrangTua: peranKomite?['namaOrangTua'] ?? anggotaData['namaOrangTua'],
            jabatan: anggotaData['jabatan'],
            komiteId: komiteId,
          );
        }).toList();
        anggotaKomiteKelas.assignAll(await Future.wait(futures));
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data komite: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> tambahAnggota(String komiteId, String jabatanDefault) async {
    final SiswaSelectionModel? siswaTerpilih = await _showSiswaSearchDialog();
    if (siswaTerpilih == null) return;
    String jabatanFinal = jabatanDefault;
    if (isKetuaKomiteSekolah.value && komiteId == 'sekolah' && jabatanDefault == "Anggota") {
      final String? selectedJabatan = await _showJabatanInputDialog();
      if (selectedJabatan == null || selectedJabatan.isEmpty) return;
      jabatanFinal = selectedJabatan;
    }
    isProcessing.value = true;
    try {
      final taAktif = configC.tahunAjaranAktif.value;
      final anggotaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc(komiteId) 
          .collection('anggota').doc(siswaTerpilih.uid);
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswaTerpilih.uid);
      final String kelasDiampuBase = (configC.infoUser['waliKelasDari'] as String?)?.trim().split('-').first ?? '';
      final WriteBatch batch = _firestore.batch();
      batch.set(anggotaRef, {
        'namaSiswa': siswaTerpilih.nama,
        'namaOrangTua': siswaTerpilih.namaOrangTua ?? 'Wali ${siswaTerpilih.nama}',
        'jabatan': jabatanFinal,
        'timestamp': FieldValue.serverTimestamp(),
        'waliKelasIdPenyimpan': kelasDiampuBase,
      });
      batch.update(siswaRef, {
        'peranKomite': {
          'jabatan': jabatanFinal,
          'namaOrangTua': siswaTerpilih.namaOrangTua ?? 'Wali ${siswaTerpilih.nama}',
        },
        'waliKelasIdPenyimpan': kelasDiampuBase,
      });
      await batch.commit();
      Get.snackbar("BERHASIL!", "${siswaTerpilih.nama} telah ditambahkan sebagai $jabatanFinal.");
      await fetchData();
    } catch (e) {
      Get.snackbar("Error", "Gagal menambah anggota: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> hapusAnggota(KomiteAnggotaModel anggota) async {
    isProcessing.value = true;
    try {
      final taAktif = configC.tahunAjaranAktif.value;
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(anggota.uidSiswa);
      final komiteId = anggota.komiteId.startsWith('kelas-') 
                       ? anggota.komiteId.split('-')[1] 
                       : anggota.komiteId;
      final anggotaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc(komiteId)
          .collection('anggota').doc(anggota.uidSiswa);
      final String kelasDiampuBase = (configC.infoUser['waliKelasDari'] as String?)?.trim().split('-').first ?? '';
      final WriteBatch batch = _firestore.batch();
      batch.delete(anggotaRef);
      batch.update(siswaRef, {
        'peranKomite': FieldValue.delete(),
        'waliKelasIdPenyimpan': kelasDiampuBase
      });
      await batch.commit();
      Get.snackbar("Berhasil", "${anggota.namaSiswa} telah dihapus dari jabatannya.");
      await fetchData();
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus anggota: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }
  
  Future<String?> _showJabatanInputDialog() async {
    final jabatanC = TextEditingController();
    final String? result = await Get.dialog(AlertDialog(
      title: const Text("Pilih Jabatan Anggota"),
        content: ObxValue((RxString jabatanTerpilih) {
            final List<String> daftarJabatan = [
              'Bendahara Komite Sekolah',
              'Sekretaris Komite Sekolah',
              'Anggota Divisi Pendidikan',
              'Anggota Divisi Humas',
              'Anggota Lainnya'
            ];
            return DropdownButton<String>(
              value: jabatanTerpilih.value,
              isExpanded: true,
              items: daftarJabatan.map((String jabatan) {
                return DropdownMenuItem<String>(
                  value: jabatan,
                  child: Text(jabatan),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  jabatanTerpilih.value = newValue;
                }
              },
            );
          }, 'Bendahara Komite Sekolah'.obs),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            // Kita perlu mengambil nilai dari RxString di dalam dialog
            final selectedJabatan = (Get.find<RxString>()).value;
            Get.back(result: selectedJabatan);
          },
          child: const Text("Simpan"),
        ),
      ],
    ));
    return result;
  }
  
  void _filterSiswaDialog() {
    final query = searchC.text.toLowerCase();
    if (query.isEmpty) {
      hasilPencarian.assignAll(_daftarSiswaMaster);
    } else {
      hasilPencarian.assignAll(_daftarSiswaMaster.where((siswa) {
        return siswa.nama.toLowerCase().contains(query);
      }));
    }
  }

  Future<SiswaSelectionModel?> _showSiswaSearchDialog() async {
    searchC.clear();
    hasilPencarian.assignAll(_daftarSiswaMaster);
    searchC.addListener(_filterSiswaDialog);

    final SiswaSelectionModel? result = await Get.dialog(
      AlertDialog(
        title: const Text("Cari & Pilih Siswa"),
        content: SizedBox(
          width: Get.width * 0.9,
          height: Get.height * 0.6,
          child: Column(
            children: [
              TextField(
                controller: searchC,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Ketik nama siswa...",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (hasilPencarian.isEmpty) {
                    return const Center(child: Text("Siswa tidak ditemukan."));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: hasilPencarian.length,
                    itemBuilder: (context, index) {
                      final siswa = hasilPencarian[index];
                      return ListTile(
                        title: Text(siswa.nama),
                        subtitle: Text("Kelas: ${siswa.kelasId.split('-').first}"),
                        onTap: () => Get.back(result: siswa),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    searchC.removeListener(_filterSiswaDialog);
    return result;
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }
}