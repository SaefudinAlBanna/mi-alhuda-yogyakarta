import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../controllers/rekap_jurnal_guru_controller.dart';

class RekapJurnalGuruView extends GetView<RekapJurnalGuruController> {
  const RekapJurnalGuruView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final ThemeData theme = Theme.of(context);
    // initializeDateFormatting('id_ID', null);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Rekap Jurnal Mengajar Saya'),
      //   centerTitle: true,
      //   backgroundColor: theme.colorScheme.primary,
      //   foregroundColor: theme.colorScheme.onPrimary,
      // ),
      // body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      //   stream: controller.getRekapJurnalGuru(),
      //   builder: (context, snapshot) {
      //     // ... (kode untuk waiting, error, dan data kosong tetap sama)
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(child: CircularProgressIndicator());
      //     }
      //     if (snapshot.hasError) {
      //       return Center(child: Text("Error: ${snapshot.error}\n\nPastikan index Firestore sudah dibuat."));
      //     }
      //     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      //       return const Center(
      //         child: Column(
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           children: [
      //             Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
      //             SizedBox(height: 10),
      //             Text("Anda belum pernah menginput jurnal."),
      //           ],
      //         ),
      //       );
      //     }

      //     var listJurnal = snapshot.data!.docs;

      //     return ListView.separated(
      //       padding: const EdgeInsets.all(16.0),
      //       itemCount: listJurnal.length,
      //       separatorBuilder: (context, index) => const SizedBox(height: 12),
      //       itemBuilder: (context, index) {
      //         Map<String, dynamic> data = listJurnal[index].data();
              
      //         // === KODE BARU YANG LEBIH AMAN ===
      //         DateTime tanggalInput;
      //         final dynamic tanggalValue = data['tanggalinput'];

      //         if (tanggalValue is Timestamp) {
      //           // Jika data adalah Timestamp (benar)
      //           tanggalInput = tanggalValue.toDate();
      //         } else if (tanggalValue is String) {
      //           // Jika data adalah String (data lama), coba ubah ke DateTime
      //           tanggalInput = DateTime.tryParse(tanggalValue) ?? DateTime.now();
      //         } else {
      //           // Jika null atau tipe lain, gunakan waktu sekarang sebagai fallback
      //           tanggalInput = DateTime.now();
      //         }
      //         // === AKHIR DARI KODE BARU ===

      //         String tanggalFormatted = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tanggalInput);
              
      //         return Card(
      //           // ... (sisa kode Card-nya sama, tidak perlu diubah)
      //           elevation: 2,
      //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      //           child: Padding(
      //             padding: const EdgeInsets.all(12.0),
      //             child: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                  Row(
      //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                   children: [
      //                     Text(
      //                       data['jampelajaran'] ?? 'Jam Pelajaran',
      //                       style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
      //                     ),
      //                     Text(
      //                       tanggalFormatted,
      //                       style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      //                     ),
      //                   ],
      //                 ),
      //                 const Divider(height: 12),
      //                 Text.rich(TextSpan(children: [
      //                   TextSpan(text: "Kelas: ", style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
      //                   TextSpan(text: "${data['kelas'] ?? '-'}", style: TextStyle(color: theme.colorScheme.onSurface)),
      //                 ]), style: theme.textTheme.bodyMedium),
      //                 const SizedBox(height: 4),
      //                 Text.rich(TextSpan(children: [
      //                   TextSpan(text: "Mapel: ", style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
      //                   TextSpan(text: "${data['namamapel'] ?? '-'}", style: TextStyle(color: theme.colorScheme.onSurface)),
      //                 ]), style: theme.textTheme.bodyMedium),
      //                 const SizedBox(height: 4),
      //                 Text.rich(TextSpan(children: [
      //                   TextSpan(text: "Materi: ", style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
      //                   TextSpan(text: "${data['materipelajaran'] ?? '-'}", style: TextStyle(color: theme.colorScheme.onSurface)),
      //                 ]), style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis,),
      //                 if (data['catatanjurnal'] != null && (data['catatanjurnal'] as String).isNotEmpty) ...[
      //                   const SizedBox(height: 6),
      //                   Text.rich(TextSpan(children: [
      //                     TextSpan(text: "Catatan: ", style: TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
      //                     TextSpan(text: "${data['catatanjurnal']}", style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface)),
      //                   ]), style: theme.textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis,),
      //                 ]
      //               ],
      //             ),
      //           ),
      //         );
      //       },
      //     );
      //   },
      // ),
    );
  }
}