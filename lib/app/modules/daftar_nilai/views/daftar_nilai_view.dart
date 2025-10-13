import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daftar_nilai_controller.dart';

class DaftarNilaiView extends GetView<DaftarNilaiController> {
  const DaftarNilaiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  //     body: Obx(() {
  //       if (controller.isLoading.value) {
  //         return const Center(child: CircularProgressIndicator());
  //       }
  //       if (controller.daftarNilai.isEmpty) {
  //         return _buildEmptyState();
  //       }
  //       return _buildNilaiList();
  //     }),
  //   );
  // }

  // // --- WIDGET UTAMA DENGAN APPBAR YANG BISA MENGECIL ---
  // Widget _buildNilaiList() {
  //   return CustomScrollView(
  //     slivers: [
  //       _buildSliverAppBar(),
  //       SliverPadding(
  //         padding: const EdgeInsets.all(16),
  //         sliver: SliverList(
  //           delegate: SliverChildBuilderDelegate(
  //             (context, index) {
  //               final nilai = controller.daftarNilai[index];
  //               return _buildNilaiCard(nilai);
  //             },
  //             childCount: controller.daftarNilai.length,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  
  // // --- APPBAR KHUSUS YANG FLEKSIBEL ---
  // SliverAppBar _buildSliverAppBar() {
  //   final Map<String, dynamic> siswa = controller.dataSiswa;
  //   final String? imageUrl = siswa['profileImageUrl'];
  //   final ImageProvider imageProvider = (imageUrl != null && imageUrl.isNotEmpty)
  //       ? NetworkImage(imageUrl)
  //       : NetworkImage("https://ui-avatars.com/api/?name=${siswa['namasiswa']}&background=random");

  //   return SliverAppBar(
  //     expandedHeight: 200.0,
  //     floating: false,
  //     pinned: true,
  //     backgroundColor: Colors.teal,
  //     flexibleSpace: FlexibleSpaceBar(
  //       centerTitle: true,
  //       title: Text(
  //         siswa['namasiswa'] ?? 'Detail Nilai',
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontSize: 16.0,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       background: Stack(
  //         fit: StackFit.expand,
  //         children: [
  //           Image(image: imageProvider, fit: BoxFit.cover),
  //           const DecoratedBox(
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 begin: Alignment(0.0, 0.5),
  //                 end: Alignment.center,
  //                 colors: <Color>[
  //                   Color(0x60000000),
  //                   Color(0x00000000),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // // --- KARTU NILAI DENGAN EXPANSIONTILE ---
  // Widget _buildNilaiCard(NilaiHalaqoh nilai) {
  //   return Card(
  //     elevation: 2,
  //     margin: const EdgeInsets.only(bottom: 16),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: ExpansionTile(
  //       tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //       title: Text(
  //         'Ust. ${nilai.pengampu}',
  //         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //       ),
  //       subtitle: Text(
  //         controller.formatTanggal(nilai.tanggalInput),
  //         style: const TextStyle(color: Colors.grey, fontSize: 14),
  //       ),
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
  //           child: Column(
  //             children: [
  //               const Divider(),
  //               _buildNilaiRow('Sabaq (Terbaru)', nilai.sabaq, nilai.nilaiSabaq),
  //               _buildNilaiRow('Sabqi (Baru)', nilai.sabqi, nilai.nilaiSabqi),
  //               _buildNilaiRow('Manzil (Lama)', nilai.manzil, nilai.nilaiManzil),
  //               if (nilai.tugasTambahan.isNotEmpty && nilai.tugasTambahan != '-')
  //                 _buildNilaiRow('Tugas Tambahan', nilai.tugasTambahan, nilai.nilaiTugasTambahan),
  //               const SizedBox(height: 10),
  //               _buildCatatanSection('Catatan Pengampu', nilai.catatanPengampu),
  //               const SizedBox(height: 10),
  //               _buildCatatanSection('Catatan Orang Tua', nilai.catatanOrangTua),
  //             ],
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  // // --- HELPER UNTUK MENAMPILKAN BARIS NILAI ---
  // Widget _buildNilaiRow(String label, String capaian, String nilai) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8.0),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Expanded(
  //           flex: 3,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
  //               const SizedBox(height: 2),
  //               Text(capaian, style: const TextStyle(fontSize: 16)),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(width: 10),
  //         Expanded(
  //           flex: 1,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.end,
  //             children: [
  //               const Text("Nilai", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
  //               const SizedBox(height: 2),
  //               Text(
  //                 nilai,
  //                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  
  // // --- HELPER UNTUK MENAMPILKAN BAGIAN CATATAN ---
  // Widget _buildCatatanSection(String title, String catatan) {
  //   if (catatan.isEmpty || catatan == '-') return const SizedBox.shrink();
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.stretch,
  //     children: [
  //       Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //       const SizedBox(height: 4),
  //       Container(
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: Colors.grey[100],
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: Colors.grey.shade300)
  //         ),
  //         child: Text(catatan, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
  //       )
  //     ],
  //   );
  // }
  
  // // --- WIDGET JIKA DATA KOSONG ---
  // Widget _buildEmptyState() {
  //   final Map<String, dynamic> siswa = controller.dataSiswa;
  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         const Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
  //         const SizedBox(height: 16),
  //         const Text(
  //           'Belum Ada Data Nilai',
  //           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  //         ),
  //         Text(
  //           'Nilai untuk ${siswa['namasiswa'] ?? 'siswa ini'} belum diinput.',
  //           style: const TextStyle(fontSize: 16, color: Colors.grey),
  //           textAlign: TextAlign.center,
  //         ),
  //       ],
  //     ),
    );
  }
}