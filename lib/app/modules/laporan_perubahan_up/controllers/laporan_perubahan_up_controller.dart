// lib/app/modules/laporan_perubahan_up/controllers/laporan_perubahan_up_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/log_perubahan_model.dart'; // Kita akan buat model ini

class LaporanPerubahanUpController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final isProcessingPdf = false.obs;

  final RxList<LogPerubahanModel> _masterLogList = <LogPerubahanModel>[].obs;
  final RxList<LogPerubahanModel> filteredLogList = <LogPerubahanModel>[].obs;
  
  final RxList<String> alasanFilterOptions = <String>['Semua Alasan'].obs;
  final RxString selectedAlasan = 'Semua Alasan'.obs;

  // Variabel untuk menampung info sekolah (untuk Kop PDF)
  final RxMap<String, dynamic> infoSekolah = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    ever(selectedAlasan, (_) => _applyFilter());
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      // Ambil data log dan info sekolah secara bersamaan
      await Future.wait([
        _fetchLogs(),
        _fetchInfoSekolah(),
      ]);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data log: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchLogs() async {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('log_perubahan_keuangan')
        .orderBy('timestamp', descending: true)
        .get();

    final logs = snapshot.docs.map((doc) => LogPerubahanModel.fromFirestore(doc)).toList();
    _masterLogList.assignAll(logs);
    filteredLogList.assignAll(logs);

    // Buat opsi filter dinamis dari data yang ada
    final Set<String> alasanSet = logs.map((log) => log.alasan).toSet();
    alasanFilterOptions.addAll(alasanSet.toList()..sort());
  }
  
  Future<void> _fetchInfoSekolah() async {
    try {
      final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah).get();
      if (doc.exists) {
        infoSekolah.value = doc.data() ?? {};
      }
    } catch (e) {
      print("### Gagal mengambil info sekolah untuk PDF: $e");
    }
  }

  void _applyFilter() {
    if (selectedAlasan.value == 'Semua Alasan') {
      filteredLogList.assignAll(_masterLogList);
    } else {
      final filtered = _masterLogList.where((log) => log.alasan == selectedAlasan.value).toList();
      filteredLogList.assignAll(filtered);
    }
  }

  Future<void> exportPdf() async {
    if (filteredLogList.isEmpty) {
      Get.snackbar("Info", "Tidak ada data untuk diekspor ke PDF.");
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
        ),
      );

      final String fileName = 'laporan_perubahan_uang_pangkal.pdf';
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);

    } catch (e) {
      Get.snackbar("Error", "Gagal membuat file PDF: ${e.toString()}");
    } finally {
      isProcessingPdf.value = false;
    }
  }

  pw.Widget _buildPdfHeader(pw.MemoryImage logo, pw.Font boldFont) {
    final namaSekolah = infoSekolah.value['namasekolah'] ?? infoSekolah.value['nama'] ?? 'MI Al-Huda YK';
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(children: [
            pw.Image(logo, width: 50, height: 50),
            pw.SizedBox(width: 15),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(namaSekolah.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.Text("Laporan Perubahan Nominal Uang Pangkal", style: const pw.TextStyle(fontSize: 12)),
            ]),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("Filter: ${selectedAlasan.value}", style: const pw.TextStyle(fontSize: 10)),
            pw.Text("Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10)),
          ]),
        ],
      ),
      pw.Divider(height: 20),
    ]);
  }

  pw.Widget _buildPdfTable(pw.Font font, pw.Font boldFont) {
    // Kelompokkan data berdasarkan alasan
    final Map<String, List<LogPerubahanModel>> groupedData = {};
    for (var log in filteredLogList) {
      if (!groupedData.containsKey(log.alasan)) {
        groupedData[log.alasan] = [];
      }
      groupedData[log.alasan]!.add(log);
    }

    final List<pw.Widget> widgets = [];
    groupedData.forEach((alasan, logs) {
      widgets.add(pw.Header(
        level: 1,
        text: 'Alasan: $alasan',
        textStyle: pw.TextStyle(font: boldFont, fontSize: 12),
      ));

      final headers = ['Waktu', 'Nama Siswa', 'Nominal Lama', 'Nominal Baru', 'Diubah Oleh'];
      final data = logs.map((log) => [
        DateFormat('dd/MM/yy HH:mm').format(log.timestamp),
        log.namaSiswa,
        NumberFormat.decimalPattern('id_ID').format(log.nominalLama),
        NumberFormat.decimalPattern('id_ID').format(log.nominalBaru),
        log.diubahOleh['nama'],
      ]).toList();

      widgets.add(pw.Table.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
        cellStyle: pw.TextStyle(font: font, fontSize: 9),
        cellAlignments: {
          0: pw.Alignment.center,
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.center,
        },
      ));
      widgets.add(pw.SizedBox(height: 15));
    });

    return pw.Column(children: widgets);
  }
}