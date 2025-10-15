// lib/app/modules/input_nilai_siswa/views/input_nilai_siswa_view.dart (LOGIKA EKSKLUSIF DITERAPKAN)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mi_alhuda_yogyakarta/app/models/atp_model.dart';
import 'package:mi_alhuda_yogyakarta/app/models/nilai_harian_model.dart';
import '../controllers/input_nilai_siswa_controller.dart';

class InputNilaiSiswaView extends GetView<InputNilaiSiswaController> {
  const InputNilaiSiswaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RxString selectedKategori = "Harian/PR".obs;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(controller.namaMapel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(controller.siswa.namaLengkap, style: const TextStyle(fontSize: 14)),
          ],
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            return controller.isSaving.value
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
              : TextButton(
                  onPressed: controller.simpanSemuaCapaian,
                  child: Text("SIMPAN", style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold)),
                );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNilaiAkhirCard(),
            const SizedBox(height: 24),
            Text("Penilaian Sumatif", style: Get.textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildKategoriSelector(selectedKategori),
            const SizedBox(height: 16),
            Obx(() => _buildKontenNilai(selectedKategori.value)),
            const Divider(height: 48, thickness: 1),
            
            // --- Widget yang logikanya DIPERBAIKI SESUAI INSTRUKSI ---
            _buildKurikulumMerdekaSection(),

            Obx(() {
              if (controller.isWaliKelas.value) {
                return _buildRekapWaliKelas();
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      }),
    );
  }

  // --- [PERBAIKAN FINAL DI SINI] ---
  // Logika kini ketat: jika ATP ada, hanya tampilkan daftar TP. Jika tidak, hanya tampilkan deskripsi manual.
  Widget _buildKurikulumMerdekaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Capaian Pembelajaran", style: Get.textTheme.titleLarge),
        const SizedBox(height: 8),
        Obx(() {
          // JIKA ATP TIDAK DITEMUKAN (null)
          if (controller.atpModel.value == null) {
            // Maka, tampilkan HANYA card deskripsi manual (KOTAK MERAH).
            return _buildDeskripsiManualCard();
          } 
          // JIKA ATP DITEMUKAN
          else {
            // Maka, tampilkan HANYA daftar TP (KOTAK BIRU).
            return _buildTPList(controller.atpModel.value!);
          }
        }),
      ],
    );
  }

  // Widget ini tidak diubah.
  Widget _buildTPList(AtpModel atp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pilih capaian siswa berdasarkan Tujuan Pembelajaran (TP) yang ada.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        ...atp.unitPembelajaran.map((unit) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.lingkupMateri, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 16),
                ...unit.tujuanPembelajaran.map((tp) => _buildTPItem(tp)).toList(),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }
  
  // Widget ini tidak diubah.
  Widget _buildTPItem(String tp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text("• $tp", style: const TextStyle(height: 1.4))),
          const SizedBox(width: 8),
          Obx(() {
            final status = controller.capaianTpSiswa[tp];
            return ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minHeight: 32.0),
              isSelected: [status == 'Tercapai', status == 'Perlu Bimbingan'],
              onPressed: (index) {
                controller.setCapaianTp(tp, index == 0 ? 'Tercapai' : 'Perlu Bimbingan');
              },
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("T")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("PB")),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  // Widget ini disederhanakan, parameter 'isAtpAvailable' tidak lagi dibutuhkan.
  Widget _buildDeskripsiManualCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Deskripsi Manual", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Karena ATP belum diatur untuk mapel ini, isi deskripsi capaian siswa secara manual.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(controller: controller.deskripsiCapaianC, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Deskripsi Capaian Siswa")),
          ],
        ),
      ),
    );
  }

  // --- Sisa widget di bawah ini tidak ada perubahan ---
  
  Widget _buildRekapWaliKelas() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          Text("Rekap Nilai Siswa (Akses Wali Kelas)", style: Get.textTheme.titleLarge),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.rekapNilaiMapelLain.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Belum ada nilai dari mapel lain.")));
            }
            return Card(
              child: Column(
                children: controller.rekapNilaiMapelLain.map((rekap) => ListTile(
                  title: Text(rekap['mapel']),
                  subtitle: Text("Guru: ${rekap['guru']}"),
                  trailing: Text(
                    (rekap['nilai_akhir'] as double).toStringAsFixed(1),
                    style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                )).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNilaiAkhirCard() {
    return Card(
      elevation: 4,
      color: Get.theme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("NILAI AKHIR RAPOR", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Obx(() => Text(
              controller.nilaiAkhir.value?.toStringAsFixed(1) ?? '-',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 42),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriSelector(RxString selectedKategori) {
    final kategori = ["Harian/PR", "Ulangan Harian", "PTS", "PAS", "Nilai Tambahan"];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: kategori.map((item) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Obx(() => ChoiceChip(
            label: Text(item),
            selectedColor: Get.theme.primaryColor.withOpacity(0.8),
            labelStyle: TextStyle(color: selectedKategori.value == item ? Colors.white : Colors.black),
            selected: selectedKategori.value == item,
            onSelected: (selected) { if (selected) selectedKategori.value = item; },
          )),
        )).toList(),
      ),
    );
  }

  Widget _buildKontenNilai(String kategori) {
    switch (kategori) {
      case "PTS":
        return _buildNilaiUtamaCard("Penilaian Tengah Semester", controller.nilaiPTS, 'nilai_pts');
      case "PAS":
        return _buildNilaiUtamaCard("Penilaian Akhir Semester", controller.nilaiPAS, 'nilai_pas');
      default:
        return _buildNilaiHarianList(kategori);
    }
  }

  Widget _buildNilaiUtamaCard(String title, Rxn<int> nilaiState, String fieldName) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Obx(() => Text(
          nilaiState.value?.toString() ?? "Belum Diisi",
          style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: nilaiState.value == null ? Colors.grey : null),
        )),
        onTap: () => _showInputDialog(
          title: "Input $title",
          initialValue: nilaiState.value?.toString() ?? '',
          onSave: (nilai) => controller.simpanNilaiUtama(fieldName, nilai),
        ),
      ),
    );
  }

  Widget _buildNilaiHarianList(String kategori) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final listNilai = controller.daftarNilaiHarian.where((n) {
            if (kategori == "Harian/PR") return n.kategori == "Harian/PR" || n.kategori == "PR";
            return n.kategori == kategori;
          }).toList();

          if (listNilai.isEmpty) return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: Text("Belum ada nilai untuk kategori ini.", style: TextStyle(color: Colors.grey.shade600))),
          );
          
          return Column(
            children: listNilai.map((nilai) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text(nilai.nilai.toString())),
                title: Text(nilai.catatan.isNotEmpty ? nilai.catatan : "Nilai ${nilai.kategori}"),
                subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(nilai.tanggal)),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showInputDialog(
                        title: "Edit Nilai ${nilai.kategori}", showCatatan: true,
                        initialValue: nilai.nilai.toString(), initialCatatan: nilai.catatan,
                        onSave: (_) => controller.updateNilaiHarian(nilai.id),
                      );
                    } else if (value == 'hapus') {
                      controller.deleteNilaiHarian(nilai.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                    const PopupMenuItem(value: 'hapus', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Hapus', style: TextStyle(color: Colors.red)))),
                  ],
                ),
              ),
            )).toList(),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: Text("Tambah Nilai $kategori"),
          onPressed: () => _showInputDialog(
            title: "Tambah Nilai $kategori",
            showCatatan: true,
            onSave: (_) => controller.simpanNilaiHarian(kategori),
          ),
        ),
      ],
    );
  }

  void _showInputDialog({
    required String title, String initialValue = '', String initialCatatan = '',
    bool showCatatan = false, required Function(int) onSave,
    }) {
    controller.nilaiC.text = initialValue;
    controller.catatanC.text = initialCatatan;
    Get.defaultDialog(
      title: title,
      content: Column(
        children: [
          TextField(controller: controller.nilaiC, decoration: const InputDecoration(labelText: 'Nilai (0-100)'), keyboardType: TextInputType.number),
          if (showCatatan) TextField(controller: controller.catatanC, decoration: const InputDecoration(labelText: 'Catatan (Opsional)')),
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isSaving.value ? null : () {
          int? nilai = int.tryParse(controller.nilaiC.text);
          if (nilai != null && nilai >= 0 && nilai <= 100) {
            onSave(nilai);
          } else {
            Get.snackbar("Input Tidak Valid", "Nilai harus berupa angka antara 0 dan 100.");
          }
        },
        child: controller.isSaving.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }
}