// lib/app/modules/create_edit_halaqah_ummi_group/controllers/create_edit_halaqah_ummi_group_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../models/pegawai_simple_model.dart';
import '../../../models/siswa_simple_model.dart';

class CreateEditHalaqahGroupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isEditMode = false.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  String? groupId;
  
  final namaGrupC = TextEditingController();
  final lokasiC = TextEditingController();
  final RxString selectedFase = "A".obs;
  final Rxn<PegawaiSimpleModel> selectedPengampu = Rxn<PegawaiSimpleModel>();
  
  final List<PegawaiSimpleModel> _allPengampu = [];
  final RxList<PegawaiSimpleModel> availablePengampu = <PegawaiSimpleModel>[].obs;

  final RxList<String> daftarKelas = <String>[].obs;
  final RxString selectedKelasFilter = "".obs;
  final RxList<SiswaSimpleModel> anggotaGrup = <SiswaSimpleModel>[].obs;
  final RxList<SiswaSimpleModel> siswaTersedia = <SiswaSimpleModel>[].obs;

  String? _initialPengampuId;
  late String tahunAjaran;
  List<SiswaSimpleModel> _initialMembers = []; 

  // [BARU] Daftar opsi untuk progresi (bisa dipindah ke Firestore nanti)
  final List<String> opsiTingkat = ['Jilid', 'Tahfidz', 'Turjuman', 'Ghorib'];
  final List<String> opsiDetailJilid = ['1', '2', '3', '4', '5', '6'];

  @override
  void onInit() {
    super.onInit();
    final dynamic argument = Get.arguments;
    if (argument is HalaqahGroupUmmiModel) {
      isEditMode.value = true;
      groupId = argument.id;
    }
    tahunAjaran = configC.tahunAjaranAktif.value;
    _loadInitialData(argument as HalaqahGroupUmmiModel?);
  }

  Future<void> _loadInitialData(HalaqahGroupUmmiModel? group) async {
    isLoading.value = true;
    try {
      await _fetchEligiblePengampu();
      await _fetchAvailableClasses();
      if (isEditMode.value && group != null) {
        await _loadGroupDataForEdit(group);
      } else {
        filterAvailablePengampu();
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchEligiblePengampu() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
    final List<PegawaiSimpleModel> eligible = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final role = data['role'] as String? ?? '';
      final tugas = List<String>.from(data['tugas'] ?? []);
      if (role == 'Pengampu' || tugas.contains('Pengampu')) {
        eligible.add(PegawaiSimpleModel.fromFirestore(doc));
      }
    }
    eligible.sort((a, b) => a.nama.compareTo(b.nama));
    _allPengampu.assignAll(eligible);
  }

  Future<void> filterAvailablePengampu() async {
    final groupsSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup_ummi').get();

    final assignedPengampuIdsInFase = groupsSnapshot.docs
        .where((doc) => doc.data()['fase'] == selectedFase.value)
        .where((doc) => isEditMode.value ? doc.id != groupId : true)
        .map((doc) => doc.data()['idPengampu'] as String)
        .toSet();

    final filteredList = _allPengampu
        .where((p) => !assignedPengampuIdsInFase.contains(p.uid))
        .toList();

    availablePengampu.assignAll(filteredList);

    if (selectedPengampu.value != null && !availablePengampu.any((p) => p.uid == selectedPengampu.value!.uid)) {
      selectedPengampu.value = null;
    }
  }

  Future<void> _fetchAvailableClasses() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaran).get();
    final classNames = snapshot.docs.map((doc) => doc.data()['namaKelas'] as String).toSet();
    daftarKelas.assignAll(classNames.toList()..sort());
  }

  Future<void> _loadGroupDataForEdit(HalaqahGroupUmmiModel group) async {
    namaGrupC.text = group.namaGrup;
    lokasiC.text = group.lokasiDefault;
    selectedFase.value = group.fase;
    _initialPengampuId = group.idPengampu;

    await filterAvailablePengampu(); 
    
    selectedPengampu.value = _allPengampu.firstWhereOrNull((p) => p.uid == group.idPengampu);

    final memberSnapshot = await _firestore
      .collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaran)
      .collection('halaqah_grup_ummi').doc(group.id).collection('anggota')
      .get();
    
    // Ambil data lengkap siswa untuk mendapatkan progresi awal
    List<SiswaSimpleModel> members = [];
    for (var memberDoc in memberSnapshot.docs) {
        final siswaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(memberDoc.id).get();
        if(siswaSnapshot.exists) {
            members.add(SiswaSimpleModel.fromFirestore(siswaSnapshot));
        }
    }

    anggotaGrup.assignAll(members);
    _initialMembers = List.from(anggotaGrup);
  }

  void onFaseChanged(String newFase) {
    selectedFase.value = newFase;
    filterAvailablePengampu();
  }
  
  Future<void> fetchAvailableStudentsByClass(String namaKelas) async {
    selectedKelasFilter.value = namaKelas;
    siswaTersedia.clear();

    final grupSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran).collection('halaqah_grup_ummi').get();

    final Set<String> siswaSudahPunyaGrup = {};
    for (var groupDoc in grupSnapshot.docs) {
      final anggotaSnapshot = await groupDoc.reference.collection('anggota').get();
      for (var anggotaDoc in anggotaSnapshot.docs) {
        siswaSudahPunyaGrup.add(anggotaDoc.id);
      }
    }

    final kelasId = '$namaKelas-$tahunAjaran';
    final siswaDiKelasSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah).collection('siswa')
        .where('kelasId', isEqualTo: kelasId)
        .get();
    
    final List<SiswaSimpleModel> siswaYangTersedia = [];
    for (var doc in siswaDiKelasSnapshot.docs) {
      if (!siswaSudahPunyaGrup.contains(doc.id)) {
        siswaYangTersedia.add(SiswaSimpleModel.fromFirestore(doc));
      }
    }
    siswaTersedia.assignAll(siswaYangTersedia);
  }

  void addSiswaToGroup(SiswaSimpleModel siswa) {
    siswaTersedia.removeWhere((s) => s.uid == siswa.uid);
    anggotaGrup.add(siswa);
  }

  void removeSiswaFromGroup(SiswaSimpleModel siswa) {
    anggotaGrup.removeWhere((s) => s.uid == siswa.uid);
    if (siswa.kelasId.startsWith(selectedKelasFilter.value)) {
      siswaTersedia.add(siswa);
    }
  }

  // [FUNGSI YANG HILANG SEBELUMNYA ADA DI SINI]
  void showEditProgresDialog(SiswaSimpleModel siswa) {
    final RxString tempTingkat = siswa.tingkat.obs;
    final RxString tempDetailTingkat = siswa.detailTingkat.obs;
    final detailController = TextEditingController(text: siswa.detailTingkat);

    Get.defaultDialog(
      title: "Edit Progres ${siswa.nama}",
      content: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: tempTingkat.value,
            items: opsiTingkat.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) {
              if (val != null) {
                tempTingkat.value = val;
                if (val == 'Jilid') {
                  tempDetailTingkat.value = '1';
                  detailController.text = '1';
                }
              }
            },
            decoration: const InputDecoration(labelText: "Tingkat", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (tempTingkat.value == 'Jilid')
            DropdownButtonFormField<String>(
              value: tempDetailTingkat.value.isNotEmpty ? tempDetailTingkat.value : null,
              items: opsiDetailJilid.map((d) => DropdownMenuItem(value: d, child: Text("Jilid $d"))).toList(),
              onChanged: (val) {
                if (val != null) {
                  tempDetailTingkat.value = val;
                  detailController.text = val;
                }
              },
              decoration: const InputDecoration(labelText: "Detail Tingkat", border: OutlineInputBorder()),
            )
          else 
            TextFormField(
              controller: detailController,
              onChanged: (val) => tempDetailTingkat.value = val,
              decoration: const InputDecoration(labelText: "Detail (contoh: An-Naba', 15)", border: OutlineInputBorder()),
            ),
        ],
      )),
      onConfirm: () {
        final siswaDiGrup = anggotaGrup.firstWhere((s) => s.uid == siswa.uid);
        siswaDiGrup.tingkat = tempTingkat.value;
        siswaDiGrup.detailTingkat = tempDetailTingkat.value;
        anggotaGrup.refresh();
        Get.back();
      },
      textConfirm: "Simpan",
      textCancel: "Batal",
    );
  }

  Future<void> saveGroup() async {
    if (selectedPengampu.value == null || namaGrupC.text.trim().isEmpty || lokasiC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Nama grup, lokasi, dan pengampu wajib diisi.");
      return;
    }
    
    isSaving.value = true;
    try {
      final WriteBatch batch = _firestore.batch();
      final groupRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('halaqah_grup_ummi').doc(groupId);
  
      batch.set(groupRef, {
        'namaGrup': namaGrupC.text.trim(), 'fase': selectedFase.value,
        'lokasiDefault': lokasiC.text.trim(), 'idPengampu': selectedPengampu.value!.uid,
        'namaPengampu': selectedPengampu.value!.displayName, 'semester': configC.semesterAktif.value,
      }, SetOptions(merge: true));
      
      final initialMemberIds = _initialMembers.map((s) => s.uid).toSet();
      final finalMemberIds = anggotaGrup.map((s) => s.uid).toSet();
      
      final siswaYangDitambahkan = anggotaGrup.where((s) => !initialMemberIds.contains(s.uid)).toList();
      final siswaYangDihapus = _initialMembers.where((s) => !finalMemberIds.contains(s.uid)).toList();
      final siswaYangTetap = anggotaGrup.where((s) => initialMemberIds.contains(s.uid)).toList();

      for (var siswa in siswaYangDitambahkan) {
        final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        batch.set(groupRef.collection('anggota').doc(siswa.uid), {
          'namaSiswa': siswa.nama, 'kelasAsal': siswa.kelasId, 'tahunAjaran': tahunAjaran,
        });
        
        batch.update(siswaRef, {
          'halaqahUmmi.idGrup': groupRef.id, 'halaqahUmmi.tahunAjaran': tahunAjaran,
          'halaqahUmmi.faseGrup': selectedFase.value, 'halaqahUmmi.namaPengampu': selectedPengampu.value!.displayName,
          'halaqahUmmi.progres': { 'tingkat': siswa.tingkat, 'detailTingkat': siswa.detailTingkat, 'halaman': 1 },
          'halaqahUmmi.tanggalSetoranTerakhir': null, 'halaqahUmmi.statusUjian': FieldValue.delete(),
        });
      }
  
      for (var siswa in siswaYangDihapus) {
        final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        batch.delete(groupRef.collection('anggota').doc(siswa.uid));
        batch.update(siswaRef, {'halaqahUmmi': FieldValue.delete()});
      }

      for (var siswa in siswaYangTetap) {
        final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        batch.update(siswaRef, {
          'halaqahUmmi.progres.tingkat': siswa.tingkat,
          'halaqahUmmi.progres.detailTingkat': siswa.detailTingkat,
        });
      }
      
      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "Grup halaqah Ummi berhasil disimpan.");
  
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan grup: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }
}


// // lib/app/modules/create_edit_halaqah_group/controllers/create_edit_halaqah_group_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_simple_model.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';

// import '../../../models/halaqah_group_model.dart';

// class CreateEditHalaqahGroupController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();

//   // State
//   final isEditMode = false.obs;
//   final isLoading = true.obs;
//   final isSaving = false.obs;
//   String? groupId;

//   // Form State
//   final namaGrupC = TextEditingController();
//   final Rxn<PegawaiSimpleModel> selectedPengampu = Rxn<PegawaiSimpleModel>();
//   final RxList<PegawaiSimpleModel> daftarPengampu = <PegawaiSimpleModel>[].obs;
//   final RxList<String> daftarKelas = <String>[].obs;
//   final RxString selectedKelasFilter = "".obs;

//   // Student Lists State
//   final RxList<SiswaSimpleModel> anggotaGrup = <SiswaSimpleModel>[].obs;
//   final RxList<SiswaSimpleModel> siswaTersedia = <SiswaSimpleModel>[].obs;

//   String? _initialPengampuId; 
  
//   // Helpers
//   late String tahunAjaran;
//   late String semester;
//   late String fieldGrupSiswa;
//   List<SiswaSimpleModel> _initialMembers = [];


//   @override
//   void onInit() {
//     super.onInit();
//     final dynamic argument = Get.arguments;
//     if (argument is HalaqahGroupModel) {
//       isEditMode.value = true;
//       groupId = argument.id;
//     }
    
//     tahunAjaran = configC.tahunAjaranAktif.value;
//     semester = configC.semesterAktif.value;
//     fieldGrupSiswa = "grupHalaqah.$tahunAjaran\_$semester";

//     _loadInitialData(argument as HalaqahGroupModel?);
//   }

//   Future<void> _loadInitialData(HalaqahGroupModel? group) async {
//     isLoading.value = true;
//     try {
//       await _fetchEligiblePengampu();
//       await _fetchAvailableClasses();
//       if (isEditMode.value && group != null) {
//         await loadGroupDataForEdit(group);
//       }
//     } catch (e) { Get.snackbar("Error", "Gagal memuat data awal: $e"); } 
//     finally { isLoading.value = false; }
//   }

//   Future<void> _fetchEligiblePengampu() async {
//     // [FIX] Ambil SEMUA pegawai terlebih dahulu
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//       .collection('pegawai')
//       .get();

//     // [FIX] Lakukan penyaringan di dalam aplikasi untuk fleksibilitas
//     final List<PegawaiSimpleModel> eligiblePengampu = [];
//     for (var doc in snapshot.docs) {
//       final data = doc.data();
//       final role = data['role'] as String? ?? '';
//       final tugas = List<String>.from(data['tugas'] ?? []);

//       // Cek semua kondisi yang Anda berikan
//       if (role == 'Pengampu' || 
//           tugas.contains('Pengampu') || 
//           tugas.contains('Koordinator Halaqah Ikhwan') || 
//           tugas.contains('Koordinator Halaqah Akhwat')) {
//         eligiblePengampu.add(PegawaiSimpleModel.fromFirestore(doc));
//       }
//     }
    
//     // Urutkan berdasarkan nama untuk tampilan yang rapi
//     eligiblePengampu.sort((a, b) => a.nama.compareTo(b.nama));
    
//     daftarPengampu.assignAll(eligiblePengampu);
//   }

//   Future<void> _fetchAvailableClasses() async {
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').get();
//     daftarKelas.assignAll(snapshot.docs.map((doc) => doc.id).toList()..sort());
//   }

//   Future<void> loadGroupDataForEdit(HalaqahGroupModel group) async {
//     namaGrupC.text = group.namaGrup;
//     selectedPengampu.value = daftarPengampu.firstWhereOrNull((p) => p.uid == group.idPengampu);
//     _initialPengampuId = group.idPengampu; // Simpan ID pengampu lama

//     final memberSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//       .collection('tahunajaran').doc(tahunAjaran)
//       .collection('halaqah_grup').doc(group.id).collection('anggota').get();
      
//     anggotaGrup.assignAll(memberSnapshot.docs.map((doc) {
//       final data = doc.data();
//       return SiswaSimpleModel.fromFirestore(doc);
//       // return SiswaSimpleModel(uid: doc.id, nama: data['namaSiswa'], kelasId: data['kelasAsal']);
//     }).toList());
//     _initialMembers = List.from(anggotaGrup);
//   }

//   Future<void> fetchAvailableStudentsByClass(String kelasId) async {
//     selectedKelasFilter.value = kelasId;
//     siswaTersedia.clear();

//     // --- [FIX] LANGKAH 1: Ambil SEMUA siswa di kelas, HAPUS filter grupHalaqah ---
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//       .collection('siswa')
//       .where('kelasId', isGreaterThanOrEqualTo: kelasId)
//       .where('kelasId', isLessThan: '$kelasId\uf8ff')
//       .get();
      
//     // --- [FIX] LANGKAH 2: Lakukan penyaringan di sini, di dalam aplikasi ---
//     final keySemester = "$tahunAjaran\_$semester";
//     final List<SiswaSimpleModel> availableStudents = [];

//     for (var doc in snapshot.docs) {
//       final data = doc.data();
//       // Cek apakah map 'grupHalaqah' ada, dan apakah key untuk semester ini ada di dalamnya.
//       if (!data.containsKey('grupHalaqah') || !(data['grupHalaqah'] as Map).containsKey(keySemester)) {
//         // Jika tidak ada, berarti siswa ini tersedia.
//         availableStudents.add(SiswaSimpleModel.fromFirestore(doc));
//       }
//     }
    
//     siswaTersedia.assignAll(availableStudents);
//   }

//   void addSiswaToGroup(SiswaSimpleModel siswa) {
//     siswaTersedia.removeWhere((s) => s.uid == siswa.uid);
//     anggotaGrup.add(siswa);
//   }

//   void removeSiswaFromGroup(SiswaSimpleModel siswa) {
//     anggotaGrup.removeWhere((s) => s.uid == siswa.uid);
//     // If the removed student belongs to the currently filtered class, add them back
//     if (siswa.kelasId == selectedKelasFilter.value) {
//       siswaTersedia.add(siswa);
//     }
//   }

//   Future<void> saveGroup() async {
//     // 1. Validasi Input Awal
//     if (selectedPengampu.value == null) {
//       Get.snackbar("Peringatan", "Silakan pilih pengampu terlebih dahulu.");
//       return;
//     }
//     if (namaGrupC.text.trim().isEmpty) {
//       Get.snackbar("Peringatan", "Nama grup tidak boleh kosong.");
//       return;
//     }
    
//     isSaving.value = true;
//     try {
//       // 2. Inisialisasi Batch dan Referensi
//       final WriteBatch batch = _firestore.batch();
//       final groupRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaran)
//         .collection('halaqah_grup').doc(groupId); // Jika groupId null, ID baru akan dibuat

//       // 3. Simpan/Perbarui Dokumen Grup Utama
//       batch.set(groupRef, {
//         'namaGrup': namaGrupC.text.trim(),
//         'idPengampu': selectedPengampu.value!.uid,
//         'namaPengampu': selectedPengampu.value!.nama,
//         'aliasPengampu': selectedPengampu.value!.alias,
//         'profileImageUrl': selectedPengampu.value!.profileImageUrl,
//         'semester': semester,
//         'createdAt': FieldValue.serverTimestamp(), // Berguna untuk melacak kapan terakhir diubah
//       }, SetOptions(merge: true));

//       // 4. Proses Perubahan Anggota Siswa
//       final initialMemberIds = _initialMembers.map((s) => s.uid).toSet();
//       final finalMemberIds = anggotaGrup.map((s) => s.uid).toSet();
      
//       final addedSiswa = anggotaGrup.where((s) => !initialMemberIds.contains(s.uid)).toList();
//       final removedSiswa = _initialMembers.where((s) => !finalMemberIds.contains(s.uid)).toList();

//       for (var siswa in addedSiswa) {
//         // Tambahkan siswa ke sub-koleksi 'anggota' di grup
//         batch.set(groupRef.collection('anggota').doc(siswa.uid), {
//           'namaSiswa': siswa.nama, 
//           'kelasAsal': siswa.kelasId
//         });
//         // Perbarui field di dokumen utama siswa
//         batch.update(_firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid), {
//           fieldGrupSiswa: groupRef.id
//         });
//       }
      
//       for (var siswa in removedSiswa) {
//         // Hapus siswa dari sub-koleksi 'anggota' di grup
//         batch.delete(groupRef.collection('anggota').doc(siswa.uid));
//         // Hapus field dari dokumen utama siswa
//         batch.update(_firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid), {
//           fieldGrupSiswa: FieldValue.delete()
//         });
//       }
      
//       // 5. Proses Denormalisasi untuk Pengampu
//       final newPengampuId = selectedPengampu.value!.uid;
//       final keySemester = "$tahunAjaran\_$semester";

//       // Jika pengampu diganti (hanya dalam mode edit)
//       if (isEditMode.value && _initialPengampuId != null && _initialPengampuId != newPengampuId) {
//         // Hapus ID grup dari daftar milik pengampu LAMA
//         final oldPengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(_initialPengampuId!);
//         batch.update(oldPengampuRef, {
//           'grupHalaqahDiampu.$keySemester': FieldValue.arrayRemove([groupRef.id])
//         });
//       }
      
//       // Selalu tambahkan ID grup ke daftar milik pengampu BARU (berlaku untuk mode create & edit ganti pengampu)
//       final newPengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(newPengampuId);
//       batch.update(newPengampuRef, {
//         'grupHalaqahDiampu.$keySemester': FieldValue.arrayUnion([groupRef.id])
//       });
      
//       // 6. Jalankan Semua Operasi
//       await batch.commit();
      
//       Get.back(); // Kembali ke halaman manajemen
//       Get.snackbar("Berhasil", "Grup halaqah berhasil disimpan.");

//     } catch (e) {
//       Get.snackbar("Error", "Gagal menyimpan grup: ${e.toString()}");
//     } finally {
//       isSaving.value = false;
//     }
//   }
  
//   @override
//   void onClose() {
//     namaGrupC.dispose();
//     super.onClose();
//   }
// }