// lib/app/modules/prota_prosem/views/prota_prosem_view.dart (FINAL & LENGKAP)

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/atp_model.dart';
import '../controllers/prota_prosem_controller.dart';

class ProtaProsemView extends GetView<ProtaProsemController> {
  const ProtaProsemView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Prota & Prosem"),
          actions: [
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: controller.cetakProtaProsem,
              tooltip: "Cetak ke PDF",
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Program Semester 1"),
              Tab(text: "Program Semester 2"),
              Tab(text: "Program Tahunan (Rekap)"),
            ],
          ),
        ),
        body: Obx(() => TabBarView(
          children: [
            _buildSemesterView(semester: 1),
            _buildSemesterView(semester: 2),
            _buildProtaView(),
          ],
        )),
      ),
    );
  }

  Widget _buildSemesterView({required int semester}) {
    final scheduledUnits = controller.atp.value.unitPembelajaran.where((unit) => unit.semester == semester).toList();
    final unscheduledUnits = controller.atp.value.unitPembelajaran.where((unit) => unit.semester == null || unit.semester == 0).toList();
    final groupedByMonth = groupBy(scheduledUnits, (UnitPembelajaran unit) => unit.bulan!);
    List<String> monthsInOrder = (semester == 1) ? controller.bulanSemester1 : controller.bulanSemester2;
      
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUnscheduledCard(unscheduledUnits),
          const SizedBox(height: 24),
          ...monthsInOrder.map((bulan) {
            final itemsForMonth = groupedByMonth[bulan] ?? [];
            return _buildMonthCard(bulan: bulan, items: itemsForMonth);
          }).toList(),
        ],
      ),
    );
  }

  Card _buildUnscheduledCard(List<UnitPembelajaran> units) {
    return Card(
      elevation: 0, color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Materi Belum Terjadwal", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (units.isEmpty)
              Text("Semua materi sudah terjadwal. Hebat!", style: TextStyle(color: Colors.grey.shade700))
            else
              ...units.map((unit) => ListTile(
                dense: true, contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.topic_outlined, size: 20),
                title: Text(unit.lingkupMateri),
                trailing: ElevatedButton(
                  onPressed: () => _showSchedulingDialog(unit),
                  child: const Text("Jadwalkan"),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Card _buildMonthCard({required String bulan, required List<UnitPembelajaran> items}) {
    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bulan, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            if (items.isEmpty)
              Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("Belum ada materi dijadwalkan untuk bulan ini.", style: TextStyle(color: Colors.grey.shade700)))
            else
              ...items.map((item) => ListTile(
                contentPadding: EdgeInsets.zero, dense: true,
                leading: Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                title: Text("${item.lingkupMateri} (${item.alokasiWaktu})", style: Get.textTheme.bodyLarge),
                trailing: IconButton(
                  icon: Icon(Icons.undo_rounded, color: Colors.orange.shade800),
                  tooltip: "Batal Jadwal",
                  onPressed: () {
                    Get.defaultDialog(
                      title: "Konfirmasi", middleText: "Anda yakin ingin membatalkan jadwal untuk materi '${item.lingkupMateri}'?",
                      confirm: TextButton(onPressed: () { Get.back(); controller.batalkanJadwalUnit(idUnit: item.idUnit); }, child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.red))),
                      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Tidak")),
                    );
                  },
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProtaView() {
    // Urutkan unit berdasarkan semester dan bulan untuk tampilan Prota yang logis
    final sortedUnits = List<UnitPembelajaran>.from(controller.atp.value.unitPembelajaran);
    sortedUnits.sort((a, b) {
      final semesterA = a.semester ?? 99; // yang belum terjadwal taruh di akhir
      final semesterB = b.semester ?? 99;
      return semesterA.compareTo(semesterB);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text("Rekapitulasi Program Tahunan", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          DataTable(
            columnSpacing: 20,
            border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text("Semester", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Unit Pembelajaran / Materi Pokok", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Alokasi Waktu", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: sortedUnits.map((unit) => DataRow(
              cells: [
                DataCell(Text(unit.semester?.toString() ?? "-")),
                DataCell(Text(unit.lingkupMateri)),
                DataCell(Text(unit.alokasiWaktu)),
              ]
            )).toList(),
          )
        ],
      ),
    );
  }

  void _showSchedulingDialog(UnitPembelajaran unit) {
    final RxInt selectedSemester = 1.obs;
    final RxString selectedMonth = ''.obs;

    Get.defaultDialog(
      title: "Jadwalkan Materi", titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Pilih jadwal untuk:\n'${unit.lingkupMateri}'", textAlign: TextAlign.center),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: selectedSemester.value,
            decoration: const InputDecoration(labelText: "Semester", border: OutlineInputBorder()),
            items: const [ DropdownMenuItem(value: 1, child: Text("Semester 1")), DropdownMenuItem(value: 2, child: Text("Semester 2")) ],
            onChanged: (value) { if (value != null) { selectedSemester.value = value; selectedMonth.value = ''; } },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            hint: const Text("Pilih Bulan"),
            value: selectedMonth.value.isEmpty ? null : selectedMonth.value,
            decoration: const InputDecoration(labelText: "Bulan", border: OutlineInputBorder()),
            items: (selectedSemester.value == 1 ? controller.bulanSemester1 : controller.bulanSemester2)
                .map((bulan) => DropdownMenuItem(value: bulan, child: Text(bulan)))
                .toList(),
            onChanged: (value) { if (value != null) selectedMonth.value = value; },
          ),
        ],
      )),
      confirm: Obx(() => ElevatedButton(
        onPressed: selectedMonth.value.isEmpty ? null : () {
          controller.jadwalkanUnit(idUnit: unit.idUnit, semester: selectedSemester.value, bulan: selectedMonth.value);
          Get.back();
        },
        child: const Text("Simpan Jadwal"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }
}