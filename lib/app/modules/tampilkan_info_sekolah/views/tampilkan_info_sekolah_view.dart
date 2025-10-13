// views/tampilkan_info_sekolah_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../controllers/tampilkan_info_sekolah_controller.dart';

class TampilkanInfoSekolahView extends GetView<TampilkanInfoSekolahController> {
  const TampilkanInfoSekolahView({super.key});

  @override
  Widget build(BuildContext context) {
    // timeago.setLocaleMessages('id', timeago.IdMessages());

    return Scaffold(
  //     appBar: AppBar(title: const Text('Info Sekolah')),
  //     body: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //       child: Column(
  //         children: [
  //           // --- BAR PENCARIAN ---
  //           Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 16.0),
  //             child: TextField(
  //               controller: controller.searchC,
  //               decoration: InputDecoration(
  //                 hintText: 'Cari berdasarkan judul atau penulis...',
  //                 prefixIcon: const Icon(Icons.search),
  //                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  //                 contentPadding: EdgeInsets.zero,
  //               ),
  //             ),
  //           ),
            
  //           // --- DAFTAR INFORMASI ---
  //           Expanded(
  //             child: Obx(() {
  //               if (controller.isLoading.value) {
  //                 return const Center(child: CircularProgressIndicator());
  //               }
  //               if (controller.filteredInfoList.isEmpty) {
  //                 return const Center(child: Text('Informasi tidak ditemukan.'));
  //               }
  //               return RefreshIndicator(
  //                 onRefresh: () => controller.fetchInfoSekolah(isRefresh: true),
  //                 child: ListView.builder(
  //                   itemCount: controller.filteredInfoList.length,
  //                   itemBuilder: (context, index) {
  //                     final doc = controller.filteredInfoList[index];
  //                     return _buildInfoSummaryCard(context, doc);
  //                   },
  //                 ),
  //               );
  //             }),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // // WIDGET KARTU RINGKASAN BARU
  // Widget _buildInfoSummaryCard(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) {
  //   final data = doc.data()!;
  //   final String judul = data['judulinformasi'] ?? 'Tanpa Judul';
  //   final String penulis = data['namapenginput'] ?? 'Admin';
  //   final String? imageUrl = data['imageUrl'];
  //   final DateTime tanggal = DateTime.parse(data['tanggalinput']);

  //   return Card(
  //     margin: const EdgeInsets.only(bottom: 16.0),
  //     elevation: 3,
  //     clipBehavior: Clip.antiAlias,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //     child: InkWell(
  //       onTap: () => controller.goToDetail(doc),
  //       child: Row(
  //         children: [
  //           // Gambar atau Placeholder
  //           SizedBox(
  //             width: 110,
  //             height: 110,
  //             child: imageUrl != null && imageUrl.isNotEmpty
  //                 ? Image.network(imageUrl, fit: BoxFit.cover)
  //                 : Container(
  //                     color: Theme.of(context).primaryColor.withOpacity(0.1),
  //                     child: const Icon(Icons.newspaper, size: 40, color: Colors.grey),
  //                   ),
  //           ),
  //           // Detail Teks
  //           Expanded(
  //             child: Padding(
  //               padding: const EdgeInsets.all(12.0),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Text(
  //                     judul,
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text(
  //                     'Oleh: $penulis',
  //                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     timeago.format(tanggal, locale: 'id'),
  //                     style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
    );
  }
}