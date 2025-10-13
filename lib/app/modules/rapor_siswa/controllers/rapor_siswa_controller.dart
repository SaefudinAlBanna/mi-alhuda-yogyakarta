// app/modules/rapor_siswa/controllers/rapor_siswa_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Model sederhana untuk menampung hasil olahan nilai per mapel
// class RaporMapel {
//   String namaMapel;
//   double nilaiAkhir;
//   String capaianKompetensi;

//   RaporMapel({
//     required this.namaMapel,
//     required this.nilaiAkhir,
//     required this.capaianKompetensi,
//   });
// }

class RaporSiswaController extends GetxController {
//   final Map<String, dynamic> args = Get.arguments; // Terima data siswa (idSiswa, namaSiswa, idKelas, dll)

//   var isLoading = true.obs;
  
//   // Variabel untuk menampung semua data rapor yang sudah matang
//   Rx<Map<String, dynamic>> dataSiswa = Rx({});
//   RxList<RaporMapel> daftarNilaiRapor = <RaporMapel>[].obs;
//   Rx<Map<String, dynamic>> dataPendukungRapor = Rx({});

//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   // Path-path dasar bisa Anda ambil dari argumen
//   late String basePath; 

//   @override
//   void onInit() {
//     super.onInit();
//     // Path dasar menuju data siswa di semester ini
//     basePath = "/Sekolah/P9984539/tahunajaran/2024-2025/kelastahunajaran/${args['idKelas']}/daftarsiswa/${args['idsiswa']}/Semester/Semester I";
    
//     fetchRaporData();
//   }

//   // Di dalam RaporSiswaController

// // import 'package:pdf/widgets.dart' as pw;
// // import 'package:printing/printing.dart';

// Future<void> generatePdfRapor() async {
//   final doc = pw.Document();

//   // Ambil data yang sudah ada
//   final listNilai = daftarNilaiRapor; 
  
//   doc.addPage(
//     pw.Page(
//       build: (pw.Context context) {
//         return pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             // Header
//             pw.Text("Rapor Siswa", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
//             pw.SizedBox(height: 20),
//             pw.Text("Nama: ${dataSiswa.value['namasiswa']}"),
//             // ... header lainnya ...
//             pw.SizedBox(height: 20),
            
//             // Tabel Nilai
//             pw.Table.fromTextArray(
//               headers: ['No', 'Mata Pelajaran', 'Nilai Akhir', 'Capaian Kompetensi'],
//               data: List<List<String>>.generate(
//                 listNilai.length, 
//                 (index) => [
//                   (index+1).toString(),
//                   listNilai[index].namaMapel,
//                   listNilai[index].nilaiAkhir.toStringAsFixed(1),
//                   listNilai[index].capaianKompetensi,
//                 ]
//               ),
//             ),
//              pw.SizedBox(height: 20),
//             pw.Text("Catatan Wali Kelas:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//             pw.Text(dataPendukungRapor.value['catatanWaliKelas'] ?? ''),
//           ]
//         );
//       },
//     ),
//   );

//   // Tampilkan preview cetak
//   await Printing.layoutPdf(onLayout: (format) async => doc.save());
// }

//   Future<void> fetchRaporData() async {
//     try {
//       isLoading.value = true;
      
//       // 1. Ambil daftar mata pelajaran siswa
//       QuerySnapshot mapelSnapshot = await firestore.collection('$basePath/matapelajaran').get();
//       List<String> daftarMapelIds = mapelSnapshot.docs.map((doc) => doc.id).toList();

//       // 2. Loop setiap mata pelajaran untuk mengolah nilainya
//       List<RaporMapel> hasilOlahNilai = [];
//       for (String idMapel in daftarMapelIds) {
//         QuerySnapshot nilaiSnapshot = await firestore
//             .collection('$basePath/matapelajaran/$idMapel/nilai')
//             .where('jenisNilai', isEqualTo: 'Sumatif') // Hanya ambil nilai sumatif
//             .get();

//         if (nilaiSnapshot.docs.isNotEmpty) {
//           double totalNilai = 0;
//           List<String> deskripsiList = [];
          
//           for (var doc in nilaiSnapshot.docs) {
//             totalNilai += (doc.data() as Map)['nilai'];
//             if ((doc.data() as Map)['deskripsi'] != null && (doc.data() as Map)['deskripsi'].isNotEmpty) {
//               deskripsiList.add((doc.data() as Map)['deskripsi']);
//             }
//           }
          
//           double rataRata = totalNilai / nilaiSnapshot.docs.length;
//           String capaian = deskripsiList.join('. '); // Gabungkan semua deskripsi

//           hasilOlahNilai.add(RaporMapel(
//             namaMapel: idMapel, 
//             nilaiAkhir: rataRata, 
//             capaianKompetensi: capaian.isEmpty ? 'Capaian kompetensi sudah baik.' : capaian,
//           ));
//         }
//       }
//       daftarNilaiRapor.value = hasilOlahNilai;
      
//       // 3. Ambil data pendukung (absensi, catatan, dll)
//       // Ini asumsi hanya ada 1 dokumen di koleksi raporData
//       QuerySnapshot raporDataSnapshot = await firestore.collection('$basePath/raporData').limit(1).get();
//       if(raporDataSnapshot.docs.isNotEmpty){
//         dataPendukungRapor.value = raporDataSnapshot.docs.first.data() as Map<String, dynamic>;
//       }

//       // 4. Set data siswa
//       dataSiswa.value = args;

//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat data rapor: $e");
//       print(e);
//     } finally {
//       isLoading.value = false;
//     }
//   }

  
}