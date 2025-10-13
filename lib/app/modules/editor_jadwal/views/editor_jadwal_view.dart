// lib/app/modules/editor_jadwal/views/editor_jadwal_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_jadwal_controller.dart';

class EditorJadwalView extends GetView<EditorJadwalController> {
  const EditorJadwalView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Jadwal Pelajaran'),
        actions: [
          Obx(() => controller.isSaving.value
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(icon: const Icon(Icons.save), onPressed: controller.simpanJadwal)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedKelasId.value,
              hint: const Text('Pilih Kelas'),
              items: controller.daftarKelas.map((k) => DropdownMenuItem<String>(value: k['id'], child: Text(k['nama']))).toList(),
              onChanged: controller.onKelasChanged,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            )),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedKelasId.value == null) return const Expanded(child: Center(child: Text('Pilih kelas untuk memulai.')));
              if (controller.isLoadingJadwal.value) return const Expanded(child: Center(child: CircularProgressIndicator()));
              return Expanded(child: _buildScheduleEditor());
            }),
          ],
        ),
      ),
      floatingActionButton: Obx(() => controller.selectedKelasId.value != null && !controller.isLoadingJadwal.value
          ? FloatingActionButton(onPressed: controller.tambahPelajaran, child: const Icon(Icons.add))
          : const SizedBox.shrink()),
    );
  }

  Widget _buildScheduleEditor() {
    return Column(children: [
      DropdownButtonFormField<String>(
        value: controller.selectedHari.value,
        items: controller.daftarHari.map((h) => DropdownMenuItem<String>(value: h, child: Text(h))).toList(),
        onChanged: (v) => controller.selectedHari.value = v!,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      Expanded(child: Obx(() {
        final listPelajaran = controller.jadwalPelajaran[controller.selectedHari.value]!;
        if (listPelajaran.isEmpty) return const Center(child: Text('Jadwal kosong. Klik + untuk menambah.'));
        listPelajaran.sort((a,b) => (a['jamMulai'] as String? ?? 'Z').compareTo((b['jamMulai'] as String? ?? 'Z')));
        
        return ListView.builder(
          itemCount: listPelajaran.length,
          itemBuilder: (context, index) => _buildPelajaranCard(listPelajaran[index], index),
        );
      })),
    ]);
  }

  // [PEROMBAKAN TOTAL WIDGET INI]
  Widget _buildPelajaranCard(Map<String, dynamic> pelajaran, int index) {
    // [PERBAIKAN #1] Hapus Obx dari sini.
    final bool isKegiatanUmum = pelajaran['idMapel'] == null && pelajaran['namaMapel'] != null;

    return Card(
      color: isKegiatanUmum ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                isKegiatanUmum ? pelajaran['namaMapel'] : 'Slot Pelajaran',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isKegiatanUmum ? Colors.blue.shade800 : null,
                ),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => controller.hapusPelajaran(index)),
            ]),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: _buildTimePickerField(Get.context!, 'Jam Mulai', pelajaran['jamMulai'], () => controller.pilihWaktu(Get.context!, index, true))),
              const SizedBox(width: 8),
              Expanded(child: _buildTimePickerField(Get.context!, 'Jam Selesai', pelajaran['jamSelesai'], () => controller.pilihWaktu(Get.context!, index, false))),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.widgets_outlined, color: Colors.blue.shade800),
                onPressed: () => controller.pilihDariTemplate(index),
                tooltip: "Pilih dari Template",
              )
            ]),
            
            const SizedBox(height: 12),

            if (isKegiatanUmum)
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blue),
                title: Text(pelajaran['namaMapel'] ?? ''),
                subtitle: const Text("Kegiatan Sekolah"),
              )
            else
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: pelajaran['idMapel'],
                    hint: const Text("Pilih Mata Pelajaran"),
                    isExpanded: true,
                    items: controller.daftarMapelTersedia.map((m) => DropdownMenuItem<String>(value: m['idMapel'], child: Text(m['nama']))).toList(),
                    onChanged: (v) => controller.updatePelajaran(index, 'idMapel', v),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // [PERBAIKAN #2] Bungkus bagian ini dengan Obx yang lebih spesifik
                  Obx(() {
                    if (pelajaran['idMapel'] != 'halaqah') {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: pelajaran['idGuru'],
                            hint: const Text("Pilih Guru Pengajar"),
                            isExpanded: true,
                            items: controller.guruDropdownList.where((g) {
                              if (controller.tampilkanSemuaGuru.value) return true;
                              return g['idMapel'] == pelajaran['idMapel'];
                            }).map((g) => DropdownMenuItem<String>(value: g['uid'], child: Text(g['alias']))).toList(),
                            onChanged: (v) => controller.updatePelajaran(index, 'idGuru', v),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                          SwitchListTile(
                            title: const Text("Tampilkan semua guru", style: TextStyle(fontSize: 14)),
                            value: controller.tampilkanSemuaGuru.value,
                            onChanged: controller.toggleTampilkanSemuaGuru,
                            dense: true,
                          ),
                        ],
                      );
                    } else {
                      return ListTile(
                        leading: const Icon(Icons.group_work_outlined),
                        title: Text(pelajaran['namaGuru'] ?? 'Tim Tahsin/Tahfidz'),
                        subtitle: const Text("Guru Halaqah"),
                      );
                    }
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk input waktu
  Widget _buildTimePickerField(BuildContext context, String label, String? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(time ?? 'Pilih Waktu', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}


// // lib/app/modules/editor_jadwal/views/editor_jadwal_view.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/editor_jadwal_controller.dart';

// class EditorJadwalView extends GetView<EditorJadwalController> {
//   const EditorJadwalView({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Editor Jadwal Pelajaran'),
//         actions: [
//           Obx(() => controller.isSaving.value
//               ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
//               : IconButton(icon: const Icon(Icons.save), onPressed: controller.simpanJadwal)),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Obx(() => DropdownButtonFormField<String>(
//               value: controller.selectedKelasId.value,
//               hint: const Text('Pilih Kelas'),
//               items: controller.daftarKelas.map((k) => DropdownMenuItem<String>(value: k['id'], child: Text(k['nama']))).toList(),
//               onChanged: controller.onKelasChanged,
//             )),
//             const SizedBox(height: 16),
//             Obx(() {
//               if (controller.selectedKelasId.value == null) return const Expanded(child: Center(child: Text('Pilih kelas untuk memulai.')));
//               if (controller.isLoadingJadwal.value) return const Expanded(child: Center(child: CircularProgressIndicator()));
//               return Expanded(child: _buildScheduleEditor());
//             }),
//           ],
//         ),
//       ),
//       floatingActionButton: Obx(() => controller.selectedKelasId.value != null && !controller.isLoadingJadwal.value
//           ? FloatingActionButton(onPressed: controller.tambahPelajaran, child: const Icon(Icons.add))
//           : const SizedBox.shrink()),
//     );
//   }

//   Widget _buildScheduleEditor() {
//     return Column(children: [
//       DropdownButtonFormField<String>(
//         value: controller.selectedHari.value,
//         items: controller.daftarHari.map((h) => DropdownMenuItem<String>(value: h, child: Text(h))).toList(),
//         onChanged: (v) => controller.selectedHari.value = v!,
//       ),
//       const SizedBox(height: 16),
//       Expanded(child: Obx(() {
//         final listPelajaran = controller.jadwalPelajaran[controller.selectedHari.value]!;
//         if (listPelajaran.isEmpty) return const Center(child: Text('Jadwal kosong. Klik + untuk menambah.'));
//         listPelajaran.sort((a,b) => (a['jam'] as String? ?? 'Z').compareTo((b['jam'] as String? ?? 'Z')));
        
//         return ListView.builder(
//           itemCount: listPelajaran.length,
//           itemBuilder: (context, index) => _buildPelajaranCard(listPelajaran[index], index),
//         );
//       })),
//     ]);
//   }

//   Widget _buildPelajaranCard(Map<String, dynamic> pelajaran, int index) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(children: [
//           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//             Text('Slot ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
//             IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.hapusPelajaran(index)),
//           ]),
//           DropdownButtonFormField<String>(
//             value: pelajaran['jam'],
//             items: controller.daftarJam.map((j) => DropdownMenuItem<String>(value: j['waktu'], child: Text(j['label']))).toList(),
//             onChanged: (v) => controller.updatePelajaran(index, 'jam', v),
//           ),
//           const SizedBox(height: 8),
//           DropdownButtonFormField<String>(
//             value: pelajaran['idMapel'],
//             items: controller.daftarMapelTersedia.map((m) => DropdownMenuItem<String>(value: m['idMapel'], child: Text(m['nama']))).toList(),
//             onChanged: (v) => controller.updatePelajaran(index, 'idMapel', v),
//           ),
//           const SizedBox(height: 8),
//           Obx(() {
//             final idMapelTerpilih = pelajaran['idMapel'];
//             final guruUntukMapelIni = controller.daftarGuruTersedia.where((g) => g['idMapel'] == idMapelTerpilih).toList();
//             return DropdownButtonFormField<String>(
//               value: pelajaran['idGuru'],
//               items: guruUntukMapelIni.map((g) => DropdownMenuItem<String>(value: g['uid'], 
//               child: Text(g['alias']))).toList(),
//               onChanged: (v) => controller.updatePelajaran(index, 'idGuru', v),
//             );
//           }),
//         ]),
//       ),
//     );
//   }
// }