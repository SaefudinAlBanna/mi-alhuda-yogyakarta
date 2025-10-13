import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../controllers/rekap_jurnal_admin_controller.dart';

class RekapJurnalAdminView extends GetView<RekapJurnalAdminController> {
  const RekapJurnalAdminView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final ThemeData theme = Theme.of(context);
    // initializeDateFormatting('id_ID', null);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Rekap Jurnal Seluruh Guru'),
      //   centerTitle: true,
      //   backgroundColor: theme.colorScheme.primary,
      //   foregroundColor: theme.colorScheme.onPrimary,
      // ),
      // body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      //   stream: controller.getAllJurnalRekap(),
      //   builder: (context, snapshot) {
      //     // ... (kode untuk waiting, error, dan data kosong tetap sama)
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(child: CircularProgressIndicator());
      //     }
      //     if (snapshot.hasError) {
      //       return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center)));
      //     }
      //     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      //       return const Center(child: Text("Belum ada jurnal yang diinput oleh guru manapun."));
      //     }

      //     var listJurnal = snapshot.data!.docs;

      //     return ListView.builder(
      //       padding: const EdgeInsets.all(16.0),
      //       itemCount: listJurnal.length,
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

      //         String tanggalFormatted = DateFormat('EEEE, dd MMM yyyy, HH:mm', 'id_ID').format(tanggalInput);
              
      //         return Card(
      //           // ... (sisa kode Card-nya sama, tidak perlu diubah)
      //           elevation: 2,
      //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      //           child: Padding(
      //             padding: const EdgeInsets.all(12.0),
      //             child: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 Text(
      //                   "${data['namapenginput'] ?? 'Tanpa Nama Guru'}",
      //                   style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      //                 ),
      //                 Text(
      //                   tanggalFormatted,
      //                   style: theme.textTheme.bodySmall,
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