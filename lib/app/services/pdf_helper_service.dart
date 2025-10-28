// lib/app/services/pdf_helper_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../controllers/config_controller.dart';
import '../models/absensi_rekap_model.dart';
import '../models/jurnal_laporan_item_model.dart';
import '../modules/halaqah_ummi_dashboard_koordinator/controllers/halaqah_ummi_dashboard_koordinator_controller.dart';
import '../modules/rekap_absensi/controllers/rekap_absensi_controller.dart';

class PdfHelperService {

  // =======================================================================
  // KOMPONEN-KOMPONEN STANDAR PDF (REUSABLE)
  // =======================================================================

  /// Membangun Kop Surat A4 Profesional yang Standar (Versi Sinkronus)
  static pw.Widget buildHeaderA4({
    required Map<String, dynamic> infoSekolah,
    required pw.MemoryImage logoImage,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    final yayasan = infoSekolah['yayasan'] ?? 'Yayasan Pendidikan';
    final namaSekolah = infoSekolah['namasekolah'] ?? infoSekolah['nama'] ?? 'MI Al-Huda Yogyakarta';
    final akreditasi = infoSekolah['akreditasi'] ?? '';
    final npsn = infoSekolah['npsn'] ?? '';
    final alamat = infoSekolah['alamatsekolah'] ?? '';
    final telp = infoSekolah['notelp'] ?? '';
    final email = infoSekolah['email'] ?? '';

    return pw.Column(children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(logoImage, width: 60, height: 60),
          pw.SizedBox(width: 15),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(yayasan.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.Text(namaSekolah.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 18)),
              if (akreditasi.isNotEmpty || npsn.isNotEmpty)
                pw.Text("Terakreditasi: $akreditasi | NPSN: $npsn", style: pw.TextStyle(font: regularFont, fontSize: 9)),
              if (alamat.isNotEmpty)
                pw.Text("Alamat: $alamat", style: pw.TextStyle(font: regularFont, fontSize: 9)),
              if (telp.isNotEmpty || email.isNotEmpty)
                pw.Text("Telp: $telp | Email: $email", style: pw.TextStyle(font: regularFont, fontSize: 9)),
            ]
          ),
        ],
      ),
      pw.Divider(height: 2, thickness: 2),
    ]);
  }

  static pw.Widget buildFooter(pw.Context context, pw.Font regularFont) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        "Halaman ${context.pageNumber} dari ${context.pagesCount}",
        style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  // =======================================================================
  // FUNGSI SPESIFIK UNTUK MEMBANGUN KONTEN LAPORAN
  // =======================================================================

  /// Membangun blok laporan jurnal harian
  static Future<List<pw.Widget>> buildJurnalReportContent({
    required List<JurnalLaporanItem> laporanData,
    required bool isLaporanPimpinan,
  }) async {
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final italicFont = await PdfGoogleFonts.poppinsItalic();
    
    final Map<String, List<JurnalLaporanItem>> groupedData = {};
    for (var item in laporanData) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.tanggal);
      if (!groupedData.containsKey(dateKey)) groupedData[dateKey] = [];
      groupedData[dateKey]!.add(item);
    }

    List<pw.Widget> widgets = [];
    for (var entry in groupedData.entries) {
      widgets.add(_buildDailyReportBlock(entry.value, isLaporanPimpinan, font, boldFont, italicFont));
      widgets.add(pw.SizedBox(height: 12));
    }
    return widgets;
  }
  
  // Helper internal untuk buildJurnalReportContent
  static pw.Widget _buildDailyReportBlock(List<JurnalLaporanItem> items, bool isPimpinan, pw.Font font, pw.Font boldFont, pw.Font italicFont) {
    final date = items.first.tanggal;
    final rekapAbsensi = items.first.rekapAbsensi;

    final headers = ['Jam', if (isPimpinan) 'Guru', 'Mapel', 'Kelas', 'Materi & Catatan'];

    final data = items.map((item) {
      final materiDanCatatan = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(item.materi, style: pw.TextStyle(font: font, fontSize: 8)),
          if (item.catatan != null && item.catatan!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                "Catatan: ${item.catatan}",
                style: pw.TextStyle(font: italicFont, fontSize: 7, color: PdfColors.grey600),
              ),
            ),
        ],
      );

      return [
        item.jamKe,
        if (isPimpinan) item.namaGuru,
        item.namaMapel,
        item.idKelas.split('-').first,
        materiDanCatatan,
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date), style: pw.TextStyle(font: boldFont, fontSize: 11)),
              if (isPimpinan && rekapAbsensi != null)
                pw.Text("Kehadiran: $rekapAbsensi", style: pw.TextStyle(font: font, fontSize: 9)),
            ],
          ),
        ),
        
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey500),
          headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: pw.TextStyle(font: font, fontSize: 8),
          cellAlignments: {
            0: pw.Alignment.center,
            if (isPimpinan) 3: pw.Alignment.center else 2: pw.Alignment.center,
          },
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            if (isPimpinan) 1: const pw.FlexColumnWidth(2.5),
            if (isPimpinan) 2: const pw.FlexColumnWidth(2.5) else 1: const pw.FlexColumnWidth(2.5),
            if (isPimpinan) 3: const pw.FlexColumnWidth(1) else 2: const pw.FlexColumnWidth(1),
            if (isPimpinan) 4: const pw.FlexColumnWidth(5) else 3: const pw.FlexColumnWidth(5),
          },
          headers: headers,
          data: data,
        ),
      ]
    );
  }

  // =======================================================================
  // FUNGSI BARU UNTUK LAPORAN ABSENSI
  // =======================================================================
  static Future<List<pw.Widget>> buildAbsensiReportContent({
    required List<AbsensiRekapModel> rekapDataHarian, // Ubah nama agar lebih jelas
    required Map<String, int> totalRekap,
    required List<SiswaAbsensiRekap> rekapPerSiswa, // [BARU] Terima data rekap per siswa
  }) async {
      final font = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();

      final totalSection = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Total Rekapitulasi", style: pw.TextStyle(font: boldFont, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildKpiItem("Hadir", totalRekap['hadir'] ?? 0, PdfColors.green, boldFont, font),
              _buildKpiItem("Sakit", totalRekap['sakit'] ?? 0, PdfColors.orange, boldFont, font),
              _buildKpiItem("Izin", totalRekap['izin'] ?? 0, PdfColors.blue, boldFont, font),
              _buildKpiItem("Alfa", totalRekap['alfa'] ?? 0, PdfColors.red, boldFont, font),
            ]
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
        ]
      );
      
      // [PEROMBAKAN TOTAL] Membuat tabel rekapitulasi per siswa
      final rekapSiswaSection = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 10),
          pw.Text("Rincian Ketidakhadiran per Siswa", style: pw.TextStyle(font: boldFont, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey500),
            headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: pw.TextStyle(font: font, fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center,
            },
            headers: ['Nama Siswa', 'Sakit', 'Izin', 'Alfa'],
            data: rekapPerSiswa.map((siswa) => [
              siswa.nama,
              siswa.sakit.toString(),
              siswa.izin.toString(),
              siswa.alfa.toString(),
            ]).toList(),
          ),
        ]
      );

      return [totalSection, rekapSiswaSection];
  }

  // Helper untuk buildAbsensiReportContent
  static pw.Widget _buildKpiItem(String label, int value, PdfColor color, pw.Font bold, pw.Font regular) {
      return pw.Column(
        children: [
          pw.Text(value.toString(), style: pw.TextStyle(font: bold, fontSize: 18, color: color)),
          pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 10, color: color)),
        ]
      );
  }

  // =======================================================================
  // FUNGSI BARU UNTUK LAPORAN HALAQAH
  // =======================================================================
  static Future<pw.Widget> buildHalaqahDashboardContent({
    required List<AgregatProgres> dataAgregat,
    required List<SiswaDashboardModel> siswaTanpaGrup,
    required List<SiswaDashboardModel> siswaProgresLambat,
    required List<SiswaDashboardModel> semuaSiswaDiFilter, // [BARU] Terima semua data siswa
  }) async {
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    final tables = <pw.Widget>[];

    // --- BAGIAN 1: TABEL DISTRIBUSI PROGRES (DETAIL) ---
    tables.add(pw.Text("Distribusi Progres Siswa", style: pw.TextStyle(font: boldFont, fontSize: 14)));
    tables.add(pw.SizedBox(height: 10));

    // Iterasi setiap tingkat progresi
    for (var agregat in dataAgregat) {
      // Filter siswa yang berada di tingkat progresi ini
      final siswaDiTingkatIni = semuaSiswaDiFilter
          .where((s) => "${s.progresTingkat} ${s.progresDetail}" == agregat.tingkat)
          .toList();

      // Buat tabel detail untuk tingkat ini
      tables.add(buildHalaqahPdfTable(
        title: "${agregat.tingkat} (${agregat.jumlahSiswa} Siswa)",
        headers: ['No', 'Nama Siswa', 'Kelas', 'Pengampu'],
        data: siswaDiTingkatIni.asMap().entries.map((e) => [
          (e.key + 1).toString(),
          e.value.nama,
          e.value.kelasId.split('-').first,
          e.value.namaPengampu,
        ]).toList(),
        font: font,
        boldFont: boldFont,
      ));
    }

    // --- BAGIAN 2 & 3: SISWA TANPA GRUP & PROGRES LAMBAT ---
    if (siswaTanpaGrup.isNotEmpty) {
      tables.add(buildHalaqahPdfTable(
        title: "Siswa Tanpa Grup (${siswaTanpaGrup.length} Siswa)",
        headers: ['No', 'Nama Siswa', 'Kelas'],
        data: siswaTanpaGrup.asMap().entries.map((e) => [(e.key + 1).toString(), e.value.nama, e.value.kelasId.split('-').first]).toList(),
        font: font, boldFont: boldFont,
      ));
    }
    
    if (siswaProgresLambat.isNotEmpty) {
       tables.add(buildHalaqahPdfTable(
        title: "Siswa Progres Lambat (${siswaProgresLambat.length} Siswa)",
        headers: ['No', 'Nama Siswa', 'Kelas', 'Pengampu', 'Setoran Terakhir'],
        data: siswaProgresLambat.asMap().entries.map((e) {
          final siswa = e.value;
          return [
            (e.key + 1).toString(),
            siswa.nama,
            siswa.kelasId.split('-').first,
            siswa.namaPengampu,
            siswa.tanggalSetoranTerakhir != null ? DateFormat('dd MMM yyyy').format(siswa.tanggalSetoranTerakhir!.toDate()) : 'N/A',
          ];
        }).toList(),
        font: font, boldFont: boldFont,
      ));
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: tables);
  }
  
  // Helper untuk buildHalaqahDashboardContent
  static pw.Widget buildHalaqahPdfTable({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
          cellStyle: pw.TextStyle(font: font, fontSize: 9),
        ),
      ],
    );
  }

  // =======================================================================
  // [FUNGSI BARU] UNTUK LAPORAN KEUANGAN SEKOLAH (BUKU BESAR)
  // =======================================================================
  static Future<List<pw.Widget>> buildLaporanKeuanganContent({
    required String tahunAnggaran,
    required Map<String, dynamic> summaryData,
    required List<Map<String, dynamic>> daftarTransaksi,
    required String filterInfo,
  }) async {
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final numberFormat = NumberFormat.decimalPattern('id_ID');

    final List<pw.Widget> widgets = [];

    // --- BAGIAN 1: RINGKASAN KEUANGAN ---
    widgets.add(pw.Text("Ringkasan Keuangan Tahun Anggaran $tahunAnggaran", style: pw.TextStyle(font: boldFont, fontSize: 14)));
    if (filterInfo.isNotEmpty) {
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4, bottom: 8),
        child: pw.Text("Filter Aktif: $filterInfo", style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
      ));
    }
    
    widgets.add(_buildFinancialKpiRow(
      label1: "Total Pemasukan", value1: numberFormat.format(summaryData['totalPemasukan'] ?? 0), color1: PdfColors.green,
      label2: "Total Pengeluaran", value2: numberFormat.format(summaryData['totalPengeluaran'] ?? 0), color2: PdfColors.red,
      boldFont: boldFont, regularFont: font
    ));
    widgets.add(_buildFinancialKpiRow(
      label1: "Saldo di Bank", value1: numberFormat.format(summaryData['saldoBank'] ?? 0), color1: PdfColors.orange,
      label2: "Saldo Kas Tunai", value2: numberFormat.format(summaryData['saldoKasTunai'] ?? 0), color2: PdfColors.blue,
      boldFont: boldFont, regularFont: font
    ));
    
    widgets.add(pw.Divider(height: 24));

    // --- BAGIAN 2: TABEL BUKU BESAR ---
    widgets.add(pw.Text("Rincian Transaksi (Buku Besar)", style: pw.TextStyle(font: boldFont, fontSize: 12)));
    widgets.add(pw.SizedBox(height: 8));
    
    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2.5), 3: const pw.FlexColumnWidth(2.5),
        4: const pw.FlexColumnWidth(2.5),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
          children: ['Tanggal', 'Keterangan', 'Kategori/Kas', 'Pemasukan', 'Pengeluaran'].map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(header, style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white), textAlign: pw.TextAlign.center),
            );
          }).toList(),
        ),
        // Data Rows
        ...daftarTransaksi.map((trx) {
          final jenis = trx['jenis'] ?? '';
          final jumlah = trx['jumlah'] ?? 0;
          String kategoriKas = '';
          if (jenis == 'Pemasukan' || jenis == 'Pengeluaran') {
            kategoriKas = trx['kategori'] ?? 'N/A';
          } else {
            kategoriKas = "Transfer";
          }
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(DateFormat('dd/MM/yy HH:mm').format((trx['tanggal'] as Timestamp).toDate()), style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(trx['keterangan'] ?? '', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(kategoriKas, style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(jenis == 'Pemasukan' ? numberFormat.format(jumlah) : '', style: pw.TextStyle(font: font, fontSize: 8), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(jenis == 'Pengeluaran' ? numberFormat.format(jumlah) : '', style: pw.TextStyle(font: font, fontSize: 8), textAlign: pw.TextAlign.right)),
            ]
          );
        }),
      ],
    ));

    return widgets;
  }
  
  static pw.Widget _buildFinancialKpiRow({
    required String label1, required String value1, required PdfColor color1,
    required String label2, required String value2, required PdfColor color2,
    required pw.Font boldFont, required pw.Font regularFont,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label1, style: pw.TextStyle(font: regularFont, fontSize: 9, color: color1)),
                pw.SizedBox(height: 2),
                pw.Text("Rp $value1", style: pw.TextStyle(font: boldFont, fontSize: 12)),
              ]
            )
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label2, style: pw.TextStyle(font: regularFont, fontSize: 9, color: color2)),
                pw.SizedBox(height: 2),
                pw.Text("Rp $value2", style: pw.TextStyle(font: boldFont, fontSize: 12)),
              ]
            )
          ),
        ]
      )
    );
  }
}