// lib/app/modules/laporan_keuangan_sekolah/controllers/laporan_keuangan_sekolah_controller.dart

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Dibutuhkan untuk rootBundle
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Dibutuhkan untuk MemoryImage
import 'package:printing/printing.dart';
import '../../../controllers/config_controller.dart';
import '../../../services/pdf_helper_service.dart';
import '../../../widgets/number_input_formatter.dart';

class LaporanKeuanganSekolahController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // --- State untuk PDF ---
  final isExporting = false.obs;

  // --- State UI & Data ---
  final isLoading = true.obs;
  final RxList<String> daftarTahunAnggaran = <String>[].obs;
  final Rxn<String> tahunTerpilih = Rxn<String>();

  // --- State Real-time ---
  final RxMap<String, dynamic> summaryData = <String, dynamic>{}.obs;
  // [MODIFIKASI 1] Ganti nama untuk menampung data mentah
  final RxList<Map<String, dynamic>> _semuaTransaksiTahunIni = <Map<String, dynamic>>[].obs;
  StreamSubscription? _summarySub;
  StreamSubscription? _transaksiSub;

  // --- State Form & Kategori ---
  final isSaving = false.obs;
  final isUploading = false.obs;
  final RxList<String> daftarKategoriPengeluaran = <String>[].obs;
  final Rxn<File> buktiTransaksiFile = Rxn<File>();

  // --- [BARU] State untuk Filter ---
  final Rxn<DateTime> filterBulanTahun = Rxn<DateTime>();
  final Rxn<String> filterJenis = Rxn<String>();
  final Rxn<String> filterKategori = Rxn<String>();

  // --- [MODIFIKASI 2] Computed property untuk menampilkan data hasil filter ---
  Rx<List<Map<String, dynamic>>> get daftarTransaksiTampil => Rx(_semuaTransaksiTahunIni.where((trx) {
      final tgl = (trx['tanggal'] as Timestamp).toDate();
      final jenis = trx['jenis'] as String;
      final kategori = trx['kategori'] as String?;

      final bool matchBulan = filterBulanTahun.value == null || (tgl.year == filterBulanTahun.value!.year && tgl.month == filterBulanTahun.value!.month);
      final bool matchJenis = filterJenis.value == null || jenis == filterJenis.value;
      final bool matchKategori = filterKategori.value == null || kategori == filterKategori.value;
      
      return matchBulan && matchJenis && matchKategori;
    }).toList());
  
  // [BARU] Helper untuk mengetahui jika ada filter aktif
  bool get isFilterActive => filterBulanTahun.value != null || filterJenis.value != null || filterKategori.value != null;

  @override
  void onInit() {
    super.onInit();
    _fetchDaftarTahun();
    _fetchKategoriPengeluaran();
  }
  

  Future<void> _fetchDaftarTahun() async {
    isLoading.value = true;
    try {
      final snap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunAnggaran').get();
      
      final listTahun = snap.docs.map((doc) => doc.id).toList();
      listTahun.sort((a, b) => b.compareTo(a));
      daftarTahunAnggaran.assignAll(listTahun);

      if (daftarTahunAnggaran.isNotEmpty) {
        pilihTahun(daftarTahunAnggaran.first);
      } else {
         // [BARU] Jika tidak ada data, buat tahun anggaran saat ini
        final tahunIni = DateTime.now().year.toString();
        daftarTahunAnggaran.add(tahunIni);
        pilihTahun(tahunIni);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar tahun anggaran: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pilihTahun(String tahun) async {
    if (tahunTerpilih.value == tahun && _summarySub != null) return;
    isLoading.value = true;
    tahunTerpilih.value = tahun;
    summaryData.clear();
    _semuaTransaksiTahunIni.clear(); // [MODIFIKASI 3] Clear list mentah
    resetFilter(closeDialog: false); // Reset filter saat ganti tahun

    await _summarySub?.cancel();
    await _transaksiSub?.cancel();

    final tahunRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunAnggaran').doc(tahun);

    _summarySub = tahunRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        summaryData.value = snapshot.data() ?? {};
      }
    }, onError: (e) => Get.snackbar("Error", "Gagal memuat ringkasan: $e"));

    _transaksiSub = tahunRef.collection('transaksi')
        .orderBy('tanggal', descending: true)
        .snapshots().listen((snapshot) {
      final listTransaksi = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _semuaTransaksiTahunIni.assignAll(listTransaksi); // [MODIFIKASI 4] Isi list mentah
      isLoading.value = false;
    }, onError: (e) {
      Get.snackbar("Error", "Gagal memuat transaksi: $e");
      isLoading.value = false;
    });
  }

  void showFilterDialog() {
    // Simpan state sementara di dalam dialog
    final tempBulan = filterBulanTahun.value.obs;
    final tempJenis = filterJenis.value.obs;
    final tempKategori = filterKategori.value.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filter Laporan", style: Get.textTheme.titleLarge),
              const Divider(),
              _buildBulanPicker(tempBulan),
              const SizedBox(height: 16),
              _buildJenisPicker(tempJenis),
              const SizedBox(height: 16),
              Obx(() => Visibility(
                visible: tempJenis.value == 'Pengeluaran',
                child: _buildKategoriPicker(tempKategori),
              )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => resetFilter(),
                      child: const Text("Reset Filter"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _terapkanFilter(tempBulan.value, tempJenis.value, tempKategori.value),
                      child: const Text("Terapkan"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildBulanPicker(Rx<DateTime?> tempBulan) {
    // Buat daftar bulan dari awal tahun sampai bulan ini
    List<DateTime> daftarBulan = [];
    final now = DateTime.now();
    for (int i = 1; i <= now.month; i++) {
      daftarBulan.add(DateTime(now.year, i));
    }

    return Obx(() => DropdownButtonFormField<DateTime>(
      value: tempBulan.value,
      hint: const Text("Filter Berdasarkan Bulan"),
      items: daftarBulan.map((bulan) {
        return DropdownMenuItem(value: bulan, child: Text(DateFormat.yMMMM('id_ID').format(bulan)));
      }).toList(),
      onChanged: (value) => tempBulan.value = value,
    ));
  }

  Widget _buildJenisPicker(Rx<String?> tempJenis) {
    return Obx(() => DropdownButtonFormField<String>(
      value: tempJenis.value,
      hint: const Text("Filter Jenis Transaksi"),
      items: ['Pemasukan', 'Pengeluaran', 'Transfer'].map((jenis) {
        return DropdownMenuItem(value: jenis, child: Text(jenis));
      }).toList(),
      onChanged: (value) => tempJenis.value = value,
    ));
  }

  Widget _buildKategoriPicker(Rx<String?> tempKategori) {
    return Obx(() => DropdownButtonFormField<String>(
      value: tempKategori.value,
      hint: const Text("Filter Kategori Pengeluaran"),
      items: daftarKategoriPengeluaran.map((k) {
        return DropdownMenuItem(value: k, child: Text(k));
      }).toList(),
      onChanged: (value) => tempKategori.value = value,
    ));
  }

  void _terapkanFilter(DateTime? bulan, String? jenis, String? kategori) {
    filterBulanTahun.value = bulan;
    filterJenis.value = jenis;
    // Hanya set filter kategori jika jenisnya adalah Pengeluaran
    filterKategori.value = (jenis == 'Pengeluaran') ? kategori : null;
    Get.back();
  }

  void resetFilter({bool closeDialog = true}) {
    filterBulanTahun.value = null;
    filterJenis.value = null;
    filterKategori.value = null;
    if (closeDialog) Get.back();
  }

  Future<void> _fetchKategoriPengeluaran() async {
    try {
      final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('konfigurasi_keuangan');
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final kategoriFromDb = (data['daftarKategoriPengeluaran'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        daftarKategoriPengeluaran.assignAll(kategoriFromDb);
      }
    } catch (e) {
      print("### Gagal memuat kategori: $e");
    }
  }

  void showPilihanTransaksiDialog() {
    if (tahunTerpilih.value == null) {
      Get.snackbar("Peringatan", "Silakan pilih tahun anggaran terlebih dahulu.");
      return;
    }
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_downward_rounded, color: Colors.green),
              title: const Text("Catat Pemasukan Lain"),
              onTap: () {
                Get.back();
                _showFormDialog(jenis: 'Pemasukan');
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward_rounded, color: Colors.red),
              title: const Text("Catat Pengeluaran"),
              onTap: () {
                Get.back();
                _showFormDialog(jenis: 'Pengeluaran');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: Colors.blue),
              title: const Text("Catat Transfer Antar Kas"),
              onTap: () {
                Get.back();
                _showFormDialog(jenis: 'Transfer');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pilihDanKompresGambar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    isUploading.value = true;
    try {
      File fileToCompress = File(pickedFile.path);
      int currentQuality = 85;
      const targetSizeInBytes = 50 * 1024; // 50 KB

      // [PERBAIKAN KUNCI] Loop kompresi dengan kondisi yang lebih baik
      while (await fileToCompress.length() > targetSizeInBytes && currentQuality >= 5) { // Gunakan >=
        final targetPath = "${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

        final result = await FlutterImageCompress.compressAndGetFile(
          fileToCompress.path,
          targetPath,
          quality: currentQuality,
          minWidth: 800,
          minHeight: 800,
        );

        if (result != null) {
          // Hapus file sementara sebelumnya untuk menghemat ruang
          if (fileToCompress.path != pickedFile.path) {
            await fileToCompress.delete();
          }
          fileToCompress = File(result.path);
          print("### Kompresi dengan kualitas $currentQuality. Ukuran baru: ${await fileToCompress.length()} bytes");
        }

        currentQuality -= 10;
      }

      buktiTransaksiFile.value = fileToCompress;
      print("### Kompresi FINAL selesai. Ukuran akhir: ${await fileToCompress.length()} bytes");

    } catch (e) {
      Get.snackbar("Error", "Gagal mengompres gambar: $e");
      buktiTransaksiFile.value = null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<String?> _uploadBuktiKeSupabase(File file) async {
    // INI ADALAH TEMPAT ANDA MENGINTEGRASIKAN LOGIKA UPLOAD KE SUPABASE
    // Ganti kode di bawah ini dengan Supabase Client Anda
    isUploading.value = true;
    try {
      // CONTOH:
      // final path = '/bukti-transaksi/${DateTime.now().millisecondsSinceEpoch}.jpg';
      // await supabase.storage.from('nama-bucket-anda').upload(path, file);
      // final url = supabase.storage.from('nama-bucket-anda').getPublicUrl(path);
      // return url;

      // Untuk sekarang, kita simulasikan proses upload
      await Future.delayed(const Duration(seconds: 2));
      print("### Simulasi Upload Berhasil");
      return "https://simulasi.url/bukti/kwitansi.jpg";

    } catch (e) {
      Get.snackbar("Error Upload", "Gagal mengunggah bukti: $e");
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  void _showFormDialog({required String jenis}) {
    final formKey = GlobalKey<FormState>();
    final jumlahC = TextEditingController();
    final keteranganC = TextEditingController();
    final RxnString kategoriTerpilih = RxnString();
    final RxnString sumberDana = RxnString('Kas Tunai');
    final RxnString dariKas = RxnString('Bank');
    final RxnString keKas = RxnString('Kas Tunai');

    buktiTransaksiFile.value = null;

    Get.dialog(
      AlertDialog(
        title: Text("Catat $jenis"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (jenis != 'Transfer') ...[
                    TextFormField(
                      controller: jumlahC,
                      keyboardType: TextInputType.number,
                      // [PERBAIKAN 1] Gunakan formatter custom Anda
                      inputFormatters: [NumberInputFormatter()], 
                      decoration: const InputDecoration(labelText: "Jumlah", prefixText: "Rp "),
                      validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    if (jenis == 'Pengeluaran')
                      Obx(() => DropdownButtonFormField<String>(
                        value: kategoriTerpilih.value,
                        hint: const Text("Pilih Kategori"),
                        items: daftarKategoriPengeluaran.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                        onChanged: (v) => kategoriTerpilih.value = v,
                        validator: (v) => v == null ? "Wajib pilih kategori" : null,
                      )),
                    if (jenis == 'Pengeluaran') const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: sumberDana.value,
                      items: ['Kas Tunai', 'Bank'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => sumberDana.value = v,
                      decoration: InputDecoration(labelText: jenis == 'Pemasukan' ? 'Masuk Ke Kas' : 'Diambil Dari Kas'),
                       validator: (v) => v == null ? "Wajib dipilih" : null,
                    ),
                  ] else ...[
                     TextFormField(
                      controller: jumlahC,
                      keyboardType: TextInputType.number,
                      // [PERBAIKAN 1] Gunakan formatter custom Anda
                      inputFormatters: [NumberInputFormatter()],
                      decoration: const InputDecoration(labelText: "Jumlah Transfer", prefixText: "Rp "),
                      validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                     DropdownButtonFormField<String>(
                      value: dariKas.value,
                      items: ['Bank', 'Kas Tunai'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => dariKas.value = v,
                      decoration: const InputDecoration(labelText: 'Dari Kas'),
                       validator: (v) => v == null ? "Wajib dipilih" : null,
                    ),
                    const SizedBox(height: 16),
                     DropdownButtonFormField<String>(
                      value: keKas.value,
                      items: ['Bank', 'Kas Tunai'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => keKas.value = v,
                      decoration: const InputDecoration(labelText: 'Ke Kas'),
                       validator: (v) => v == null ? "Wajib dipilih" : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: keteranganC,
                    decoration: const InputDecoration(labelText: "Keterangan"),
                    validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                  ),
                  if (jenis == 'Pengeluaran') ...[
                    const SizedBox(height: 16),
                    Obx(() => buktiTransaksiFile.value == null
                        ? OutlinedButton.icon(
                            onPressed: _pilihDanKompresGambar,
                            icon: isUploading.value ? const SizedBox(width:16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.attach_file),
                            label: Text(isUploading.value ? "Memproses..." : "Unggah Bukti (Struk/Nota)"),
                          )
                        : ListTile(
                            leading: Image.file(buktiTransaksiFile.value!, width: 40, height: 40, fit: BoxFit.cover),
                            title: const Text("Bukti Terlampir", style: TextStyle(fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => buktiTransaksiFile.value = null,
                            ),
                          )
                    )
                  ],
                ],
              ),
            ),
          ),
          actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          Obx(() => ElevatedButton(
            onPressed: isSaving.value ? null : () {
              // [MODIFIKASI KUNCI] Panggil fungsi konfirmasi
              _konfirmasiSebelumSimpan(
                formKey: formKey,
                jenis: jenis,
                jumlahC: jumlahC,
                keteranganC: keteranganC,
                kategori: kategoriTerpilih.value,
                sumberDana: sumberDana.value,
                dariKas: dariKas.value,
                keKas: keKas.value,
              );
            },
            child: Text("Simpan"),
          )),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _konfirmasiSebelumSimpan({
    required GlobalKey<FormState> formKey,
    required String jenis,
    required TextEditingController jumlahC,
    required TextEditingController keteranganC,
    String? kategori,
    String? sumberDana,
    String? dariKas,
    String? keKas,
  }) {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (jenis == 'Transfer' && dariKas == keKas) {
      Get.snackbar("Peringatan", "Kas sumber dan tujuan tidak boleh sama.");
      return;
    }

    final jumlah = jumlahC.text;

    Get.defaultDialog(
      title: "Konfirmasi Data",
      middleText: "Anda akan menyimpan transaksi $jenis sebesar Rp $jumlah. Data yang sudah disimpan tidak dapat diubah atau dihapus. Lanjutkan?",
      confirm: Obx(() => ElevatedButton(
        onPressed: isSaving.value ? null : () async {
          isSaving.value = true;
          Get.back(); // Tutup dialog konfirmasi

          String? urlBukti;
          if (jenis == 'Pengeluaran' && buktiTransaksiFile.value != null) {
            urlBukti = await _uploadBuktiKeSupabase(buktiTransaksiFile.value!);
          }

          final data = {
            'jumlah': int.tryParse(jumlah.replaceAll('.', '')) ?? 0,
            'keterangan': keteranganC.text,
            'kategori': kategori,
            'sumberDana': sumberDana,
            'dariKas': dariKas,
            'keKas': keKas,
            'urlBukti': urlBukti,
          };

          await _simpanTransaksi(jenis, data);
        },
        child: Text(isSaving.value ? "MEMPROSES..." : "Ya, Lanjutkan"),
      )),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  Future<void> _simpanTransaksi(String jenis, Map<String, dynamic> data) async {
    final int jumlah = data['jumlah'];
  
    final tahunRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunAnggaran').doc(tahunTerpilih.value!);
  
    try {
      await _firestore.runTransaction((transaction) async {
        final pencatatUid = configC.infoUser['uid'];
        final pencatatNama = configC.infoUser['nama'] ?? 'User';
        
        // [MODIFIKASI KUNCI] Buat satu timestamp bersama untuk semua operasi
        final sharedTimestamp = Timestamp.now();
  
        if (jenis == 'Pemasukan' || jenis == 'Pengeluaran') {
          final Map<String, dynamic> dataTransaksi = {
            'tanggal': sharedTimestamp,
            'jenis': jenis,
            'jumlah': jumlah,
            'keterangan': data['keterangan'],
            'sumberDana': data['sumberDana'],
            'kategori': (jenis == 'Pemasukan') ? 'Pemasukan Lain-Lain' : data['kategori'],
            'urlBuktiTransaksi': (jenis == 'Pengeluaran') ? data['urlBukti'] : null,
            'diinputOleh': pencatatUid,
            'diinputOlehNama': pencatatNama,
          };
  
          final Map<String, dynamic> dataSummaryUpdate = {
            (jenis == 'Pemasukan' ? 'totalPemasukan' : 'totalPengeluaran'): FieldValue.increment(jumlah),
            'saldoAkhir': FieldValue.increment(jenis == 'Pemasukan' ? jumlah : -jumlah),
            (data['sumberDana'] == 'Bank' ? 'saldoBank' : 'saldoKasTunai'): FieldValue.increment(jenis == 'Pemasukan' ? jumlah : -jumlah),
          };
  
          transaction.set(tahunRef.collection('transaksi').doc(), dataTransaksi);
          transaction.set(tahunRef, dataSummaryUpdate, SetOptions(merge: true));
  
        } else { // [MODIFIKASI KUNCI] Logika baru untuk 'Transfer' (Double-Entry)
          
          final transferId = tahunRef.collection('transaksi').doc().id; // Gunakan ID doc sebagai ID transfer
  
          // 1. Buat Dokumen Pengeluaran (Transfer Keluar)
          final dataPengeluaran = {
            'tanggal': sharedTimestamp,
            'jenis': 'Pengeluaran',
            'jumlah': jumlah,
            'keterangan': data['keterangan'],
            'sumberDana': data['dariKas'],
            'kategori': 'Transfer Keluar', // Kategori sistem
            'diinputOleh': pencatatUid,
            'diinputOlehNama': pencatatNama,
            'transferId': transferId, // Tautan
          };
          transaction.set(tahunRef.collection('transaksi').doc(), dataPengeluaran);
  
          // 2. Buat Dokumen Pemasukan (Transfer Masuk)
          final dataPemasukan = {
            'tanggal': sharedTimestamp,
            'jenis': 'Pemasukan',
            'jumlah': jumlah,
            'keterangan': data['keterangan'],
            'sumberDana': data['keKas'],
            'kategori': 'Transfer Masuk', // Kategori sistem
            'diinputOleh': pencatatUid,
            'diinputOlehNama': pencatatNama,
            'transferId': transferId, // Tautan
          };
          transaction.set(tahunRef.collection('transaksi').doc(), dataPemasukan);
  
          // 3. Update Saldo Kas & Bank, sementara Saldo Akhir tetap
          final Map<String, dynamic> dataSummaryUpdate = {
            (data['dariKas'] == 'Bank' ? 'saldoBank' : 'saldoKasTunai'): FieldValue.increment(-jumlah),
            (data['keKas'] == 'Bank' ? 'saldoBank' : 'saldoKasTunai'): FieldValue.increment(jumlah),
          };
          transaction.set(tahunRef, dataSummaryUpdate, SetOptions(merge: true));
        }
      });
      
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "$jenis berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);
  
    } catch(e) {
      Get.snackbar("Error", "Gagal menyimpan transaksi: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    _summarySub?.cancel();
    _transaksiSub?.cancel();
    super.onClose();
  }

  String formatRupiah(dynamic amount) {
    final number = (amount as num?)?.toInt() ?? 0;
    return "Rp ${NumberFormat.decimalPattern('id_ID').format(number)}";
  }

  // --- [BARU] FUNGSI UNTUK FASE 5 ---
  Future<void> exportToPdf() async {
    if (isExporting.value) return;
    isExporting.value = true;
    
    // PENANDA VERSI KODE
    print("### MENJALANKAN KODE PDF VERSI FINAL V2 ###"); 
  
    try {
      // --- LANGKAH 1: KUMPULKAN SEMUA ASET & DATA ASYNCHRONOUS ---
      
      final infoSekolah = await _firestore.collection('Sekolah').doc(configC.idSekolah).get().then((d) {
        final data = d.data();
        if (data == null) return <String, dynamic>{};
        return Map<String, dynamic>.from(data);
      });
      
      final logoBytes = await rootBundle.load('assets/png/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final regularFont = await PdfGoogleFonts.poppinsRegular();
  
      String filterInfoText = "";
      if (isFilterActive) {
        List<String> filters = [];
        if (filterBulanTahun.value != null) filters.add(DateFormat.yMMMM('id_ID').format(filterBulanTahun.value!));
        if (filterJenis.value != null) filters.add(filterJenis.value!);
        if (filterKategori.value != null) filters.add(filterKategori.value!);
        filterInfoText = filters.join(" | ");
      }
      
      final List<pw.Widget> contentWidgets = await PdfHelperService.buildLaporanKeuanganContent(
        tahunAnggaran: tahunTerpilih.value!,
        summaryData: summaryData,
        daftarTransaksi: daftarTransaksiTampil.value,
        filterInfo: filterInfoText,
      );
      
      // --- LANGKAH 2: RAKIT DOKUMEN PDF ---
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => PdfHelperService.buildHeaderA4(
            infoSekolah: infoSekolah,
            logoImage: logoImage,
            boldFont: boldFont,
            regularFont: regularFont,
          ),
          footer: (context) => PdfHelperService.buildFooter(context, regularFont),
          build: (context) => contentWidgets,
        ),
      );
  
      // --- LANGKAH 3: SIMPAN DAN BAGIKAN PDF ---
      final String fileName = 'laporan_keuangan_${tahunTerpilih.value}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat file PDF: ${e.toString()}");
      print("### PDF EXPORT ERROR: $e");
    } finally {
      isExporting.value = false;
    }
  }
}