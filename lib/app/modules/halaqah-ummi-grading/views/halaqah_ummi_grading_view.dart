import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart'; // Pastikan import ini ada
import '../controllers/halaqah_ummi_grading_controller.dart';

class HalaqahUmmiGradingView extends GetView<HalaqahUmmiGradingController> {
  const HalaqahUmmiGradingView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.group.namaGrup),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: "Input Nilai Massal",
            onPressed: () {
              Get.toNamed(
                Routes.HALAQAH_UMMI_GRADING_MASSAL,
                arguments: controller.group,
              );
            },
          ),
        ],
      ),
      body: GetBuilder<HalaqahUmmiGradingController>(
        builder: (_) {
          return FutureBuilder<List<SiswaGradingModel>>(
            future: controller.listAnggotaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Belum ada anggota di grup ini."));
              }

              final anggotaList = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                itemCount: anggotaList.length,
                itemBuilder: (context, index) {
                  final siswaModel = anggotaList[index];
                  final kelasDisplay = siswaModel.siswa.kelasId.split('-').first;
                  final hasStatusUjian = siswaModel.statusUjian != null && siswaModel.statusUjian!.isNotEmpty;
                  
                  return Card(
                    elevation: 2,
                    shape: hasStatusUjian
                        ? RoundedRectangleBorder(
                            side: BorderSide(color: siswaModel.statusUjian == 'Diajukan' ? Colors.blue : Colors.amber, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Get.toNamed(
                          Routes.HALAQAH_UMMI_RIWAYAT_PENGAMPU,
                          arguments: siswaModel.siswa,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: siswaModel.siswa.fotoProfilUrl != null
                                      ? CachedNetworkImageProvider(siswaModel.siswa.fotoProfilUrl!)
                                      : null,
                                  child: siswaModel.siswa.fotoProfilUrl == null
                                      ? Text(siswaModel.siswa.nama[0], style: const TextStyle(fontSize: 24))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(siswaModel.siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text("Kelas: $kelasDisplay", style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                if (hasStatusUjian)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (siswaModel.statusUjian == 'Diajukan' ? Colors.blue : Colors.amber).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      siswaModel.statusUjian!,
                                      style: TextStyle(
                                        color: siswaModel.statusUjian == 'Diajukan' ? Colors.blue.shade800 : Colors.amber.shade800,
                                        fontWeight: FontWeight.bold, fontSize: 10,
                                      ),
                                    ),
                                  )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildProgresIndicator(siswaModel.progresData),
                                Row(
                                  children: [
                                    if (!hasStatusUjian)
                                      IconButton(
                                        icon: const Icon(Icons.flag_outlined, color: Colors.blueGrey),
                                        tooltip: "Ajukan Munaqosyah/Ujian",
                                        onPressed: () => controller.ajukanMunaqosyah(siswaModel),
                                      ),
                                    ElevatedButton(
                                      child: const Text("Nilai"),
                                      // onPressed: () => controller.openGradingSheet(siswaModel),
                                      onPressed: () => _openGradingSheet(context, siswaModel),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProgresIndicator(Map<String, dynamic> progresData) {
    final tingkat = progresData['tingkat'] ?? 'Jilid';
    final detailTingkat = progresData['detailTingkat'] ?? '1';
    final halaman = progresData['halaman'] ?? 1;
    final color = _getJilidColor(detailTingkat);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "$tingkat $detailTingkat",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "Hal $halaman",
            style: TextStyle(color: Colors.grey[800], fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.trending_up, color: Colors.green, size: 16),
      ],
    );
  }

  Color _getJilidColor(String detailTingkat) {
    switch (detailTingkat) {
      case '1': return Colors.red;
      case '2': return Colors.orange;
      case '3': return Colors.green;
      case '4': return Colors.blue;
      case '5': return Colors.pink;
      case '6': return Colors.purple;
      default: return Colors.grey;
    }
  }

  void _openGradingSheet(BuildContext context, SiswaGradingModel siswaModel) {
    // Reset form dari controller
    controller.selectedStatus.value = "Lancar";
    controller.nilaiC.clear();
    controller.catatanC.clear();
    controller.lokasiC.text = controller.group.lokasiDefault;

    Get.bottomSheet(
      Container(
        // Gunakan tinggi layar agar lebih responsif
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header BottomSheet
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text("Penilaian: ${siswaModel.siswa.nama}", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            // Text("Progres Saat Ini: ${siswaModel.progresData}", 
            Text("Progres Saat Ini: ${siswaModel.progresTingkat} ${siswaModel.progresDetailTingkat} Hal ${siswaModel.progresHalaman}", 
            style: Get.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 24),

            // Konten Form yang bisa di-scroll
            Expanded(
              child: ListView(
                children: [
                  const Text("Status Setoran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  // Gunakan Obx untuk reaktivitas pada pilihan status
                  Obx(() => Row(
                    children: [
                      _buildStatusChip("Lancar"),
                      _buildStatusChip("Perlu Perbaikan"),
                      _buildStatusChip("Mengulang"),
                    ],
                  )),
                  const SizedBox(height: 24),
                  
                  TextField(controller: controller.nilaiC, decoration: const InputDecoration(labelText: "Nilai (0-100)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  
                  TextField(controller: controller.lokasiC, decoration: const InputDecoration(labelText: "Lokasi Setoran", border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  
                  TextField(controller: controller.catatanC, decoration: const InputDecoration(labelText: "Catatan untuk Orang Tua", border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Tombol Simpan (di luar ListView agar tetap terlihat)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.isSaving.value ? null : () => controller.saveIndividualGrading(siswaModel),
                  child: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Penilaian"),
                ),
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Agar background container yang terlihat
    );
  }

  Widget _buildStatusChip(String title) {
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectedStatus.value = title,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: controller.selectedStatus.value == title
                ? Get.theme.primaryColor.withOpacity(0.1)
                : Colors.grey[200],
            border: Border.all(
              color: controller.selectedStatus.value == title
                  ? Get.theme.primaryColor
                  : Colors.grey[400]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Radio<String>(
                value: title,
                groupValue: controller.selectedStatus.value,
                onChanged: (value) => controller.selectedStatus.value = value!,
              ),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../routes/app_pages.dart';
// import '../controllers/halaqah_ummi_grading_controller.dart';

// class HalaqahUmmiGradingView extends GetView<HalaqahUmmiGradingController> {
//   const HalaqahUmmiGradingView({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(controller.group.namaGrup),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.grid_on),
//             tooltip: "Input Nilai Semua Siswa",
//             onPressed: () {
//               Get.toNamed(
//                 Routes.HALAQAH_UMMI_GRADING_MASSAL,
//                 arguments: controller.group, // Kirim data grup ke halaman massal
//               );
//             },
//           ),
//         ],
//       ),
//       body: GetBuilder<HalaqahUmmiGradingController>(
//         builder: (_) {
//           return FutureBuilder<List<SiswaGradingModel>>(
//             future: controller.listAnggotaFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text("Error: ${snapshot.error}"));
//               }
//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return const Center(child: Text("Belum ada anggota di grup ini."));
//               }

//               final anggotaList = snapshot.data!;

//               return ListView.builder(
//                 padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
//                 itemCount: anggotaList.length,
//                 itemBuilder: (context, index) {
//                   final siswaModel = anggotaList[index];
//                   final kelasDisplay = siswaModel.siswa.kelasId.split('-').first;
//                   final bool hasStatusUjian = siswaModel.statusUjian != null && siswaModel.statusUjian!.isNotEmpty;

//                   return Card(
//                     elevation: 2,
//                     shape: hasStatusUjian 
//                         ? RoundedRectangleBorder(
//                             side: BorderSide(color: siswaModel.statusUjian == 'Diajukan' ? Colors.blue : Colors.amber, width: 2),
//                             borderRadius: BorderRadius.circular(12),
//                           )
//                         : null,
//                     margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     clipBehavior: Clip.antiAlias,
//                     child: InkWell(
//                       onTap: () => controller.openGradingSheet(siswaModel),
//                       child: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                             CircleAvatar(
//                               radius: 28,
//                               backgroundImage: siswaModel.siswa.fotoProfilUrl != null
//                                   ? CachedNetworkImageProvider(siswaModel.siswa.fotoProfilUrl!)
//                                   : null,
//                               child: siswaModel.siswa.fotoProfilUrl == null
//                                   ? Text(siswaModel.siswa.nama[0], style: const TextStyle(fontSize: 24))
//                                   : null,
//                             ),
//                             const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(siswaModel.siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                     const SizedBox(height: 4),
//                                     Text("Kelas: $kelasDisplay", style: TextStyle(color: Colors.grey[600])),
//                                   ],
//                                 ),
//                               ),
//                               // Tombol "Ajukan" atau Badge Status
//                               if (hasStatusUjian)
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: (siswaModel.statusUjian == 'Diajukan' ? Colors.blue : Colors.amber).withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     siswaModel.statusUjian!,
//                                     style: TextStyle(
//                                       color: siswaModel.statusUjian == 'Diajukan' ? Colors.blue.shade800 : Colors.amber.shade800,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 10,
//                                     ),
//                                   ),
//                                 )
//                               else
//                                 IconButton(
//                                   icon: const Icon(Icons.flag, color: Colors.blue),
//                                   tooltip: "Ajukan Munaqosyah/Ujian",
//                                   onPressed: () => controller.ajukanMunaqosyah(siswaModel),
//                                 )
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           _buildProgresIndicator(siswaModel.progresData as SiswaGradingModel),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   // WIDGET BARU UNTUK INDIKATOR PROGRES
//   Widget _buildProgresIndicator(SiswaGradingModel siswaModel) {
//     final color = _getJilidColor(siswaModel.progresDetailTingkat);
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: Text(
//             "${siswaModel.progresTingkat} ${siswaModel.progresDetailTingkat}",
//             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: Colors.grey[200],
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: Text(
//             "Hal ${siswaModel.progresHalaman}",
//             style: TextStyle(color: Colors.grey[800], fontSize: 12),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Icon(Icons.trending_up, color: Colors.green, size: 16),
//       ],
//     );
//   }

//   // FUNGSI HELPER BARU UNTUK WARNA JILID
//   Color _getJilidColor(String detailTingkat) {
//     switch (detailTingkat) {
//       case '1': return Colors.red;
//       case '2': return Colors.orange;
//       case '3': return Colors.green;
//       case '4': return Colors.blue;
//       case '5': return Colors.pink;
//       case '6': return Colors.purple;
//       default: return Colors.grey;
//     }
//   }

//   void _openGradingSheet(BuildContext context, SiswaGradingModel siswaModel) {
//     // Reset form dari controller
//     controller.selectedStatus.value = "Lancar";
//     controller.nilaiC.clear();
//     controller.catatanC.clear();
//     controller.lokasiC.text = controller.group.lokasiDefault;

//     Get.bottomSheet(
//       Container(
//         // Gunakan tinggi layar agar lebih responsif
//         height: MediaQuery.of(context).size.height * 0.85,
//         padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(24),
//             topRight: Radius.circular(24),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header BottomSheet
//             Center(
//               child: Container(
//                 width: 40,
//                 height: 5,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text("Penilaian: ${siswaModel.siswa.nama}", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
//             Text("Progres Saat Ini: ${siswaModel.progresData}", style: Get.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
//             const SizedBox(height: 24),

//             // Konten Form yang bisa di-scroll
//             Expanded(
//               child: ListView(
//                 children: [
//                   const Text("Status Setoran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                   const SizedBox(height: 8),
//                   // Gunakan Obx untuk reaktivitas pada pilihan status
//                   Obx(() => Row(
//                     children: [
//                       _buildStatusChip("Lancar"),
//                       _buildStatusChip("Perlu Perbaikan"),
//                       _buildStatusChip("Mengulang"),
//                     ],
//                   )),
//                   const SizedBox(height: 24),
                  
//                   TextField(controller: controller.nilaiC, decoration: const InputDecoration(labelText: "Nilai (0-100)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
//                   const SizedBox(height: 16),
                  
//                   TextField(controller: controller.lokasiC, decoration: const InputDecoration(labelText: "Lokasi Setoran", border: OutlineInputBorder())),
//                   const SizedBox(height: 16),
                  
//                   TextField(controller: controller.catatanC, decoration: const InputDecoration(labelText: "Catatan untuk Orang Tua", border: OutlineInputBorder()), maxLines: 3),
//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),

//             // Tombol Simpan (di luar ListView agar tetap terlihat)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 16.0),
//               child: Obx(() => SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   onPressed: controller.isSaving.value ? null : () => controller.saveIndividualGrading(siswaModel),
//                   child: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Penilaian"),
//                 ),
//               )),
//             ),
//           ],
//         ),
//       ),
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent, // Agar background container yang terlihat
//     );
//   }

//   Widget _buildStatusChip(String title) {
//     return Expanded(
//       child: InkWell(
//         onTap: () => controller.selectedStatus.value = title,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 4),
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//           decoration: BoxDecoration(
//             color: controller.selectedStatus.value == title
//                 ? Get.theme.primaryColor.withOpacity(0.1)
//                 : Colors.grey[200],
//             border: Border.all(
//               color: controller.selectedStatus.value == title
//                   ? Get.theme.primaryColor
//                   : Colors.grey[400]!,
//             ),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Column(
//             children: [
//               Radio<String>(
//                 value: title,
//                 groupValue: controller.selectedStatus.value,
//                 onChanged: (value) => controller.selectedStatus.value = value!,
//               ),
//               Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import '../../../routes/app_pages.dart';
// // import '../controllers/halaqah_ummi_grading_controller.dart';

// // class HalaqahUmmiGradingView extends GetView<HalaqahUmmiGradingController> {
// //   const HalaqahUmmiGradingView({Key? key}) : super(key: key);
// //   @override
// //   Widget build(BuildContext context) {
// //     // Controller sudah di-binding, kita bisa panggil methodnya langsung.
// //     // Tidak perlu membuat instance baru di sini.
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(controller.group.namaGrup),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.grid_on),
// //             tooltip: "Input Nilai Massal",
// //             onPressed: () {
// //               Get.snackbar("Info", "Fitur input nilai massal akan segera hadir!");
// //             },
// //           ),
// //         ],
// //       ),
// //       body: GetBuilder<HalaqahUmmiGradingController>(
// //         builder: (_) {
// //           return FutureBuilder<List<SiswaGradingModel>>(
// //             future: controller.listAnggotaFuture,
// //             builder: (context, snapshot) {
// //               if (snapshot.connectionState == ConnectionState.waiting) {
// //                 return const Center(child: CircularProgressIndicator());
// //               }
// //               if (snapshot.hasError) {
// //                 return Center(child: Text("Error: ${snapshot.error}"));
// //               }
// //               if (!snapshot.hasData || snapshot.data!.isEmpty) {
// //                 return const Center(child: Text("Belum ada anggota di grup ini."));
// //               }

// //               final anggotaList = snapshot.data!;

// //               return ListView.builder(
// //                 padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
// //                 itemCount: anggotaList.length,
// //                 itemBuilder: (context, index) {
// //                   final siswaModel = anggotaList[index];
// //                   return Card(
// //                     elevation: 2,
// //                     margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// //                     child: ListTile(
// //                       // --- TAMBAHKAN onTap DI SINI ---
// //                       onTap: () => Get.toNamed(
// //                         Routes.HALAQAH_UMMI_RIWAYAT_PENGAMPU, 
// //                         arguments: siswaModel.siswa
// //                       ),
// //                       // --- AKHIR TAMBAHAN ---
// //                       leading: CircleAvatar(child: Text(siswaModel.siswa.nama[0])),
// //                       title: Text(siswaModel.siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
// //                       subtitle: Text("Progres: ${siswaModel.progres}"),
// //                       trailing: ElevatedButton(
// //                         child: const Text("Beri Nilai"),
// //                         onPressed: () => _openGradingSheet(context, siswaModel),
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               );
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   // --- [PEROMBAKAN UTAMA DIMULAI DI SINI] ---
// //   // Method ini diubah menjadi private dan dipanggil dari view
// //   void _openGradingSheet(BuildContext context, SiswaGradingModel siswaModel) {
// //     // Reset form dari controller
// //     controller.selectedStatus.value = "Lancar";
// //     controller.nilaiC.clear();
// //     controller.catatanC.clear();
// //     controller.lokasiC.text = controller.group.lokasiDefault;

// //     Get.bottomSheet(
// //       Container(
// //         // Gunakan tinggi layar agar lebih responsif
// //         height: MediaQuery.of(context).size.height * 0.85,
// //         padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
// //         decoration: const BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.only(
// //             topLeft: Radius.circular(24),
// //             topRight: Radius.circular(24),
// //           ),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Header BottomSheet
// //             Center(
// //               child: Container(
// //                 width: 40,
// //                 height: 5,
// //                 decoration: BoxDecoration(
// //                   color: Colors.grey[300],
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(height: 16),
// //             Text("Penilaian: ${siswaModel.siswa.nama}", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
// //             Text("Progres Saat Ini: ${siswaModel.progres}", style: Get.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
// //             const SizedBox(height: 24),

// //             // Konten Form yang bisa di-scroll
// //             Expanded(
// //               child: ListView(
// //                 children: [
// //                   const Text("Status Setoran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
// //                   const SizedBox(height: 8),
// //                   // Gunakan Obx untuk reaktivitas pada pilihan status
// //                   Obx(() => Row(
// //                     children: [
// //                       _buildStatusChip("Lancar"),
// //                       _buildStatusChip("Perlu Perbaikan"),
// //                       _buildStatusChip("Mengulang"),
// //                     ],
// //                   )),
// //                   const SizedBox(height: 24),
                  
// //                   TextField(controller: controller.nilaiC, decoration: const InputDecoration(labelText: "Nilai (0-100)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
// //                   const SizedBox(height: 16),
                  
// //                   TextField(controller: controller.lokasiC, decoration: const InputDecoration(labelText: "Lokasi Setoran", border: OutlineInputBorder())),
// //                   const SizedBox(height: 16),
                  
// //                   TextField(controller: controller.catatanC, decoration: const InputDecoration(labelText: "Catatan untuk Orang Tua", border: OutlineInputBorder()), maxLines: 3),
// //                   const SizedBox(height: 24),
// //                 ],
// //               ),
// //             ),

// //             // Tombol Simpan (di luar ListView agar tetap terlihat)
// //             Padding(
// //               padding: const EdgeInsets.symmetric(vertical: 16.0),
// //               child: Obx(() => SizedBox(
// //                 width: double.infinity,
// //                 child: ElevatedButton(
// //                   style: ElevatedButton.styleFrom(
// //                     padding: const EdgeInsets.symmetric(vertical: 16),
// //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                   ),
// //                   onPressed: controller.isSaving.value ? null : () => controller.saveIndividualGrading(siswaModel),
// //                   child: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Penilaian"),
// //                 ),
// //               )),
// //             ),
// //           ],
// //         ),
// //       ),
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent, // Agar background container yang terlihat
// //     );
// //   }

// //   // Helper widget untuk membuat tombol radio kustom yang lebih baik
// //   Widget _buildStatusChip(String title) {
// //     return Expanded(
// //       child: InkWell(
// //         onTap: () => controller.selectedStatus.value = title,
// //         borderRadius: BorderRadius.circular(8),
// //         child: Container(
// //           margin: const EdgeInsets.symmetric(horizontal: 4),
// //           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
// //           decoration: BoxDecoration(
// //             color: controller.selectedStatus.value == title
// //                 ? Get.theme.primaryColor.withOpacity(0.1)
// //                 : Colors.grey[200],
// //             border: Border.all(
// //               color: controller.selectedStatus.value == title
// //                   ? Get.theme.primaryColor
// //                   : Colors.grey[400]!,
// //             ),
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //           child: Column(
// //             children: [
// //               Radio<String>(
// //                 value: title,
// //                 groupValue: controller.selectedStatus.value,
// //                 onChanged: (value) => controller.selectedStatus.value = value!,
// //               ),
// //               Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }