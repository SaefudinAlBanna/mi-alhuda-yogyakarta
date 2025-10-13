// lib/app/modules/buat_tagihan_tahunan/views/buat_tagihan_tahunan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/buat_tagihan_tahunan_controller.dart';

class BuatTagihanTahunanView extends GetView<BuatTagihanTahunanController> {
  const BuatTagihanTahunanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tagihan Tahunan'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCardSPP(),
            const SizedBox(height: 16),
            _buildCardBiayaLain("Daftar Ulang", "DU", controller.isProcessingDU, controller.masterBiaya['daftarUlang'] ?? 0),
            const SizedBox(height: 16),
            _buildCardBiayaLain("Uang Kegiatan", "UK", controller.isProcessingUK, controller.masterBiaya['uangKegiatan'] ?? 0),
            const SizedBox(height: 16),
            _buildCardUangPangkal(), // <-- Widget yang kita modifikasi
            const SizedBox(height: 16),
            _buildCardUangBuku(),
          ],
        );
      }),
    );
  }

  Widget _buildCardSPP() {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Tagihan SPP", style: Get.textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text("Membuat 12 tagihan SPP bulanan untuk semua siswa aktif sesuai nominal di profil masing-masing."),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
              onPressed: controller.isProcessingSPP.value ? null : controller.konfirmasiBuatTagihanSPP,
              icon: controller.isProcessingSPP.value ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.receipt_long_rounded),
              label: const Text("Buat Tagihan SPP Satu Tahun"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBiayaLain(String jenisBiaya, String jenisSingkat, RxBool processingFlag, int nominal) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Tagihan $jenisBiaya", style: Get.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text("Membuat tagihan ini untuk semua siswa aktif dengan nominal Rp ${NumberFormat.decimalPattern('id_ID').format(nominal)}"),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
              onPressed: processingFlag.value ? null : () => controller.konfirmasiBuatTagihanUmum(jenisSingkat),
              icon: processingFlag.value ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.receipt_long_rounded),
              label: Text("Buat Tagihan $jenisBiaya"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            )),
          ],
        ),
      ),
    );
  }

  // [PEROMBAKAN TOTAL WIDGET INI]
  Widget _buildCardUangPangkal() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Tagihan Uang Pangkal", style: Get.textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text("Tambahkan siswa (misal: siswa baru, pindahan) yang akan dibuatkan tagihan Uang Pangkal."),
            const SizedBox(height: 16),
            
            // Tombol untuk menambah siswa
            OutlinedButton.icon(
              onPressed: controller.bukaPencarianSiswa,
              icon: const Icon(Icons.add),
              label: const Text("Tambah Siswa ke Daftar"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const Divider(height: 24),

            // Daftar siswa yang akan ditagih
            Obx(() {
              if (controller.siswaUntukDitagihUP.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Belum ada siswa yang ditambahkan.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.siswaUntukDitagihUP.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final siswa = controller.siswaUntukDitagihUP[index];
                  return Row(
                    children: [
                      // Tombol Hapus
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => controller.hapusSiswaDariDaftar(siswa.uid),
                      ),
                      // Nama & Kelas
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(siswa.namaLengkap, overflow: TextOverflow.ellipsis),
                            Text(siswa.kelasId?.split('-').first ?? 'Tanpa Kelas', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Input Nominal
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          controller: controller.uangPangkalControllers[siswa.uid],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: "Rp ",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
            const SizedBox(height: 16),
            
            // Tombol Proses Utama
            Obx(() => ElevatedButton.icon(
              onPressed: controller.isProcessingUP.value || controller.siswaUntukDitagihUP.isEmpty
                  ? null
                  : controller.konfirmasiBuatTagihanUangPangkal,
              icon: controller.isProcessingUP.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.foundation_rounded),
              label: const Text("Buat Tagihan Uang Pangkal"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCardUangBuku() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Tagihan Uang Buku", style: Get.textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text("Membuat tagihan berdasarkan data pendaftaran buku yang telah dipilih oleh siswa."),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
              onPressed: controller.isProcessingBuku.value ? null : controller.konfirmasiBuatTagihanBuku,
              icon: controller.isProcessingBuku.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.book_online_rounded),
              label: const Text("Buat Tagihan dari Pendaftaran Buku"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.teal,
              ),
            )),
          ],
        ),
      ),
    );
  }
}