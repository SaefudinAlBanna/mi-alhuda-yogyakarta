import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/kenaikan_siswa_model.dart';
import '../controllers/proses_kenaikan_kelas_controller.dart';

class ProsesKenaikanKelasView extends GetView<ProsesKenaikanKelasController> {
  const ProsesKenaikanKelasView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Proses Kenaikan Kelas ${controller.tahunAjaranLama}")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.siswaPerKelas.isEmpty) {
          return const Center(child: Text("Tidak ada siswa yang terdaftar di tahun ajaran ini."));
        }
        return _buildWizard();
      }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: controller.isProcessing.value ? null : controller.konfirmasiDanJalankanProses,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(controller.isProcessing.value ? "MEMPROSES..." : "JALANKAN PROSES KENAIKAN KELAS"),
        )),
      ),
    );
  }

  Widget _buildWizard() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: controller.siswaPerKelas.keys.length,
      itemBuilder: (context, index) {
        String kelasAsalNama = controller.siswaPerKelas.keys.elementAt(index);
        List<KenaikanSiswaModel> daftarSiswa = controller.siswaPerKelas[kelasAsalNama]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text("Kelas $kelasAsalNama", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${daftarSiswa.length} Siswa"),
            initiallyExpanded: true,
            children: [
              _buildBulkAction(kelasAsalNama),
              const Divider(height: 1),
              ...daftarSiswa.map((siswa) => _buildSiswaTile(siswa)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBulkAction(String kelasAsal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          const Expanded(child: Text("Terapkan untuk semua:", style: TextStyle(fontSize: 12))),
          SizedBox(
            width: 150,
            child: DropdownButton<String>(
              isDense: true,
              hint: const Text("Pilih Aksi...", style: TextStyle(fontSize: 12)),
              onChanged: (value) {
                if(value != null) controller.updateStatusSatuKelas(kelasAsal, value);
              },
              items: controller.pilihanKelasBaru.map((pilihan) {
                return DropdownMenuItem<String>(value: pilihan['id'], child: Text(pilihan['nama']!, style: const TextStyle(fontSize: 12)));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiswaTile(KenaikanSiswaModel siswa) {
    return Obx(() => ListTile(
      title: Text(siswa.nama),
      subtitle: Text("NISN: ${siswa.nisn}"), // Tambahkan NISN di subtitle
      trailing: SizedBox(
        width: 150,
        child: DropdownButton<String>(
          value: siswa.targetKelasId,
          isExpanded: true,
          items: controller.pilihanKelasBaru.map((pilihan) {
            final isTinggal = pilihan['id'] == siswa.kelasAsalId;
            String namaTampilan = pilihan['nama']!;
            if (isTinggal) namaTampilan = "Tinggal di ${siswa.kelasAsalNama}";
            
            return DropdownMenuItem<String>(
              value: pilihan['id'],
              child: Text(namaTampilan, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            if(value != null) controller.updateStatusSiswa(siswa.uid, siswa.kelasAsalNama, value);
          },
        ),
      ),
    ));
  }
}