// lib/app/modules/manajemen_kalender_akademik/controllers/manajemen_kalender_akademik_controller.dart (FINAL & SOLID)

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/dashboard_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/acara_kalender_model.dart';
import 'package:table_calendar/table_calendar.dart';

class ManajemenKalenderAkademikController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final bool isPimpinan = Get.find<DashboardController>().isPimpinan;

  late final CollectionReference<Map<String, dynamic>> _acaraRef;
  StreamSubscription? _acaraSubscription;

  final isLoading = true.obs; // [PERBAIKAN] Tambahkan deklarasi isLoading

  final RxMap<DateTime, List<AcaraKalender>> events = <DateTime, List<AcaraKalender>>{}.obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rxn<DateTime> selectedDay = Rxn<DateTime>();
  final Rx<CalendarFormat> calendarFormat = CalendarFormat.month.obs;
  final RxList<AcaraKalender> monthlyEvents = <AcaraKalender>[].obs;

  final formKey = GlobalKey<FormState>();
  final TextEditingController namaC = TextEditingController();
  final TextEditingController deskripsiC = TextEditingController();
  final Rx<DateTime> tanggalMulai = DateTime.now().obs;
  final Rx<DateTime> tanggalSelesai = DateTime.now().obs;
  final RxBool isLibur = false.obs;
  final Rx<Color> warnaTerpilih = Colors.blue.obs;
  final RxBool isFormLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    selectedDay.value = focusedDay.value;
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    
    // [PERBAIKAN] Pindah logika ini ke _initializeData atau _listenToEvents
    // dan pastikan isLoading diatur dengan benar.
    if (tahunAjaran.isNotEmpty && !tahunAjaran.contains("TIDAK")) {
      _acaraRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kalender_akademik');
      _listenToEvents();
    } else {
      Get.snackbar("Peringatan", "Tahun ajaran aktif belum terdeteksi. Kalender mungkin tidak tampil.");
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _acaraSubscription?.cancel();
    namaC.dispose();
    deskripsiC.dispose();
    super.onClose();
  }

  void _listenToEvents() {
    // [PERBAIKAN] Pastikan isLoading diatur saat memulai dan mengakhiri loading data.
    isLoading.value = true;
    _acaraSubscription = _acaraRef.snapshots().listen((snapshot) {
      final Map<DateTime, List<AcaraKalender>> tempEvents = {};
      for (var doc in snapshot.docs) {
        try {
          final acara = AcaraKalender.fromFirestore(doc);
          for (var day = acara.mulai; day.isBefore(acara.selesai.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
            final dateWithoutTime = DateTime(day.year, day.month, day.day);
            if (tempEvents[dateWithoutTime] == null) tempEvents[dateWithoutTime] = [];
            tempEvents[dateWithoutTime]!.add(acara);
          }
        } catch (e) { print("Error parsing acara: ${doc.id}, error: $e"); }
      }
      events.value = tempEvents;
      _updateMonthlyEvents();
      isLoading.value = false; // Set false setelah data di-load
    }, onError: (error) {
      print("[ManajemenKalenderAkademikController] Error listening to events: $error");
      Get.snackbar("Error", "Gagal memuat acara kalender: $error");
      isLoading.value = false; // Set false juga jika ada error
    });
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    if (!isSameDay(selectedDay.value, selected)) {
      selectedDay.value = selected;
      focusedDay.value = focused;
    }
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
    _updateMonthlyEvents();
  }

  void _updateMonthlyEvents() {
    final List<AcaraKalender> eventsInMonth = [];
    final Set<String> uniqueEventIds = {};
    events.forEach((date, acaraList) {
      if (date.month == focusedDay.value.month && date.year == focusedDay.value.year) {
        for (var acara in acaraList) {
          if (uniqueEventIds.add(acara.id)) eventsInMonth.add(acara);
        }
      }
    });
    eventsInMonth.sort((a, b) => a.mulai.compareTo(b.mulai));
    monthlyEvents.value = eventsInMonth;
  }

  List<AcaraKalender> getEventsForDay(DateTime day) {
    return events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String _colorToHex(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  void showColorPickerDialog() {
    final Rx<Color> dialogPickerColor = warnaTerpilih.value.obs; // Gunakan Rx<Color> sementara
    Get.dialog(
      AlertDialog(
        title: const Text('Pilih Warna Acara'),
        content: Obx(() => SingleChildScrollView( // Obx untuk rebuild saat warna berubah
          child: ColorPicker(
            pickerColor: dialogPickerColor.value,
            onColorChanged: (color) => dialogPickerColor.value = color, // Perbarui Rx<Color>
          ),
        )),
        actions: [ ElevatedButton(child: const Text('Pilih'), onPressed: () {
          warnaTerpilih.value = dialogPickerColor.value; // Assign nilai final
          Get.back();
        })],
      ),
    );
  }

  void showFormDialog({AcaraKalender? acara}) {
    if (acara != null) {
      namaC.text = acara.judul; deskripsiC.text = acara.deskripsi;
      tanggalMulai.value = acara.mulai; tanggalSelesai.value = acara.selesai;
      isLibur.value = acara.isLibur; warnaTerpilih.value = acara.warna;
    } else {
      namaC.clear(); deskripsiC.clear();
      tanggalMulai.value = selectedDay.value ?? DateTime.now();
      tanggalSelesai.value = selectedDay.value ?? DateTime.now();
      isLibur.value = false; warnaTerpilih.value = Colors.blue;
    }

    Get.defaultDialog(
      title: acara == null ? "Tambah Acara Baru" : "Edit Acara",
      content: SizedBox(
        width: Get.width, height: Get.height * 0.6,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(controller: namaC, decoration: const InputDecoration(labelText: 'Nama Kegiatan'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                const SizedBox(height: 16),
                TextField(controller: deskripsiC, decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)', alignLabelWithHint: true), maxLines: 3),
                const SizedBox(height: 16),
                _buildDatePicker(label: "Tanggal Mulai", isMulai: true),
                _buildDatePicker(label: "Tanggal Selesai", isMulai: false),
                ListTile(
                  contentPadding: EdgeInsets.zero, title: const Text('Warna Acara'),
                  trailing: Obx(() => CircleAvatar(backgroundColor: warnaTerpilih.value, radius: 15)),
                  onTap: showColorPickerDialog,
                ),
                Obx(() => SwitchListTile(title: const Text("Tandai sebagai hari libur"), value: isLibur.value, onChanged: (val) => isLibur.value = val, dense: true)),
              ],
            ),
          ),
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isFormLoading.value ? null : () => simpanAcara(eventId: acara?.id),
        child: Text(isFormLoading.value ? "Menyimpan..." : "Simpan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  Widget _buildDatePicker({required String label, required bool isMulai}) {
    return Obx(() => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(isMulai ? tanggalMulai.value : tanggalSelesai.value)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(context: Get.context!, initialDate: isMulai ? tanggalMulai.value : tanggalSelesai.value, firstDate: DateTime(2022), lastDate: DateTime(2030));
        if (picked != null) {
          if (isMulai) {
            tanggalMulai.value = picked;
            if (picked.isAfter(tanggalSelesai.value)) tanggalSelesai.value = picked;
          } else {
            tanggalSelesai.value = picked;
          }
        }
      },
    ));
  }

  void simpanAcara({String? eventId}) async {
    if (!formKey.currentState!.validate()) return;
    if (tanggalMulai.value.isAfter(tanggalSelesai.value)) { Get.snackbar("Peringatan", "Tanggal mulai tidak boleh setelah tanggal selesai."); return; }

    isFormLoading.value = true;
    try {
      final dataToSave = {
        "namaKegiatan": namaC.text.trim(), "deskripsi": deskripsiC.text.trim(),
        "tanggalMulai": Timestamp.fromDate(tanggalMulai.value),
        "tanggalSelesai": Timestamp.fromDate(tanggalSelesai.value),
        "isLibur": isLibur.value, "warnaHex": _colorToHex(warnaTerpilih.value),
        "dibuatOleh": configC.infoUser['uid'], 
        "timestamp": FieldValue.serverTimestamp(),
      };

      if (eventId == null) {
        await _acaraRef.add(dataToSave);
        Get.back(); Get.snackbar("Berhasil", "Acara baru berhasil ditambahkan.");
      } else {
        await _acaraRef.doc(eventId).update(dataToSave);
        Get.back(); Get.snackbar("Berhasil", "Acara berhasil diperbarui.");
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan acara: $e");
      print("[ManajemenKalenderAkademikController] Error saving event: $e");
    } finally {
      isFormLoading.value = false;
    }
  }

  void hapusAcara(String eventId) {
    Get.defaultDialog(
      title: "Konfirmasi Hapus", middleText: "Anda yakin ingin menghapus acara ini?",
      textConfirm: "Ya, Hapus", textCancel: "Batal", confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        try {
          await _acaraRef.doc(eventId).delete();
          Get.snackbar("Berhasil", "Acara telah dihapus.");
        } catch (e) { 
          Get.snackbar("Error", "Gagal menghapus acara: $e");
          print("[ManajemenKalenderAkademikController] Error deleting event: $e");
        }
      },
    );
  }
}