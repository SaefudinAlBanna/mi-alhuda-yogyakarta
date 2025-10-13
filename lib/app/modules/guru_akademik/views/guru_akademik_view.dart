import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/guru_akademik_controller.dart';

class GuruAkademikView extends GetView<GuruAkademikController> {
  const GuruAkademikView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas & Mapel Saya'),
        centerTitle: true,
        // --- [PERBAIKAN] Pindahkan Aksi Wali Kelas ke Body untuk UI yang Lebih Bersih ---
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarIdKelas.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Anda belum memiliki penugasan mengajar untuk tahun ajaran ini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }
        // Tampilan utama setelah data dimuat
        return Column(
          children: [
            _buildKelasSelector(),
            _buildWaliKelasActions(),
            const Divider(height: 1),
            Expanded(child: _buildMapelList()),
          ],
        );
      }),
    );
  }

  // --- [BARU] Widget untuk menampilkan ChoiceChip Kelas ---
  Widget _buildKelasSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white,
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.daftarIdKelas.length,
        itemBuilder: (context, index) {
          final idKelas = controller.daftarIdKelas[index];
          final namaKelas = idKelas.split('-').first; // Ambil nama pendek
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Obx(() => ChoiceChip(
                  label: Text(namaKelas),
                  selected: controller.kelasTerpilihId.value == idKelas,
                  onSelected: (_) => controller.pilihKelas(idKelas),
                  selectedColor: Get.theme.primaryColor,
                  labelStyle: TextStyle(
                      color: controller.kelasTerpilihId.value == idKelas
                          ? Colors.white
                          : Colors.black),
                )),
          );
        },
      ),
    );
  }

  // --- [BARU] Widget untuk menampilkan tombol khusus Wali Kelas ---
  Widget _buildWaliKelasActions() {
    return Obx(() {
      // Tampilkan hanya jika guru ini adalah wali kelas DARI kelas yang sedang dipilih
      if (controller.isWaliKelas.value && controller.kelasDiampuId.value == controller.kelasTerpilihId.value) {
        return Container(
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text("Absensi Harian"),
                onPressed: controller.goToAbsensi,
              ),
              TextButton.icon(
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text("Rekap Absensi"),
                onPressed: controller.goToRekapAbsensiKelas,
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink(); // Sembunyikan jika bukan wali kelas dari kelas ini
    });
  }

  // --- [BARU] Widget untuk menampilkan daftar Mapel di kelas terpilih ---
  Widget _buildMapelList() {
    return Obx(() {
      if (controller.kelasTerpilihId.value == null) {
        return const Center(child: Text("Silakan pilih kelas di atas."));
      }
      if (controller.mapelDiKelasTerpilih.isEmpty) {
        // Ini seharusnya tidak terjadi jika logika controller benar, tapi sebagai pengaman
        return const Center(child: Text("Tidak ada mapel yang diampu di kelas ini."));
      }
      return RefreshIndicator(
        onRefresh: () => controller.fetchMapelDiampu(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.mapelDiKelasTerpilih.length,
          itemBuilder: (context, index) {
            final mapel = controller.mapelDiKelasTerpilih[index];
            
            // Tampilan ini sekarang terpadu, tidak perlu if/else isPengganti
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                // Tambahkan border jika guru pengganti
                side: BorderSide(
                  color: mapel.isPengganti ? Colors.amber.shade400 : Colors.transparent,
                  width: 1.5,
                )
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: mapel.isPengganti ? Colors.amber.withOpacity(0.15) : Colors.indigo.withOpacity(0.1),
                  child: Icon(
                    mapel.isPengganti ? Icons.people_alt_rounded : Icons.book_outlined,
                    color: mapel.isPengganti ? Colors.amber.shade800 : Colors.indigo.shade700,
                  ),
                ),
                title: Text(mapel.namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: mapel.isPengganti && mapel.namaGuruAsli != null
                    ? Text("Menggantikan: ${mapel.namaGuruAsli}", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
                    : null, // Jangan tampilkan subtitle jika bukan pengganti
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => controller.goToDaftarSiswaPermapel(mapel),
              ),
            );
          },
        ),
      );
    });
  }
}