import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/pegawai_simple_model.dart';
import '../../../models/siswa_simple_model.dart';
import '../../../services/notifikasi_service.dart';
import '../../../services/pdf_helper_service.dart';


// -- MODEL HELPER --
class SiswaDashboardModel {
  final String uid;
  final String nama;
  final String kelasId;
  final Map<String, dynamic>? halaqahData;
  SiswaDashboardModel({required this.uid, required this.nama, required this.kelasId, this.halaqahData});
  bool get hasGroup => halaqahData != null && halaqahData!.containsKey('idGrup');
  String get namaPengampu => halaqahData?['namaPengampu'] ?? 'N/A';
  String get progresTingkat => halaqahData?['progres']?['tingkat'] ?? 'Belum';
  String get progresDetail => halaqahData?['progres']?['detailTingkat'] ?? 'Diatur';
  Timestamp? get tanggalSetoranTerakhir => halaqahData?['tanggalSetoranTerakhir'];
}
class AgregatProgres {
  final String tingkat;
  int jumlahSiswa = 0;
  AgregatProgres(this.tingkat);
}
// -- AKHIR MODEL HELPER --

class HalaqahUmmiDashboardKoordinatorController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isProcessingPdf = false.obs;
  final RxMap<String, dynamic> infoSekolah = <String, dynamic>{}.obs;

  // State Utama
  final RxBool isLoading = true.obs;
  final RxString selectedKelas = "Semua Kelas".obs;
  final RxList<String> daftarKelas = <String>["Semua Kelas"].obs;
  
  // State Data Hasil Analisis
  final RxList<SiswaDashboardModel> semuaSiswaDiFilter = <SiswaDashboardModel>[].obs;
  final RxList<SiswaDashboardModel> siswaTanpaGrup = <SiswaDashboardModel>[].obs;
  final RxList<SiswaDashboardModel> siswaProgresLambat = <SiswaDashboardModel>[].obs;
  final RxList<AgregatProgres> dataAgregat = <AgregatProgres>[].obs;

  final RxBool isLoadingPenguji = true.obs;
  final RxList<PegawaiSimpleModel> daftarPenguji = <PegawaiSimpleModel>[].obs;
  
  // State untuk form penjadwalan
  final Rxn<PegawaiSimpleModel> selectedPenguji = Rxn<PegawaiSimpleModel>();
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // [MODIFIKASI BAGIAN INI]
    await Future.wait([
      _fetchDaftarKelas(),
      _fetchDaftarPenguji(),
      _fetchInfoSekolah(), // Tambahkan pemanggilan ini
    ]);
    await fetchDataForDashboard(); // Muat data awal untuk "Semua Kelas"
  }

  Future<void> _fetchInfoSekolah() async {
    try {
      final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah).get();
      if (doc.exists) {
        infoSekolah.value = doc.data() ?? {};
      }
    } catch (e) {
      print("### Gagal mengambil info sekolah: $e");
      // Biarkan kosong jika gagal, header PDF akan menggunakan nilai default
    }
  }

  Future<void> _fetchDaftarKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').get();
    final kelasList = snapshot.docs.map((doc) => doc.id).toList()..sort();
    daftarKelas.addAll(kelasList);
  }

  Future<void> fetchDataForDashboard() async {
    isLoading.value = true;
    try {
      Query query = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa');

      if (selectedKelas.value != 'Semua Kelas') {
        query = query.where('kelasId', isGreaterThanOrEqualTo: selectedKelas.value)
                     .where('kelasId', isLessThan: '${selectedKelas.value}\uf8ff');
      }

      final snapshot = await query.get();

      // --- PERBAIKAN DIMULAI DI SINI ---
      semuaSiswaDiFilter.assignAll(snapshot.docs.map((doc) {
        // Gunakan 'as Map<String, dynamic>?' yang aman, lalu beri nilai default jika null
        final data = doc.data() as Map<String, dynamic>? ?? {}; 

        return SiswaDashboardModel(
          uid: doc.id,
          nama: data['namaLengkap'] ?? 'Tanpa Nama',
          kelasId: data['kelasId'] ?? 'N/A',
          halaqahData: data['halaqahUmmi'] as Map<String, dynamic>?,
        );
      }).toList());
      // --- AKHIR PERBAIKAN ---

      _analyzeData(); // Panggil fungsi analisis

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data dashboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _analyzeData() {
    // 1. Analisis Siswa Tanpa Grup
    siswaTanpaGrup.assignAll(semuaSiswaDiFilter.where((s) => !s.hasGroup).toList());

    // 2. Analisis Progres Lambat
    final DateTime limitWaktu = DateTime.now().subtract(const Duration(days: 7));
    siswaProgresLambat.assignAll(semuaSiswaDiFilter.where((s) {
      if (!s.hasGroup || s.tanggalSetoranTerakhir == null) return false;
      return s.tanggalSetoranTerakhir!.toDate().isBefore(limitWaktu);
    }).toList());

    // 3. Analisis Agregat Progres
    final Map<String, AgregatProgres> agregatMap = {};
    for (var siswa in semuaSiswaDiFilter) {
      if (siswa.hasGroup) {
        final tingkatKey = "${siswa.progresTingkat} ${siswa.progresDetail}";
        if (agregatMap.containsKey(tingkatKey)) {
          agregatMap[tingkatKey]!.jumlahSiswa++;
        } else {
          agregatMap[tingkatKey] = AgregatProgres(tingkatKey)..jumlahSiswa = 1;
        }
      }
    }
    dataAgregat.assignAll(agregatMap.values.toList()..sort((a,b) => a.tingkat.compareTo(b.tingkat)));
  }

  void onKelasFilterChanged(String? newValue) {
    if (newValue != null) {
      selectedKelas.value = newValue;
      fetchDataForDashboard();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSiswaDiajukan() {
    return _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa')
        .where('halaqahUmmi.statusUjian', isEqualTo: 'Diajukan')
        .snapshots();
  }

  Future<void> _fetchDaftarPenguji() async {
    isLoadingPenguji.value = true;
    try {
      final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('halaqah_ummi_config').get();

      if (doc.exists) {
        final Map<String, dynamic> pengujiMap = doc.data()?['daftarPenguji'] ?? {};
        final List<PegawaiSimpleModel> tempList = [];
        pengujiMap.forEach((uid, nama) {
          tempList.add(PegawaiSimpleModel(uid: uid, nama: nama, alias: ''));
        });
        daftarPenguji.assignAll(tempList);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar penguji: $e");
    } finally {
      isLoadingPenguji.value = false;
    }
  }

  void openSchedulingSheet(SiswaSimpleModel siswa) {
    selectedPenguji.value = null;
    selectedDate.value = DateTime.now();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        child: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Atur Jadwal: ${siswa.nama}", style: Get.textTheme.titleLarge),
            const SizedBox(height: 20),
            DropdownButtonFormField<PegawaiSimpleModel>(
              value: selectedPenguji.value,
              items: daftarPenguji.map((p) => DropdownMenuItem(value: p, child: Text(p.nama))).toList(),
              onChanged: (val) => selectedPenguji.value = val,
              decoration: const InputDecoration(labelText: 'Pilih Penguji', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Tanggal Ujian"),
              subtitle: Text(DateFormat('dd MMMM yyyy').format(selectedDate.value)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedPenguji.value == null ? null : () => _saveSchedule(siswa),
              child: const Text("Jadwalkan Ujian"),
            )
          ],
        )),
      ),
      backgroundColor: Colors.white,
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: Get.context!, initialDate: selectedDate.value,
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) selectedDate.value = picked;
  }

  Future<void> _saveSchedule(SiswaSimpleModel siswa) async {
    if (selectedPenguji.value == null) {
      Get.snackbar("Peringatan", "Penguji belum dipilih.");
      return;
    }

    try {
      final batch = _firestore.batch();
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
      final munaqosyahRef = siswaRef.collection('halaqah_munaqosyah').doc();

      final materiUjianOtomatis = await _getMateriUjianOtomatis(siswa.uid);

      // 1. Buat dokumen ujian baru
      batch.set(munaqosyahRef, {
        'idSekolah': configC.idSekolah, // <-- TAMBAHAN KRUSIAL
        'tanggalUjian': Timestamp.fromDate(selectedDate.value),
        'materiUjian': materiUjianOtomatis,
        'idPenguji': selectedPenguji.value!.uid,
        'namaPenguji': selectedPenguji.value!.nama,
        'hasil': 'Dijadwalkan',
        'nilai': 0, 'catatanPenguji': '',
      });

      // 2. Update status siswa
      batch.update(siswaRef, {'halaqahUmmi.statusUjian': 'Dijadwalkan'});

      await batch.commit();

      // --- TAMBAHAN BARU: KIRIM NOTIFIKASI ---
      await NotifikasiService.kirimNotifikasi(
        uidPenerima: siswa.uid,
        judul: "Jadwal Munaqosyah (Ujian) Halaqah",
        isi: "Ananda ${siswa.nama} dijadwalkan untuk Munaqosyah pada ${DateFormat('dd MMMM yyyy').format(selectedDate.value)} dengan penguji ${selectedPenguji.value!.nama}.",
        tipe: "HALAQAH_UMMI",
      );
      // --- AKHIR TAMBAHAN ---

      Get.back(); // Tutup bottom sheet
      Get.snackbar("Berhasil", "Ujian untuk ${siswa.nama} telah dijadwalkan.");

    } catch (e) {
      Get.snackbar("Error", "Gagal menjadwalkan: $e");
    }
  }

  Future<String> _getMateriUjianOtomatis(String siswaUid) async {
    final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswaUid).get();
    final progres = doc.data()?['halaqahUmmi']?['progres'];
    if (progres != null) {
      final tingkat = progres['tingkat'] ?? 'Jilid';
      final detail = progres['detailTingkat'] ?? '1';
      // Logika sederhana untuk menentukan materi ujian
      if (tingkat == 'Jilid') {
        int jilidBerikutnya = (int.tryParse(detail) ?? 1) + 1;
        if (jilidBerikutnya > 6) {
          return "Ujian Kenaikan ke Al-Qur'an";
        }
        return "Ujian Kenaikan ke Jilid $jilidBerikutnya";
      }
      return "Ujian Kenaikan Tingkat $tingkat";
    }
    return "Ujian Kenaikan Tingkat";
  }

  Future<void> exportPdf() async {
    if (semuaSiswaDiFilter.isEmpty) {
      Get.snackbar("Tidak Ada Data", "Tidak ada data siswa untuk diekspor pada filter ini.");
      return;
    }
    isProcessingPdf.value = true;
    try {
      final doc = pw.Document();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final logoImage = pw.MemoryImage((await rootBundle.load('assets/png/logo.png')).buffer.asUint8List());
      
      final infoSekolah = this.infoSekolah.value;

      // [PERBAIKAN] Kirim 'semuaSiswaDiFilter' ke dalam service
      final content = await PdfHelperService.buildHalaqahDashboardContent(
        dataAgregat: dataAgregat,
        siswaTanpaGrup: siswaTanpaGrup,
        siswaProgresLambat: siswaProgresLambat,
        semuaSiswaDiFilter: semuaSiswaDiFilter, // <-- Tambahan penting
      );

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => PdfHelperService.buildHeaderA4(infoSekolah: infoSekolah, logoImage: logoImage, boldFont: boldFont),
          footer: (context) => PdfHelperService.buildFooter(context),
          build: (context) => [
            pw.SizedBox(height: 20),
            pw.Text("Laporan Dashboard Halaqah Ummi", style: pw.TextStyle(font: boldFont, fontSize: 14), textAlign: pw.TextAlign.center),
            pw.Text("Filter Kelas: ${selectedKelas.value}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 20),
            content, // Konten yang sudah sangat informatif
          ],
        ),
      );
      
      final String fileName = 'laporan_halaqah_ummi_${selectedKelas.value.replaceAll(' ', '_')}.pdf';
      await Printing.sharePdf(bytes: await doc.save(), filename: fileName);

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
              pw.Text("Laporan Dashboard Halaqah Ummi", style: const pw.TextStyle(fontSize: 14)),
            ]),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("Filter Kelas: ${selectedKelas.value}", style: const pw.TextStyle(fontSize: 10)),
            pw.Text("T.A: ${configC.tahunAjaranAktif.value}", style: const pw.TextStyle(fontSize: 10)),
            pw.Text("Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10)),
          ]),
        ],
      ),
      pw.Divider(height: 20),
    ]);
  }
  
  pw.Widget _buildPdfRingkasan(pw.Font boldFont, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Ringkasan Data", style: pw.TextStyle(font: boldFont, fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(children: [
              pw.Text(semuaSiswaDiFilter.length.toString(), style: pw.TextStyle(font: boldFont, fontSize: 18)),
              pw.Text("Total Siswa", style: pw.TextStyle(font: font, fontSize: 10)),
            ]),
            pw.Column(children: [
              pw.Text(siswaTanpaGrup.length.toString(), style: pw.TextStyle(font: boldFont, fontSize: 18)),
              pw.Text("Tanpa Grup", style: pw.TextStyle(font: font, fontSize: 10)),
            ]),
            pw.Column(children: [
              pw.Text(siswaProgresLambat.length.toString(), style: pw.TextStyle(font: boldFont, fontSize: 18)),
              pw.Text("Progres Lambat", style: pw.TextStyle(font: font, fontSize: 10)),
            ]),
          ]
        ),
        pw.SizedBox(height: 16),
        pw.Text("Distribusi Progres", style: pw.TextStyle(font: boldFont, fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Column(
          children: dataAgregat.map((agregat) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(agregat.tingkat, style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text(agregat.jumlahSiswa.toString(), style: pw.TextStyle(font: boldFont, fontSize: 10)),
            ]
          )).toList()
        ),
      ]
    );
  }
  
    pw.Widget _buildPdfTable(String title, List<String> headers, List<SiswaDashboardModel> dataList, pw.Font font, pw.Font boldFont) {
    if (dataList.isEmpty) return pw.Container();
    
    // Buat data baris untuk tabel
    final data = dataList.asMap().entries.map((entry) {
      int index = entry.key;
      SiswaDashboardModel siswa = entry.value;
  
      // Buat baris sesuai dengan header yang diminta
      final List<String> row = [
        (index + 1).toString(),
        siswa.nama,
        siswa.kelasId.split('-').first,
      ];
  
      if (headers.contains('Pengampu')) {
        row.add(siswa.namaPengampu);
      }
      if (headers.contains('Setoran Terakhir')) {
        row.add(siswa.tanggalSetoranTerakhir != null
            ? DateFormat('dd MMM yyyy').format(siswa.tanggalSetoranTerakhir!.toDate())
            : 'N/A');
      }
      return row;
    }).toList();
  
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
          cellStyle: pw.TextStyle(font: font, fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.center,
            2: pw.Alignment.center,
          },
        ),
      ],
    );
  }
}