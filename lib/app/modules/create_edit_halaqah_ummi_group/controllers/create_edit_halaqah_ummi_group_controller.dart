// lib/app/modules/create_edit_halaqah_ummi_group/controllers/create_edit_halaqah_ummi_group_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../models/pegawai_simple_model.dart';
import '../../../models/siswa_simple_model.dart';

class CreateEditHalaqahUmmiGroupController extends GetxController {
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


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../controllers/config_controller.dart';
// import '../../../models/halaqah_group_ummi_model.dart';
// import '../../../models/pegawai_simple_model.dart';
// import '../../../models/siswa_simple_model.dart';

// class CreateEditHalaqahUmmiGroupController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();

//   // State Halaman
//   final isEditMode = false.obs;
//   final isLoading = true.obs;
//   final isSaving = false.obs;
//   String? groupId;

//   // Form State
//   final namaGrupC = TextEditingController();
//   final lokasiC = TextEditingController();
//   final RxString selectedFase = "A".obs;
//   final Rxn<PegawaiSimpleModel> selectedPengampu = Rxn<PegawaiSimpleModel>();
  
//   // Daftar Pengampu
//   final List<PegawaiSimpleModel> _allPengampu = [];
//   final RxList<PegawaiSimpleModel> availablePengampu = <PegawaiSimpleModel>[].obs;

//   // State Manajemen Siswa
//   final RxList<String> daftarKelas = <String>[].obs;
//   final RxString selectedKelasFilter = "".obs;
//   final RxList<SiswaSimpleModel> anggotaGrup = <SiswaSimpleModel>[].obs;
//   final RxList<SiswaSimpleModel> siswaTersedia = <SiswaSimpleModel>[].obs;

//   // Helpers untuk Lacak Perubahan
//   String? _initialPengampuId;
//   late String tahunAjaran;
//   // Deklarasikan _initialMembers di scope kelas agar bisa diakses di semua method
//   List<SiswaSimpleModel> _initialMembers = []; 

//   @override
//   void onInit() {
//     super.onInit();
//     final dynamic argument = Get.arguments;
//     if (argument is HalaqahGroupUmmiModel) {
//       isEditMode.value = true;
//       groupId = argument.id;
//     }
//     tahunAjaran = configC.tahunAjaranAktif.value;
//     _loadInitialData(argument as HalaqahGroupUmmiModel?);
//   }

//   Future<void> _loadInitialData(HalaqahGroupUmmiModel? group) async {
//     isLoading.value = true;
//     try {
//       await _fetchEligiblePengampu();
//       await _fetchAvailableClasses();
//       if (isEditMode.value && group != null) {
//         await _loadGroupDataForEdit(group);
//       } else {
//         filterAvailablePengampu();
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat data awal: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> _fetchEligiblePengampu() async {
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
//     final List<PegawaiSimpleModel> eligible = [];
//     for (var doc in snapshot.docs) {
//       final data = doc.data();
//       final role = data['role'] as String? ?? '';
//       final tugas = List<String>.from(data['tugas'] ?? []);
//       if (role == 'Pengampu' || tugas.contains('Pengampu')) {
//         eligible.add(PegawaiSimpleModel.fromFirestore(doc));
//       }
//     }
//     eligible.sort((a, b) => a.nama.compareTo(b.nama));
//     _allPengampu.assignAll(eligible);
//   }

//   // LOGIKA KUNCI: Filter pengampu berdasarkan fase yang dipilih
//   Future<void> filterAvailablePengampu() async {
//     // 1. Dapatkan semua grup ummi yang sudah ada di semester ini
//     final groupsSnapshot = await _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaran)
//         .collection('halaqah_grup_ummi').get();

//     // 2. Buat daftar pengampu yang sudah terpakai di fase TERPILIH
//     final assignedPengampuIdsInFase = groupsSnapshot.docs
//         .where((doc) => doc.data()['fase'] == selectedFase.value)
//         // Pengecualian: jika mode edit, jangan anggap pengampu grup ini sebagai 'terpakai'
//         .where((doc) => isEditMode.value ? doc.id != groupId : true)
//         .map((doc) => doc.data()['idPengampu'] as String)
//         .toSet();

//     // 3. Filter daftar semua pengampu
//     final filteredList = _allPengampu
//         .where((p) => !assignedPengampuIdsInFase.contains(p.uid))
//         .toList();

//     availablePengampu.assignAll(filteredList);

//     // Jika pengampu yang dipilih sebelumnya tidak ada di daftar baru, reset
//     if (selectedPengampu.value != null && !availablePengampu.any((p) => p.uid == selectedPengampu.value!.uid)) {
//       selectedPengampu.value = null;
//     }
//   }

//   Future<void> _fetchAvailableClasses() async {
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').get();
//     daftarKelas.assignAll(snapshot.docs.map((doc) => doc.id).toList()..sort());
//   }

//   Future<void> _loadGroupDataForEdit(HalaqahGroupUmmiModel group) async {
//     namaGrupC.text = group.namaGrup;
//     lokasiC.text = group.lokasiDefault;
//     selectedFase.value = group.fase;
//     _initialPengampuId = group.idPengampu;

//     // Filter pengampu berdasarkan fase dari grup yang diedit
//     await filterAvailablePengampu(); 
    
//     selectedPengampu.value = _allPengampu.firstWhereOrNull((p) => p.uid == group.idPengampu);

//     final memberSnapshot = await _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaran)
//         .collection('halaqah_grup_ummi').doc(group.id).collection('anggota').get();
      
//     anggotaGrup.assignAll(memberSnapshot.docs.map((doc) {
//       final data = doc.data();
//       return SiswaSimpleModel(uid: doc.id, nama: data['namaSiswa'], kelasId: data['kelasAsal']);
//     }).toList());

//     _initialMembers = List.from(anggotaGrup);
    
//   }

//   void onFaseChanged(String newFase) {
//     selectedFase.value = newFase;
//     filterAvailablePengampu();
//   }
  
//   Future<void> fetchAvailableStudentsByClass(String kelasId) async {
//     selectedKelasFilter.value = kelasId;
//     siswaTersedia.clear();

//     // Ambil semua siswa di kelas yang BELUM punya grup ummi di tahun ajaran ini
//     final snapshot = await _firestore
//         .collection('Sekolah').doc(configC.idSekolah).collection('siswa')
//         .where('kelasId', isGreaterThanOrEqualTo: kelasId)
//         .where('kelasId', isLessThan: '$kelasId\uf8ff')
//         .where('halaqahUmmi.tahunAjaran', isNotEqualTo: tahunAjaran)
//         .get();

//     // Perlu query kedua untuk siswa yang field `halaqahUmmi` nya tidak ada sama sekali
//      final snapshotNull = await _firestore
//         .collection('Sekolah').doc(configC.idSekolah).collection('siswa')
//         .where('kelasId', isGreaterThanOrEqualTo: kelasId)
//         .where('kelasId', isLessThan: '$kelasId\uf8ff')
//         .where('halaqahUmmi', isEqualTo: null)
//         .get();

//     final combinedDocs = [...snapshot.docs, ...snapshotNull.docs];
//     final uniqueIds = <String>{};
//     final uniqueDocs = combinedDocs.where((doc) => uniqueIds.add(doc.id)).toList();

//     siswaTersedia.assignAll(uniqueDocs.map((doc) => SiswaSimpleModel.fromFirestore(doc)).toList());
//   }

//   void addSiswaToGroup(SiswaSimpleModel siswa) {
//     siswaTersedia.removeWhere((s) => s.uid == siswa.uid);
//     anggotaGrup.add(siswa);
//   }

//   void removeSiswaFromGroup(SiswaSimpleModel siswa) {
//     anggotaGrup.removeWhere((s) => s.uid == siswa.uid);
//     if (siswa.kelasId == selectedKelasFilter.value) {
//       siswaTersedia.add(siswa);
//     }
//   }

//   Future<void> saveGroup() async {
//     if (selectedPengampu.value == null || namaGrupC.text.trim().isEmpty || lokasiC.text.trim().isEmpty) {
//       Get.snackbar("Peringatan", "Nama grup, lokasi, dan pengampu wajib diisi.");
//       return;
//     }
    
//     isSaving.value = true;
//     try {
//       final WriteBatch batch = _firestore.batch();
//       final groupRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(tahunAjaran)
//           .collection('halaqah_grup_ummi').doc(groupId);
  
//       // 1. Simpan/Update data grup utama
//       batch.set(groupRef, {
//         'namaGrup': namaGrupC.text.trim(),
//         'fase': selectedFase.value,
//         'lokasiDefault': lokasiC.text.trim(),
//         'idPengampu': selectedPengampu.value!.uid,
//         'namaPengampu': selectedPengampu.value!.displayName,
//         'semester': configC.semesterAktif.value,
//       }, SetOptions(merge: true));
      
//       // --- [LOGIKA BARU] Lacak perubahan anggota dengan lebih akurat ---
//       final initialMemberIds = _initialMembers.map((s) => s.uid).toSet();
//       final finalMemberIds = anggotaGrup.map((s) => s.uid).toSet();
      
//       final siswaYangDitambahkan = anggotaGrup.where((s) => !initialMemberIds.contains(s.uid)).toList();
//       final siswaYangDihapus = _initialMembers.where((s) => !finalMemberIds.contains(s.uid)).toList();
      
//       // 2. Proses Siswa yang Ditambahkan
//       for (var siswa in siswaYangDitambahkan) {
//         final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
//         batch.set(groupRef.collection('anggota').doc(siswa.uid), {'namaSiswa': siswa.nama, 'kelasAsal': siswa.kelasId});
        
//         // Set data halaqah baru (dengan progres default)
//         batch.update(siswaRef, {
//           'halaqahUmmi.idGrup': groupRef.id,
//           'halaqahUmmi.tahunAjaran': tahunAjaran,
//           'halaqahUmmi.faseGrup': selectedFase.value,
//           'halaqahUmmi.namaPengampu': selectedPengampu.value!.displayName,
//           'halaqahUmmi.progres': { 'tingkat': 'Jilid', 'detailTingkat': '1', 'halaman': 1 },
//           'halaqahUmmi.tanggalSetoranTerakhir': null,
//           'halaqahUmmi.statusUjian': FieldValue.delete(),
//         });
//       }
  
//       // 3. Proses Siswa yang Dihapus (PR SELESAI)
//       for (var siswa in siswaYangDihapus) {
//         final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
//         // Hapus dari sub-koleksi anggota
//         batch.delete(groupRef.collection('anggota').doc(siswa.uid));
//         // Hapus seluruh Map 'halaqahUmmi' dari dokumen siswa
//         batch.update(siswaRef, {'halaqahUmmi': FieldValue.delete()});
//       }
//       // --- [AKHIR LOGIKA BARU] ---
      
//       // 4. Logika Denormalisasi Pengampu (jika ada perubahan)
//       final newPengampuId = selectedPengampu.value!.uid;
//       if (isEditMode.value && _initialPengampuId != null && _initialPengampuId != newPengampuId) {
//         // (Opsional) Jika Anda menyimpan daftar grup di dokumen pengampu,
//         // logika untuk menghapus dari pengampu lama akan ada di sini.
//       }
      
//       await batch.commit();
      
//       Get.back();
//       Get.snackbar("Berhasil", "Grup halaqah Ummi berhasil disimpan.");
  
//     } catch (e) {
//       Get.snackbar("Error", "Gagal menyimpan grup: ${e.toString()}");
//     } finally {
//       isSaving.value = false;
//     }
//   }
// }