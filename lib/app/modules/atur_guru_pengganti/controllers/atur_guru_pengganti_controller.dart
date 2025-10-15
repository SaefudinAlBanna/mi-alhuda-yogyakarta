
// lib/app/modules/atur_guru_pengganti/controllers/atur_guru_pengganti_controller.dart (VERSI FINAL)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/pegawai_simple_model.dart';
import 'package:mi_alhuda_yogyakarta/app/models/jadwal_tugas_item_model.dart';

class AturGuruPenggantiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<JadwalTugasItem> jadwalHariIni = <JadwalTugasItem>[].obs;
  final RxList<PegawaiSimpleModel> daftarGuru = <PegawaiSimpleModel>[].obs;
  
  final Rxn<JadwalTugasItem> sesiTerpilih = Rxn<JadwalTugasItem>();
  final Rxn<PegawaiSimpleModel> guruPenggantiTerpilih = Rxn<PegawaiSimpleModel>();

  @override
  void onInit() {
    super.onInit();
    fetchJadwalForSelectedDate();
    _fetchDaftarGuru();
  }

  Future<void> _fetchDaftarGuru() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
    daftarGuru.assignAll(snapshot.docs.map((d) => PegawaiSimpleModel.fromFirestore(d)).toList());
  }

  // --- [DIUBAH] Fungsi ini sekarang lebih aman dari data null ---
  Future<void> fetchJadwalForSelectedDate() async {
    isLoading.value = true;
    jadwalHariIni.clear();
    try {
      final tanggalStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final namaHariKapital = DateFormat('EEEE', 'id_ID').format(selectedDate.value);
      final tahunAjaran = configC.tahunAjaranAktif.value;

      // 1. Ambil data pengganti yang sudah ada untuk hari ini (Query Tambahan)
      final sesiPenggantiSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('sesi_pengganti_kbm')
          .where('tanggal', isEqualTo: tanggalStr)
          .get();
      
      // Buat "peta contekan" agar mudah dicari
      final Map<String, Map<String, dynamic>> petaPengganti = {
        for (var doc in sesiPenggantiSnap.docs)
          "${doc.data()['idKelas']}_${doc.data()['jamKe']}": {
            'nama': doc.data()['namaGuruPengganti'],
            'idDokumen': doc.id,
          }
      };

      // 2. Ambil semua jadwal pelajaran seperti biasa
      final jadwalKelasSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('jadwalkelas').get();
      
      final List<JadwalTugasItem> jadwalDitemukan = [];
      for (var doc in jadwalKelasSnap.docs) {
        final data = doc.data();
        final jadwalHari = (data[namaHariKapital] ?? data[namaHariKapital.toLowerCase()]) as List? ?? [];
        
        for (var slot in jadwalHari) {
          if (slot is Map<String, dynamic> && slot['idGuru'] != null && slot['jam'] != null) {
            
            // 3. Cek "peta contekan" saat membuat model
            final String sesiKey = "${doc.id}_${slot['jam']}";
            final dataPengganti = petaPengganti[sesiKey];

            jadwalDitemukan.add(JadwalTugasItem(
              idKelas: doc.id,
              jamKe: slot['jam'],
              namaMapel: slot['namaMapel'] ?? 'N/A',
              idMapel: slot['idMapel'] ?? '',
              idGuru: slot['idGuru'] ?? '',
              namaGuru: slot['namaGuru'] ?? 'N/A',
              tingkatanKelas: '', status: StatusJurnal.BelumDiisi,
              // --- [INTEGRASI DATA PENGGANTI] ---
              namaGuruPengganti: dataPengganti?['nama'],
              idSesiPengganti: dataPengganti?['idDokumen'],
            ));
          }
        }
      }
      
      jadwalDitemukan.sort((a, b) => a.jamKe.compareTo(b.jamKe));
      jadwalHariIni.assignAll(jadwalDitemukan);

    } catch (e) { Get.snackbar("Error", "Gagal memuat jadwal: ${e.toString()}"); } 
    finally { isLoading.value = false; }
  }

  Future<void> batalkanPengganti(JadwalTugasItem sesi) async {
    Get.dialog(
      AlertDialog(
        title: const Text("Konfirmasi Pembatalan"),
        content: const Text("Anda yakin ingin membatalkan penugasan guru pengganti ini?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Tidak")),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              isSaving.value = true;
              try {
                final tahunAjaran = configC.tahunAjaranAktif.value;
                await _firestore
                    .collection('Sekolah').doc(configC.idSekolah)
                    .collection('tahunajaran').doc(tahunAjaran)
                    .collection('sesi_pengganti_kbm').doc(sesi.idSesiPengganti!)
                    .delete();
                
                // --- [LOGIKA REAKTIF BARU - BATAL] ---
                final index = jadwalHariIni.indexOf(sesi);
                if (index != -1) {
                  final updatedSesi = jadwalHariIni[index].copyWith(clearPengganti: true);
                  jadwalHariIni[index] = updatedSesi;
                }
                // HAPUS fetchJadwalForSelectedDate(); KARENA TIDAK PERLU LAGI!
                // ------------------------------------

                Get.snackbar("Berhasil", "Guru pengganti telah dibatalkan.", backgroundColor: Colors.green, colorText: Colors.white);
              } catch (e) {
                Get.snackbar("Error", "Gagal membatalkan: $e");
              } finally {
                isSaving.value = false;
              }
            },
            child: const Text("Ya, Batalkan"),
          ),
        ],
      ),
    );
  }
  
  void pickDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: selectedDate.value, firstDate: DateTime(2022), lastDate: DateTime(2030));
    if (picked != null) {
      selectedDate.value = picked;
      fetchJadwalForSelectedDate();
    }
  }

  // --- [DIUBAH] Dialog disederhanakan, tanpa validasi bentrok ---
  void openGantiGuruDialog(JadwalTugasItem sesi) {
    sesiTerpilih.value = sesi;
    guruPenggantiTerpilih.value = null;
    
    Get.defaultDialog(
      title: "Pilih Guru Pengganti",
      content: Obx(() => DropdownButtonFormField<PegawaiSimpleModel>(
        value: guruPenggantiTerpilih.value,
        isExpanded: true,
        hint: const Text("Pilih Guru"),
        items: daftarGuru.where((g) => g.uid != sesi.idGuru).map((p) => DropdownMenuItem(
          value: p,
          // --- [FIX] Tampilkan alias jika ada, jika tidak, baru nama ---
          child: Text(
            p.alias.isNotEmpty ? p.alias : p.nama,
            overflow: TextOverflow.ellipsis
          ),
        )).toList(),
        onChanged: (value) {
          guruPenggantiTerpilih.value = value;
        },
      )),
      confirm: Obx(() => ElevatedButton(
        onPressed: guruPenggantiTerpilih.value != null ? simpanPengganti : null,
        child: const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  // --- [DIHAPUS] Fungsi checkJadwalBentrok sudah tidak diperlukan lagi ---

  Future<void> simpanPengganti() async {
   isSaving.value = true;
   Get.back(); // Tutup dialog
   try {
     final sesi = sesiTerpilih.value!;
     final pengganti = guruPenggantiTerpilih.value!;
     final namaPenggantiToShow = pengganti.displayName; // Gunakan displayName dari model

     final docRef = await _firestore.collection('Sekolah').doc(configC.idSekolah)
       .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
       .collection('sesi_pengganti_kbm').add({
         'tanggal': DateFormat('yyyy-MM-dd').format(selectedDate.value),
         'idKelas': sesi.idKelas,
         'jamKe': sesi.jamKe,
         'idMapel': sesi.idMapel,
         // --- [PERBAIKAN DENORMALISASI] Simpan nama mapel ---
         'namaMapel': sesi.namaMapel, 
         'idGuruAsli': sesi.idGuru,
         'namaGuruAsli': sesi.namaGuru,
         'idGuruPengganti': pengganti.uid,
         'namaGuruPengganti': namaPenggantiToShow,
         'createdAt': FieldValue.serverTimestamp(),
       });

      // --- [LOGIKA REAKTIF BARU - TAMBAH] ---
      // 1. Cari index dari item yang baru saja diubah.
      final index = jadwalHariIni.indexWhere((item) => item.idKelas == sesi.idKelas && item.jamKe == sesi.jamKe);
      
      if (index != -1) {
        // 2. Buat item baru dengan data pengganti menggunakan copyWith.
        final updatedSesi = jadwalHariIni[index].copyWith(
          namaGuruPengganti: namaPenggantiToShow,
          idSesiPengganti: docRef.id,
        );
        // 3. Ganti item lama dengan yang baru di dalam RxList.
        jadwalHariIni[index] = updatedSesi;
      }
      // ------------------------------------

      Get.snackbar("Berhasil", "Guru pengganti telah disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch(e) { Get.snackbar("Error", "Gagal menyimpan: $e"); }
    finally { isSaving.value = false; }
  }
}