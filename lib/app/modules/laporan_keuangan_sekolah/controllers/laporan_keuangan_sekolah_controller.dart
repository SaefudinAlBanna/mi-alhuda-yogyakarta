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
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../controllers/config_controller.dart';
import '../../../services/pdf_helper_service.dart';
import '../../../widgets/number_input_formatter.dart';

class LaporanKeuanganSekolahController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late TabController tabController; 

  // --- State untuk Anggaran ---
  final RxMap<String, int> dataAnggaran = <String, int>{}.obs;
  StreamSubscription? _budgetSub;



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

  // [BARU] Computed property untuk menggabungkan anggaran dan realisasi
  RxList<Map<String, dynamic>> get analisisAnggaran {
    final List<Map<String, dynamic>> result = [];
    
    // Hitung realisasi dari semua transaksi
    final Map<String, double> realisasi = {};
    for (var trx in _semuaTransaksiTahunIni) {
      if (trx['jenis'] == 'Pengeluaran' && trx['kategori'] != 'Transfer Keluar') {
        final kategori = trx['kategori'] as String;
        final jumlah = (trx['jumlah'] as num).toDouble();
        realisasi[kategori] = (realisasi[kategori] ?? 0.0) + jumlah;
      }
    }
    
    // Gabungkan dengan data anggaran
    dataAnggaran.forEach((kategori, anggaran) {
      result.add({
        'kategori': kategori,
        'anggaran': anggaran,
        'realisasi': realisasi[kategori] ?? 0.0,
      });
    });
    
    // Urutkan berdasarkan sisa anggaran paling sedikit
    result.sort((a, b) {
      final sisaA = (a['anggaran'] as int) - (a['realisasi'] as double);
      final sisaB = (b['anggaran'] as int) - (b['realisasi'] as double);
      return sisaA.compareTo(sisaB);
    });

    return result.obs;
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this); 
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
    _semuaTransaksiTahunIni.clear();
    dataAnggaran.clear(); // [BARU] Hapus data anggaran lama
    resetFilter(closeDialog: false);

    await _summarySub?.cancel();
    await _transaksiSub?.cancel();
    await _budgetSub?.cancel(); // [BARU] Batalkan listener anggaran lama

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
    
    _budgetSub = tahunRef.collection('anggaran').doc('data_anggaran').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final budgets = snapshot.data()!['anggaranPengeluaran'] as Map<String, dynamic>? ?? {};
        dataAnggaran.value = budgets.map((key, value) => MapEntry(key, (value as num).toInt()));
      } else {
        dataAnggaran.clear(); // Jika dokumen tidak ada, pastikan data kosong
      }
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
    isUploading.value = true;
    try {
      // 1. Dapatkan ekstensi file (selalu .jpg karena kita kompres ke jpg)
      const fileExtension = 'jpg';
      // 2. Buat path file yang unik di dalam bucket
      final filePath = 'public/bukti-transaksi/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      // 'public' adalah folder di dalam bucket, Anda bisa meniadakannya jika tidak perlu
      
      final supabase = Supabase.instance.client;
  
      // 3. Upload file
      await supabase.storage
          .from('bukti-transaksi') // Nama bucket yang sudah Anda buat
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
  
      // 4. Dapatkan URL publiknya
      final publicUrl = supabase.storage
          .from('bukti-transaksi')
          .getPublicUrl(filePath);
          
      print("### Upload Supabase Berhasil. URL: $publicUrl");
      return publicUrl;
  
    } on StorageException catch (e) {
      // Tangani error spesifik dari Supabase
      Get.snackbar("Error Supabase", "Gagal mengunggah bukti: ${e.message}");
      print("### Supabase Storage Error: ${e.message}");
      return null;
    } catch (e) {
      Get.snackbar("Error Upload", "Terjadi kesalahan saat mengunggah: ${e.toString()}");
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
    final int jumlahInt = int.tryParse(jumlah.replaceAll('.', '')) ?? 0;

    // [MODIFIKASI KUNCI] VALIDASI SALDO SEBELUM KONFIRMASI
    if (jenis == 'Pengeluaran' || jenis == 'Transfer') {
      final kasYangDigunakan = (jenis == 'Transfer') ? dariKas : sumberDana;
      final saldoSaatIni = (kasYangDigunakan == 'Bank')
          ? (summaryData['saldoBank'] as num?)?.toInt() ?? 0
          : (summaryData['saldoKasTunai'] as num?)?.toInt() ?? 0;

      if (jumlahInt > saldoSaatIni) {
        Get.snackbar(
          "Saldo Tidak Cukup",
          "Pengeluaran sebesar ${formatRupiah(jumlahInt)} melebihi saldo di $kasYangDigunakan (${formatRupiah(saldoSaatIni)}).",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return; // Hentikan proses
      }
    }
    // [AKHIR MODIFIKASI]

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
            'jumlah': jumlahInt, // Kirim jumlah yang sudah di-parse
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
      final batch = _firestore.batch();

      final pencatatUid = configC.infoUser['uid'];
      final pencatatNama = configC.infoUser['alias'] ?? configC.infoUser['nama'] ?? 'User';

      final sharedTimestamp = Timestamp.now();

      if (jenis == 'Pemasukan' || jenis == 'Pengeluaran') {
        final newTransactionRef = tahunRef.collection('transaksi').doc();
        final Map<String, dynamic> dataTransaksi = {
          'tanggal': sharedTimestamp, 'jenis': jenis, 'jumlah': jumlah,
          'keterangan': data['keterangan'], 'sumberDana': data['sumberDana'],
          'kategori': (jenis == 'Pemasukan') ? 'Pemasukan Lain-Lain' : data['kategori'],
          'urlBuktiTransaksi': (jenis == 'Pengeluaran') ? data['urlBukti'] : null,
          'diinputOleh': pencatatUid, 'diinputOlehNama': pencatatNama,
          if (data['koreksiDariTrxId'] != null) 'koreksiDariTrxId': data['koreksiDariTrxId'],
        };

        final Map<String, dynamic> dataSummaryUpdate = {
          (jenis == 'Pemasukan' ? 'totalPemasukan' : 'totalPengeluaran'): FieldValue.increment(jumlah),
          'saldoAkhir': FieldValue.increment(jenis == 'Pemasukan' ? jumlah : -jumlah),
          (data['sumberDana'] == 'Bank' ? 'saldoBank' : 'saldoKasTunai'): FieldValue.increment(jenis == 'Pemasukan' ? jumlah : -jumlah),
        };

        batch.set(newTransactionRef, dataTransaksi);
        batch.set(tahunRef, dataSummaryUpdate, SetOptions(merge: true));

      } else { // 'Transfer'

        final transferId = tahunRef.collection('transaksi').doc().id;

        // 1. Dokumen Pengeluaran (Transfer Keluar)
        final dataPengeluaran = {
          'tanggal': sharedTimestamp, 'jenis': 'Pengeluaran', 'jumlah': jumlah,
          'keterangan': data['keterangan'], 'sumberDana': data['dariKas'],
          'kategori': 'Transfer Keluar',
          'diinputOleh': pencatatUid, 'diinputOlehNama': pencatatNama,
          'transferId': transferId,
        };
        // [PERBAIKAN] Gunakan 'batch'
        batch.set(tahunRef.collection('transaksi').doc(), dataPengeluaran);

        // 2. Dokumen Pemasukan (Transfer Masuk)
        final dataPemasukan = {
          'tanggal': sharedTimestamp, 'jenis': 'Pemasukan', 'jumlah': jumlah,
          'keterangan': data['keterangan'], 'sumberDana': data['keKas'],
          'kategori': 'Transfer Masuk',
          'diinputOleh': pencatatUid, 'diinputOlehNama': pencatatNama,
          'transferId': transferId,
        };
        // [PERBAIKAN] Gunakan 'batch'
        batch.set(tahunRef.collection('transaksi').doc(), dataPemasukan);

        // 3. Update Saldo Kas & Bank
        final Map<String, dynamic> dataSummaryUpdate = {
          (data['dariKas'] == 'Bank' ? 'saldoBank' : 'saldoKasTunai'): FieldValue.increment(-jumlah),
          (data['keKas'] == 'Bank' ? 'saldoBank' : 'saldoKasTunai'): FieldValue.increment(jumlah),
        };
        // [PERBAIKAN] Gunakan 'batch'
        batch.set(tahunRef, dataSummaryUpdate, SetOptions(merge: true));
      }

      await batch.commit();

      Get.snackbar("Berhasil", "$jenis berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);

    } catch(e) {
      Get.snackbar("Error", "Gagal menyimpan transaksi: ${e.toString()}");
      print("### ERROR MENYIMPAN TRANSAKSI: $e");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    // [MODIFIKASI 4] Pastikan semua subscription dibatalkan
    tabController.dispose();
    _summarySub?.cancel();
    _transaksiSub?.cancel();
    _budgetSub?.cancel(); 
    super.onClose();
  }

  String formatRupiah(dynamic amount) {
    final number = (amount as num?)?.toInt() ?? 0;
    return "Rp ${NumberFormat.decimalPattern('id_ID').format(number)}";
  }

  Future<void> exportToPdf() async {
    if (isExporting.value) return;
    isExporting.value = true;
    
    print("### MENJALANKAN KODE PDF DENGAN LOGIKA KOREKSI v3 (DEFENITIF) ###"); 
  
    try {
      // --- LANGKAH 1: PERSIAPAN ASET (TIDAK BERUBAH) ---
      final infoSekolah = await _firestore.collection('Sekolah').doc(configC.idSekolah).get().then((d) => Map<String, dynamic>.from(d.data() ?? {}));
      final logoBytes = await rootBundle.load('assets/png/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final regularFont = await PdfGoogleFonts.poppinsRegular();
  
      // --- LANGKAH 2: NETTING - Proses data mentah/lengkap ---
      final List<Map<String, dynamic>> nettedTransactions = [];
      final Set<String> idTransaksiYangSudahDiproses = {};
  
      // Gunakan data mentah '_semuaTransaksiTahunIni' untuk memastikan semua pasangan ditemukan
      for (var trx in _semuaTransaksiTahunIni) {
        if (idTransaksiYangSudahDiproses.contains(trx['id'])) continue;
  
        final koreksi = _semuaTransaksiTahunIni.firstWhereOrNull(
          (k) => k['koreksiDariTrxId'] == trx['id']
        );
  
        if (koreksi != null) {
          idTransaksiYangSudahDiproses.add(trx['id']);
          idTransaksiYangSudahDiproses.add(koreksi['id']);
  
          final trxAsli = Map<String, dynamic>.from(trx);
          final jumlahLama = trxAsli['jumlah'] as int;
          final jumlahKoreksi = koreksi['jumlah'] as int;
          
          int jumlahBenar;
          if (trxAsli['jenis'] == koreksi['jenis']) {
              jumlahBenar = jumlahLama + jumlahKoreksi;
          } else {
              jumlahBenar = jumlahLama - jumlahKoreksi;
          }
  
          trxAsli['jumlah'] = jumlahBenar.abs(); // Pastikan jumlah selalu positif
          trxAsli['keterangan'] = "${trxAsli['keterangan']} (*dikoreksi)";
          
          nettedTransactions.add(trxAsli);
  
        } else if (trx['koreksiDariTrxId'] == null) {
          nettedTransactions.add(trx);
        }
      }
      
      // --- LANGKAH 3: FILTER - Terapkan filter UI pada data yang sudah di-netting ---
      final List<Map<String, dynamic>> transaksiUntukPdf = nettedTransactions.where((trx) {
        final tgl = (trx['tanggal'] as Timestamp).toDate();
        final jenis = trx['jenis'] as String;
        final kategori = trx['kategori'] as String?;
  
        final bool matchBulan = filterBulanTahun.value == null || (tgl.year == filterBulanTahun.value!.year && tgl.month == filterBulanTahun.value!.month);
        final bool matchJenis = filterJenis.value == null || jenis == filterJenis.value;
        final bool matchKategori = filterKategori.value == null || kategori == filterKategori.value;
        
        return matchBulan && matchJenis && matchKategori;
      }).toList();
  
  
      // --- LANGKAH 4: RAKIT DOKUMEN PDF (MENGGUNAKAN DATA FINAL) ---
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
        daftarTransaksi: transaksiUntukPdf,
        filterInfo: filterInfoText,
      );
      
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => PdfHelperService.buildHeaderA4(
            infoSekolah: infoSekolah, logoImage: logoImage, 
            boldFont: boldFont, regularFont: regularFont
          ),
          footer: (context) => PdfHelperService.buildFooter(context, regularFont),
          build: (context) => contentWidgets,
        ),
      );
  
      // --- LANGKAH 5: SIMPAN & BAGIKAN (TIDAK BERUBAH) ---
      final String fileName = 'laporan_keuangan_${tahunTerpilih.value}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat file PDF: ${e.toString()}");
      print("### PDF EXPORT ERROR: $e");
    } finally {
      isExporting.value = false;
    }
  }

  // Future<void> exportToPdf() async {
  //   if (isExporting.value) return;
  //   isExporting.value = true;

  //   print("### MENJALANKAN KODE PDF DENGAN LOGIKA KOREKSI ###"); 

  //   try {
  //     // --- LANGKAH 1: PERSIAPAN ASET (TIDAK BERUBAH) ---
  //     final infoSekolah = await _firestore.collection('Sekolah').doc(configC.idSekolah).get().then((d) => Map<String, dynamic>.from(d.data() ?? {}));
  //     final logoBytes = await rootBundle.load('assets/png/logo.png');
  //     final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
  //     final boldFont = await PdfGoogleFonts.poppinsBold();
  //     final regularFont = await PdfGoogleFonts.poppinsRegular();

  //     // --- LANGKAH 2: [UPGRADE] PRA-PEMROSESAN DATA DENGAN LOGIKA NETTING ---
  //     final List<Map<String, dynamic>> transaksiUntukPdf = [];
  //     final Set<String> idTransaksiKoreksi = {}; // Untuk melacak ID transaksi koreksi

  //     // Iterasi pertama: temukan semua transaksi koreksi
  //     for (var trx in daftarTransaksiTampil.value) {
  //       if (trx['koreksiDariTrxId'] != null) {
  //         idTransaksiKoreksi.add(trx['id']);
  //       }
  //     }

  //     // Iterasi kedua: bangun daftar final untuk PDF
  //     for (var trx in daftarTransaksiTampil.value) {
  //       // Lewati transaksi ini jika ia adalah sebuah transaksi koreksi
  //       if (idTransaksiKoreksi.contains(trx['id'])) {
  //         continue;
  //       }

  //       // Cari apakah transaksi ini memiliki koreksi
  //       final koreksi = daftarTransaksiTampil.value.firstWhereOrNull(
  //         (k) => k['koreksiDariTrxId'] == trx['id']
  //       );

  //       if (koreksi != null) {
  //         // Jika ada koreksi, buat entri virtual
  //         final trxAsli = Map<String, dynamic>.from(trx); // Buat salinan
  //         final jumlahLama = trxAsli['jumlah'] as int;
  //         final jumlahKoreksi = koreksi['jumlah'] as int;

  //         // Hitung efek bersih
  //         int jumlahBenar;
  //         if (trxAsli['jenis'] == 'Pengeluaran') {
  //           // Pengeluaran 150rb, dikoreksi (Pemasukan) 50rb -> Efek: 100rb
  //           jumlahBenar = jumlahLama - jumlahKoreksi;
  //         } else { // Pemasukan
  //           // Pemasukan 150rb, dikoreksi (Pengeluaran) 50rb -> Efek: 100rb
  //           jumlahBenar = jumlahLama - jumlahKoreksi;
  //         }

  //         // Modifikasi entri untuk PDF
  //         trxAsli['jumlah'] = jumlahBenar;
  //         trxAsli['keterangan'] = "${trxAsli['keterangan']} (*dikoreksi)";

  //         transaksiUntukPdf.add(trxAsli);

  //       } else {
  //         // Jika tidak ada koreksi, tambahkan transaksi seperti biasa
  //         transaksiUntukPdf.add(trx);
  //       }
  //     }


  //     // --- LANGKAH 3: RAKIT DOKUMEN PDF (MENGGUNAKAN DATA BERSIH) ---
  //     String filterInfoText = "";
  //     if (isFilterActive) {
  //       List<String> filters = [];
  //       if (filterBulanTahun.value != null) filters.add(DateFormat.yMMMM('id_ID').format(filterBulanTahun.value!));
  //       if (filterJenis.value != null) filters.add(filterJenis.value!);
  //       if (filterKategori.value != null) filters.add(filterKategori.value!);
  //       filterInfoText = filters.join(" | ");
  //     }

  //     final List<pw.Widget> contentWidgets = await PdfHelperService.buildLaporanKeuanganContent(
  //       tahunAnggaran: tahunTerpilih.value!,
  //       summaryData: summaryData,
  //       daftarTransaksi: transaksiUntukPdf, // [PENTING] Gunakan data yang sudah diproses
  //       filterInfo: filterInfoText,
  //     );

  //     final pdf = pw.Document();
  //     pdf.addPage(
  //       pw.MultiPage(
  //         pageFormat: PdfPageFormat.a4,
  //         header: (context) => PdfHelperService.buildHeaderA4(
  //           infoSekolah: infoSekolah,
  //           logoImage: logoImage,
  //           boldFont: boldFont,
  //           regularFont: regularFont,
  //         ),
  //         footer: (context) => PdfHelperService.buildFooter(context, regularFont),
  //         build: (context) => contentWidgets,
  //       ),
  //     );

  //     // --- LANGKAH 4: SIMPAN & BAGIKAN (TIDAK BERUBAH) ---
  //     final String fileName = 'laporan_keuangan_${tahunTerpilih.value}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
  //     await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);

  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal membuat file PDF: ${e.toString()}");
  //     print("### PDF EXPORT ERROR: $e");
  //   } finally {
  //     isExporting.value = false;
  //   }
  // }

  // [FUNGSI FINAL #2] Handler utama untuk alur koreksi
  void handleKoreksi(Map<String, dynamic> trxAsli) {
    // 1. Cek Pra-kondisi di Sisi Klien
    final bool isKoreksi = trxAsli['koreksiDariTrxId'] != null;
    final bool isTransfer = trxAsli['transferId'] != null;

    if (isKoreksi || isTransfer) {
      Get.snackbar("Tidak Diizinkan", "Transaksi ini tidak dapat dikoreksi.");
      return;
    }

    // 2. Tampilkan Loading & Lakukan Pengecekan Real-time ke DB
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunAnggaran').doc(tahunTerpilih.value!)
        .collection('transaksi')
        .where('koreksiDariTrxId', isEqualTo: trxAsli['id'])
        .limit(1)
        .get()
        .then((query) {
          Get.back(); // Tutup loading
          if (query.docs.isNotEmpty) {
            Get.snackbar("Sudah Dikoreksi", "Transaksi ini sudah pernah dikoreksi dan tidak dapat dikoreksi lagi.", backgroundColor: Colors.orange.shade800, colorText: Colors.white);
          } else {
            // 3. Jika Semua Aman, Baru Buka Form Koreksi
            _showFormKoreksi(trxAsli);
          }
        }).catchError((e) {
          Get.back(); // Tutup loading
          Get.snackbar("Error", "Gagal memverifikasi status koreksi: $e");
        });
  }

  void _showFormKoreksi(Map<String, dynamic> trxAsli) {
    final formKey = GlobalKey<FormState>();
    final jumlahBenarC = TextEditingController(text: (trxAsli['jumlah'] ?? 0).toString());
    final alasanC = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("Buat Transaksi Koreksi"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Koreksi untuk: ${trxAsli['keterangan']}"),
                const Divider(),
                TextFormField(
                  controller: jumlahBenarC,
                  decoration: const InputDecoration(labelText: "Jumlah Seharusnya", prefixText: "Rp "),
                  inputFormatters: [NumberInputFormatter()],
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Wajib diisi";
                    final val = int.tryParse(v.replaceAll('.', ''));
                    if (val == null) return "Angka tidak valid";
                    // [UPGRADE KUNCI] Validasi anti-minus
                    if (val < 0) return "Jumlah tidak boleh negatif";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: alasanC,
                  decoration: const InputDecoration(labelText: "Alasan Koreksi"),
                  validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                _konfirmasiKoreksi(
                  trxAsli: trxAsli,
                  jumlahBenar: int.tryParse(jumlahBenarC.text.replaceAll('.', '')) ?? 0,
                  alasan: alasanC.text,
                );
              }
            },
            child: const Text("Simpan Koreksi"),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _konfirmasiKoreksi({
    required Map<String, dynamic> trxAsli,
    required int jumlahBenar,
    required String alasan,
  }) {
    final jumlahLama = trxAsli['jumlah'] as int;
    final selisih = jumlahBenar - jumlahLama;

    if (selisih == 0) {
      Get.snackbar("Informasi", "Jumlah yang dimasukkan sama dengan jumlah lama. Tidak ada koreksi yang dibuat.");
      return;
    }

    final jumlahKoreksi = selisih.abs();
    final jenisKoreksi = (trxAsli['jenis'] == 'Pemasukan' && selisih < 0) || (trxAsli['jenis'] == 'Pengeluaran' && selisih > 0)
        ? 'Pengeluaran'
        : 'Pemasukan';

    // [MODIFIKASI KUNCI] VALIDASI SALDO UNTUK KOREKSI PENGELUARAN
    if (jenisKoreksi == 'Pengeluaran') {
      final kasYangDigunakan = trxAsli['sumberDana'] as String?;
      final saldoSaatIni = (kasYangDigunakan == 'Bank')
          ? (summaryData['saldoBank'] as num?)?.toInt() ?? 0
          : (summaryData['saldoKasTunai'] as num?)?.toInt() ?? 0;

      if (jumlahKoreksi > saldoSaatIni) {
        Get.snackbar(
          "Saldo Tidak Cukup",
          "Koreksi ini akan membuat pengeluaran ${formatRupiah(jumlahKoreksi)} dari $kasYangDigunakan, namun saldo hanya ${formatRupiah(saldoSaatIni)}.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return; // Hentikan proses
      }
    }
    // [AKHIR MODIFIKASI]

      Get.defaultDialog(
      title: "Konfirmasi Koreksi",
      middleText: "Ini akan membuat transaksi $jenisKoreksi baru sebesar ${formatRupiah(jumlahKoreksi)} untuk menyeimbangkan pembukuan. Lanjutkan?",
      confirm: Obx(() => ElevatedButton(
        onPressed: isSaving.value ? null : () async {
          isSaving.value = true;
          Get.back();
          Get.back();

          // [MODIFIKASI KUNCI] Buat keterangan yang ramah pengguna
          String keteranganAsli = trxAsli['keterangan'] ?? '';
          // Potong jika terlalu panjang untuk menjaga kebersihan
          if (keteranganAsli.length > 30) {
            keteranganAsli = "${keteranganAsli.substring(0, 30)}...";
          }

          final dataKoreksi = {
            'jumlah': jumlahKoreksi,
            'keterangan': "Koreksi untuk: '$keteranganAsli'. Alasan: $alasan",
            'kategori': trxAsli['kategori'],
            'sumberDana': trxAsli['sumberDana'],
            'koreksiDariTrxId': trxAsli['id'], // [BARU] Field teknis untuk developer
            'dariKas': null, 'keKas': null, 'urlBukti': null,
          };

          await _simpanTransaksi(jenisKoreksi, dataKoreksi);
        },
        child: Text(isSaving.value ? "MEMPROSES..." : "Ya, Lanjutkan"),
      )),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  // Widget _buildDetailRowForDialog(String title, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4.0),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(width: 90, child: Text(title, style: TextStyle(color: Colors.grey.shade600))),
  //         const Text(": "),
  //         Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
  //       ],
  //     ),
  //   );
  // }

  // [FUNGSI BARU] Menampilkan form untuk membuat koreksi
  void showKoreksiDialog(Map<String, dynamic> trxAsli) {
    final formKey = GlobalKey<FormState>();
    final jumlahBenarC = TextEditingController(text: (trxAsli['jumlah'] ?? 0).toString());
    final alasanC = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("Buat Transaksi Koreksi"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Koreksi untuk: ${trxAsli['keterangan']}"),
                const Divider(),
                TextFormField(
                  controller: jumlahBenarC,
                  decoration: const InputDecoration(labelText: "Jumlah Seharusnya", prefixText: "Rp "),
                  inputFormatters: [NumberInputFormatter()],
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Wajib diisi";
                    final val = int.tryParse(v.replaceAll('.', ''));
                    if (val == null) return "Angka tidak valid";
                    // [UPGRADE KUNCI] Validasi anti-minus
                    if (val < 0) return "Jumlah tidak boleh negatif";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: alasanC,
                  decoration: const InputDecoration(labelText: "Alasan Koreksi"),
                  validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                _konfirmasiKoreksi(
                  trxAsli: trxAsli,
                  jumlahBenar: int.tryParse(jumlahBenarC.text.replaceAll('.', '')) ?? 0,
                  alasan: alasanC.text,
                );
              }
            },
            child: const Text("Simpan Koreksi"),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // [BARU] Data untuk Bar Chart (Pemasukan vs Pengeluaran per Bulan)
  Rx<Map<int, Map<String, double>>> get dataGrafikBulanan {
    final Map<int, Map<String, double>> data = {};
    // Inisialisasi 12 bulan dengan nilai 0
    for (int i = 1; i <= 12; i++) {
      data[i] = {'pemasukan': 0.0, 'pengeluaran': 0.0};
    }

    // Olah semua transaksi (bukan hanya yang difilter)
    for (var trx in _semuaTransaksiTahunIni) {
      final tanggal = (trx['tanggal'] as Timestamp).toDate();
      final bulan = tanggal.month;
      final jumlah = (trx['jumlah'] as num).toDouble();
      final jenis = trx['jenis'] as String;

      if (jenis == 'Pemasukan' && trx['kategori'] != 'Transfer Masuk') {
        data[bulan]!['pemasukan'] = (data[bulan]!['pemasukan'] ?? 0.0) + jumlah;
      } else if (jenis == 'Pengeluaran' && trx['kategori'] != 'Transfer Keluar') {
        data[bulan]!['pengeluaran'] = (data[bulan]!['pengeluaran'] ?? 0.0) + jumlah;
      }
    }
    return Rx(data);
  }

  // [BARU] Data untuk Pie Chart (Distribusi Kategori Pengeluaran)
  Rx<Map<String, double>> get dataDistribusiPengeluaran {
    final Map<String, double> data = {};

    // Olah semua transaksi pengeluaran (bukan hanya yang difilter)
    for (var trx in _semuaTransaksiTahunIni) {
      final jenis = trx['jenis'] as String;
      final kategori = trx['kategori'] as String?;
      final jumlah = (trx['jumlah'] as num).toDouble();

      if (jenis == 'Pengeluaran' && kategori != null && kategori != 'Transfer Keluar') {
        data[kategori] = (data[kategori] ?? 0.0) + jumlah;
      }
    }
    return Rx(data);
  }
}