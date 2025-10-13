import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/data_sarpras_controller.dart';
// Import model jika ingin mengakses properti format tanggal langsung dari view
// import '../../../data/models/sarpras_model.dart';

class DataSarprasView extends GetView<DataSarprasController> {
  const DataSarprasView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Data Sarana Prasarana'),
      //   centerTitle: true,
      //   actions: [
      //     // Tombol refresh (opsional)
      //     Obx(() {
      //       if (controller.isAllowedToView.value) {
      //         return IconButton(
      //           icon: const Icon(Icons.refresh),
      //           onPressed: controller.isLoading.value ? null : () => controller.refreshData(),
      //         );
      //       }
      //       return const SizedBox.shrink(); // Kosong jika tidak diizinkan
      //     }),
      //   ],
      // ),
      // body: Obx(() {
      //   if (controller.isLoading.value) {
      //     return const Center(child: CircularProgressIndicator());
      //   }

      //   if (!controller.isAllowedToView.value) {
      //     return Center(
      //       child: Padding(
      //         padding: const EdgeInsets.all(16.0),
      //         child: Text(
      //           controller.errorMessage.value.isNotEmpty
      //               ? controller.errorMessage.value
      //               : "Anda tidak memiliki hak akses untuk melihat data ini.",
      //           style: const TextStyle(fontSize: 16, color: Colors.red),
      //           textAlign: TextAlign.center,
      //         ),
      //       ),
      //     );
      //   }

      //   if (controller.errorMessage.value.isNotEmpty && controller.sarprasList.isEmpty) {
      //     return Center(
      //       child: Padding(
      //         padding: const EdgeInsets.all(16.0),
      //         child: Text(
      //           controller.errorMessage.value,
      //           style: const TextStyle(fontSize: 16, color: Colors.red),
      //           textAlign: TextAlign.center,
      //         ),
      //       ),
      //     );
      //   }

      //   if (controller.sarprasList.isEmpty) {
      //     return const Center(
      //       child: Text(
      //         'Belum ada data sarpras yang ditambahkan.',
      //         style: TextStyle(fontSize: 16),
      //       ),
      //     );
      //   }

      //   // Jika menggunakan stream di controller:
      //   // return StreamBuilder<List<SarprasModel>>(
      //   //   stream: controller.streamSarprasData(), // Panggil stream dari controller
      //   //   builder: (context, snapshot) {
      //   //     if (snapshot.connectionState == ConnectionState.waiting) {
      //   //       return const Center(child: CircularProgressIndicator());
      //   //     }
      //   //     if (snapshot.hasError) {
      //   //       return Center(child: Text("Error: ${snapshot.error}"));
      //   //     }
      //   //     if (!snapshot.hasData || snapshot.data!.isEmpty) {
      //   //       return const Center(child: Text("Belum ada data sarpras."));
      //   //     }
      //   //     final sarprasList = snapshot.data!;
      //   //     return ListView.builder(
      //   //       itemCount: sarprasList.length,
      //   //       itemBuilder: (context, index) {
      //   //         final sarpras = sarprasList[index];
      //   //         return _buildSarprasCard(sarpras);
      //   //       },
      //   //     );
      //   //   },
      //   // );


      //   // Jika menggunakan RxList yang diupdate via listen() di controller:
      //   return RefreshIndicator(
      //     onRefresh: controller.refreshData,
      //     child: ListView.builder(
      //       padding: const EdgeInsets.all(8.0),
      //       itemCount: controller.sarprasList.length,
      //       itemBuilder: (context, index) {
      //         final sarpras = controller.sarprasList[index];
      //         return Card(
      //           elevation: 3,
      //           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      //           child: ListTile(
      //             title: Text(
      //               sarpras.namaBarang,
      //               style: const TextStyle(fontWeight: FontWeight.bold),
      //             ),
      //             subtitle: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 Text('Jumlah: ${sarpras.jumlah}'),
      //                 Text('Kondisi: ${sarpras.kondisi}'),
      //                 Text('Lokasi: ${sarpras.lokasi}'),
      //                 if (sarpras.tanggalPengadaan != null)
      //                   Text('Tgl Pengadaan: ${sarpras.tanggalPengadaanFormatted}'),
      //                 if (sarpras.keterangan != null && sarpras.keterangan!.isNotEmpty)
      //                   Padding(
      //                     padding: const EdgeInsets.only(top: 4.0),
      //                     child: Text('Ket: ${sarpras.keterangan}', style: TextStyle(fontStyle: FontStyle.italic)),
      //                   ),
      //               ],
      //             ),
      //             trailing: IconButton(
      //               icon: const Icon(Icons.edit_note, color: Colors.blue),
      //               onPressed: () {
      //                 // TODO: Implementasi navigasi ke halaman edit sarpras
      //                 // Get.toNamed('/edit-sarpras', arguments: sarpras);
      //                 Get.snackbar("Info", "Fitur edit untuk ${sarpras.namaBarang} belum diimplementasikan.");
      //               },
      //             ),
      //             isThreeLine: true, // Sesuaikan jika perlu
      //           ),
      //         );
      //       },
      //     ),
      //   );
      // }),
      // floatingActionButton: Obx(() {
      //    // Hanya tampilkan FAB jika user diizinkan melihat dan mungkin punya hak input
      //   if (controller.isAllowedToView.value && controller.allowedJabatan.contains(controller.currentUserJabatan)) {
      //     return FloatingActionButton(
      //       onPressed: () {
      //         controller.goToBuatSarpras();
      //       },
      //       child: const Icon(Icons.add),
      //       tooltip: 'Tambah Data Sarpras',
      //     );
      //   }
      //   return const SizedBox.shrink();
      // }),
    );
  }
}