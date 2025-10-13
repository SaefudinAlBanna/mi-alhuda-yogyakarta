// lib/app/modules/rincian_tunggakan/controllers/rincian_tunggakan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/tunggakan_siswa_model.dart';

class RincianTunggakanController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final isProcessingPdf = false.obs;
  final String jenisPembayaran = Get.arguments['jenisPembayaran'];
  final String filterKelas = Get.arguments['filterKelas'];

  final RxList<TunggakanSiswaModel> daftarPenunggak = <TunggakanSiswaModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchDataTunggakan();
  }

  Future<void> _fetchDataTunggakan() async {
    isLoading.value = true;
    try {
      Query query = _firestore.collectionGroup('tagihan')
          .where('idTahunAjaran', isEqualTo: configC.tahunAjaranAktif.value)
          .where('jenisPembayaran', isEqualTo: jenisPembayaran)
          .where('status', isNotEqualTo: 'Lunas');

      if (filterKelas != 'Semua Kelas') {
        query = query.where('kelasSaatDitagih', isGreaterThanOrEqualTo: filterKelas)
                     .where('kelasSaatDitagih', isLessThan: '$filterKelas\uf8ff');
      }

      if (jenisPembayaran == 'SPP') {
        query = query.where('tanggalJatuhTempo', isLessThan: Timestamp.now());
      }

      final snapshot = await query.get();

      final Map<String, TunggakanSiswaModel> mapPenunggak = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final sisaTagihan = ((data['jumlahTagihan'] ?? 0) - (data['jumlahTerbayar'] ?? 0)).toInt();

        if (sisaTagihan > 0) {
          final idSiswa = data['idSiswa'] as String;
          if (mapPenunggak.containsKey(idSiswa)) {
            mapPenunggak[idSiswa]!.totalTunggakan = (mapPenunggak[idSiswa]!.totalTunggakan + sisaTagihan).toInt();
          } else {
            mapPenunggak[idSiswa] = TunggakanSiswaModel(
              uid: idSiswa,
              namaSiswa: data['namaSiswa'] ?? 'Tanpa Nama',
              kelasId: data['kelasSaatDitagih'],
              totalTunggakan: sisaTagihan.toInt(),
            );
          }
        }
      }

      final result = mapPenunggak.values.toList();

      // [PENYEMPURNAAN KUNCI DI SINI] Logika Pengurutan Kustom
      result.sort((a, b) {
        // Ekstrak angka dan huruf dari nama kelas
        final regex = RegExp(r'(\d+)([A-Z]?)');
        
        final matchA = regex.firstMatch(a.namaKelasSimple);
        final matchB = regex.firstMatch(b.namaKelasSimple);

        final numA = int.tryParse(matchA?.group(1) ?? '0') ?? 0;
        final charA = matchA?.group(2) ?? '';
        
        final numB = int.tryParse(matchB?.group(1) ?? '0') ?? 0;
        final charB = matchB?.group(2) ?? '';

        // 1. Bandingkan berdasarkan angka kelas
        if (numA != numB) {
          return numA.compareTo(numB);
        }
        
        // 2. Jika angka sama, bandingkan berdasarkan huruf kelas
        if (charA != charB) {
          return charA.compareTo(charB);
        }

        // 3. Jika kelas sama, urutkan berdasarkan nama siswa
        return a.namaSiswa.compareTo(b.namaSiswa);
      });

      daftarPenunggak.assignAll(result);

    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil rincian tunggakan: ${e.toString()}");
      print("Error fetching tunggakan details: $e");
    } finally {
      isLoading.value = false;
    }
  }
  
  // [FUNGSI BARU] Logika untuk membuat dan mengekspor PDF
  Future<void> exportPdf() async {
    if (daftarPenunggak.isEmpty) {
      Get.snackbar("Tidak Ada Data", "Tidak ada data tunggakan untuk diekspor.");
      return;
    }
    isProcessingPdf.value = true;
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final logoImage = pw.MemoryImage((await rootBundle.load('assets/png/logo.png')).buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildPdfHeader(logoImage, boldFont),
          build: (context) => [_buildPdfTable(font, boldFont)],
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Halaman ${context.pageNumber} dari ${context.pagesCount}",
                style: pw.TextStyle(font: font, fontSize: 8),
              ),
            );
          },
        ),
      );
      
      final String fileName = 'laporan_tunggakan_${jenisPembayaran.replaceAll(' ', '_')}_${filterKelas.replaceAll(' ', '_')}.pdf';
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);

    } catch (e) {
      Get.snackbar("Error", "Gagal membuat file PDF: ${e.toString()}");
    } finally {
      isProcessingPdf.value = false;
    }
  }

  pw.Widget _buildPdfHeader(pw.MemoryImage logo, pw.Font boldFont) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(children: [
            pw.Image(logo, width: 50, height: 50),
            pw.SizedBox(width: 15),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("MI Al-Huda Yogyakarta", style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.Text("Laporan Tunggakan: $jenisPembayaran", style: const pw.TextStyle(fontSize: 14)),
            ]),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("Filter Kelas: $filterKelas", style: const pw.TextStyle(fontSize: 10)),
            pw.Text("T.A: ${configC.tahunAjaranAktif.value}", style: const pw.TextStyle(fontSize: 10)),
            pw.Text("Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10)),
          ]),
        ],
      ),
      pw.Divider(height: 20),
    ]);
  }
  
  pw.Widget _buildPdfTable(pw.Font font, pw.Font boldFont) {
    final headers = ['No', 'Nama Siswa', 'Kelas', 'Total Tunggakan'];
    
    final data = daftarPenunggak.asMap().entries.map((entry) {
      int index = entry.key;
      TunggakanSiswaModel siswa = entry.value;

      return [
        (index + 1).toString(),
        siswa.namaSiswa,
        siswa.namaKelasSimple,
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(siswa.totalTunggakan),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
    );
  }
}