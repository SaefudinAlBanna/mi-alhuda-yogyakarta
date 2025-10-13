// lib/app/modules/pembayaran_spp/views/pembayaran_spp_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/pembayaran_spp_controller.dart';

class PembayaranSppView extends GetView<PembayaranSppController> {
  const PembayaranSppView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  //     appBar: AppBar(
  //       title: Obx(() => Text(controller.selectedKelasNama.value.isEmpty
  //           ? 'Pembayaran Siswa'
  //           : 'Siswa Kelas ${controller.selectedKelasNama.value}')),
  //       centerTitle: true,
  //     ),
  //     body: Column(
  //       children: [
  //         _buildKelasDropdown(),
  //         _buildSiswaList(),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildKelasDropdown() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Obx(() {
  //       if (controller.isKelasLoading.value) {
  //         return const Center(child: CircularProgressIndicator());
  //       }
  //       // Gunakan sintaks fungsi untuk `items`
  //       return DropdownSearch<Map<String, dynamic>>(
  //         items:(f, cs) => controller.daftarKelas,
  //         itemAsString: (Map<String, dynamic> item) => item['nama'] ?? '',
  //         compareFn: (item, selectedItem) => item['id'] == selectedItem['id'],
  //         popupProps: const PopupProps.menu(showSearchBox: true),
  //         decoratorProps: DropDownDecoratorProps(
  //           decoration: InputDecoration(
  //             labelText: "Pilih Kelas",
  //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  //           ),
  //         ),
  //         onChanged: (value) {
  //           if (value != null) {
  //             controller.selectedKelasId.value = value['id'];
  //             controller.selectedKelasNama.value = value['nama'];
  //           } else {
  //             controller.selectedKelasId.value = null;
  //             controller.selectedKelasNama.value = '';
  //           }
  //         },
  //       );
  //     }),
  //   );
  // }

  // Widget _buildSiswaList() {
  //   return Expanded(
  //     child: Obx(() {
  //       if (controller.selectedKelasId.value == null) {
  //         return const Center(child: Text("Silakan pilih kelas terlebih dahulu."));
  //       }
  //       return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
  //         key: ValueKey(controller.selectedKelasId.value),
  //         future: controller.getDataSiswa(),
  //         builder: (context, snapsiswa) {
  //           if (snapsiswa.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
  //           if (snapsiswa.hasError) return Center(child: Text("Error: ${snapsiswa.error}"));
  //           if (snapsiswa.data == null || snapsiswa.data!.docs.isEmpty) return const Center(child: Text("Tidak ada siswa di kelas ini."));
            
  //           var datasiswaList = snapsiswa.data!.docs;
            
  //           return ListView.builder(
  //             padding: const EdgeInsets.symmetric(horizontal: 8),
  //             itemCount: datasiswaList.length,
  //             itemBuilder: (context, index) {
  //               var datasiswa = datasiswaList[index].data();
  //               String idsiswa = datasiswaList[index].id;
  //               String namaSiswa = datasiswa['namasiswa'] ?? 'Tanpa Nama';
                
  //               return Card(
  //                 margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
  //                 child: ListTile(
  //                   title: Text(namaSiswa, style: const TextStyle(fontSize: 16)),
  //                   onTap: () {
  //                     _showPaymentSheet(context, idsiswa, namaSiswa);
  //                   },
  //                 ),
  //               );
  //             },
  //           );
  //         },
  //       );
  //     }),
  //   );
  // }

  // // --- UI ALUR BARU YANG LEBIH SEDERHANA ---
  // void _showPaymentSheet(BuildContext context, String idsiswa, String namaSiswa) {
  //   controller.resetBottomSheetState();
  //   Get.bottomSheet(
  //     Container(
  //       height: Get.height * 0.9, // Beri lebih banyak ruang
  //       padding: const EdgeInsets.all(16),
  //       decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Header
  //           Text("Pembayaran: $namaSiswa", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 8),
            
  //           // Dropdown untuk memilih jenis pembayaran
  //           Obx(() => DropdownSearch<String>(
  //             items: (f, cs) => controller.daftarJenisPembayaran,
  //             popupProps: const PopupProps.menu(showSearchBox: true, fit: FlexFit.loose),
  //             decoratorProps: const DropDownDecoratorProps(
  //               decoration: InputDecoration(labelText: "Pilih Jenis Pembayaran", border: OutlineInputBorder()),
  //             ),
  //             onChanged: (value) => controller.onJenisPembayaranChanged(value, idsiswa),
  //             selectedItem: controller.jenisPembayaranTerpilih.value.isEmpty ? null : controller.jenisPembayaranTerpilih.value,
  //           )),
  //           const Divider(height: 24),

  //           // Konten dinamis: riwayat dan form input
  //           Expanded(
  //             child: Obx(() {
  //               if (controller.jenisPembayaranTerpilih.value.isEmpty) {
  //                 return const Center(child: Text("Silakan pilih jenis pembayaran untuk melanjutkan."));
  //               }
  //               if (controller.isRiwayatLoading.value) {
  //                 return const Center(child: CircularProgressIndicator());
  //               }
                
  //               // Gunakan SingleChildScrollView di sini untuk mencegah semua error overflow
  //               return SingleChildScrollView(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Text("Riwayat Pembayaran:", style: TextStyle(fontWeight: FontWeight.bold)),
  //                     _buildRiwayatList(),
  //                     const SizedBox(height: 24),
  //                     const Text("Input Pembayaran Baru:", style: TextStyle(fontWeight: FontWeight.bold)),
  //                     Obx(() {
  //                       if (controller.jenisPembayaranTerpilih.value == "SPP") {
  //                         return _buildSppInput(controller.riwayatPembayaran);
  //                       } else {
  //                         return _buildLainnyaInput();
  //                       }
  //                     }),
  //                     const SizedBox(height: 24),
  //                     ElevatedButton(
  //                       style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
  //                       onPressed: () => controller.simpanPembayaran(idsiswa),
  //                       child: const Text("Simpan Pembayaran"),
  //                     )
  //                   ],
  //                 ),
  //               );
  //             }),
  //           ),
  //         ],
  //       ),
  //     ),
  //     isScrollControlled: true,
  //   );
  // }

  // Widget _buildRiwayatList() {
  //   return Obx(() {
  //     if (controller.riwayatPembayaran.isEmpty) {
  //       return const Padding(
  //         padding: EdgeInsets.symmetric(vertical: 20),
  //         child: Center(child: Text("Belum ada riwayat pembayaran.")),
  //       );
  //     }
  //     return ListView.builder(
  //       shrinkWrap: true, // Penting untuk ListView di dalam SingleChildScrollView
  //       physics: const NeverScrollableScrollPhysics(), // Penting
  //       itemCount: controller.riwayatPembayaran.length,
  //       itemBuilder: (context, index) {
  //         var doc = controller.riwayatPembayaran[index];
  //         var item = doc.data();
  //         String detail = controller.jenisPembayaranTerpilih.value == "SPP"
  //             ? "Bulan: ${doc.id}"
  //             : "Ket: ${item['keterangan'] ?? 'N/A'}";
  //         Timestamp? tgl = item['tglbayar'];
  //         String tglBayar = tgl != null ? DateFormat('d MMM yyyy', 'id_ID').format(tgl.toDate()) : "N/A";
  //         String nominal = controller.formatRupiah((item['nominal'] as num?)?.toInt() ?? 0);
          
  //         return Card(
  //           margin: const EdgeInsets.only(bottom: 8),
  //           child: ListTile(
  //             dense: true,
  //             leading: const Icon(Icons.check_circle, color: Colors.green, size: 20),
  //             title: Text(detail, style: const TextStyle(fontWeight: FontWeight.bold)),
  //             subtitle: Text("Petugas: ${item['petugas'] ?? '-'} | Tgl: $tglBayar"),
  //             trailing: Text(nominal, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
  //           ),
  //         );
  //       },
  //     );
  //   });
  // }

  // Widget _buildSppInput(List<QueryDocumentSnapshot<Map<String, dynamic>>> riwayat) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text("Pilih Bulan:", style: TextStyle(fontWeight: FontWeight.w500)),
  //       const SizedBox(height: 8),
  //       DropdownSearch<String>.multiSelection(
  //         items: (f, cs) => controller.getListBulan().where((bulan) {
  //           final lunas = riwayat.map((doc) => doc.id).toSet();
  //           return !lunas.contains(bulan);
  //         }).toList(),
  //         popupProps: const PopupPropsMultiSelection.menu(showSearchBox: true, showSelectedItems: true, fit: FlexFit.loose),
  //         decoratorProps: const DropDownDecoratorProps(
  //           decoration: InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8))
  //         ),
  //         onChanged: (values) {
  //           controller.selectedBulanList.value = values;
  //           int total = values.length * controller.nominalTagihanSiswa.value;
  //           controller.sppTotalController.text = controller.formatRupiah(total);
  //         },
  //       ),
  //       const SizedBox(height: 16),
  //       const Text("Total Nominal:", style: TextStyle(fontWeight: FontWeight.w500)),
  //       const SizedBox(height: 8),
  //       TextField(controller: controller.sppTotalController, readOnly: true, decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, prefixText: "Rp ")),
  //     ],
  //   );
  // }

  // Widget _buildLainnyaInput() {
  //   final bool isOpsional = ['Infaq', 'Lain-Lain'].contains(controller.jenisPembayaranTerpilih.value);
    
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Obx(() {
  //         if (controller.sisaTagihanSiswa.value > 0) {
  //           return Padding(
  //             padding: const EdgeInsets.only(bottom: 12.0),
  //             child: Text("Sisa Tagihan: ${controller.formatRupiah(controller.sisaTagihanSiswa.value)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
  //           );
  //         }
  //         return const SizedBox.shrink();
  //       }),
  //       if (!isOpsional) ...[
  //         const Text("Keterangan:", style: TextStyle(fontWeight: FontWeight.w500)),
  //         const SizedBox(height: 8),
  //         TextField(controller: controller.keteranganController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Contoh: Buku Paket")),
  //         const SizedBox(height: 16),
  //       ],
  //       const Text("Nominal Pembayaran:", style: TextStyle(fontWeight: FontWeight.w500)),
  //       const SizedBox(height: 8),
  //       TextField(controller: controller.nominalController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Contoh: 150000", prefixText: "Rp ")),
  //     ],
    );
  }
}