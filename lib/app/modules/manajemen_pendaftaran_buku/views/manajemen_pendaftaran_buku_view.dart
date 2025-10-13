import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/manajemen_pendaftaran_buku_controller.dart';

class ManajemenPendaftaranBukuView extends GetView<ManajemenPendaftaranBukuController> {
  const ManajemenPendaftaranBukuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pendaftaran Buku'),
        centerTitle: true,
        actions: [
          Obx(() {
            // Hanya tampilkan tombol jika pendaftaran aktif
            if (controller.pendaftaranAktif.value == null) return const SizedBox.shrink();
            return controller.isProcessingPdf.value
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.print_outlined),
                  onPressed: controller.exportPdf,
                  tooltip: "Cetak Rekap Pendaftar",
                );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // Jika pendaftaran aktif ada, tampilkan dashboard. Jika tidak, tampilkan form.
        return controller.pendaftaranAktif.value != null
            ? _buildDashboardPendaftaranAktif(context)
            : _buildFormBukaPendaftaran(context);
      }),
    );
  }

  Widget _buildFormBukaPendaftaran(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Saat ini tidak ada periode pendaftaran buku yang aktif. Silakan buka pendaftaran baru di bawah ini.", textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextField(controller: controller.judulC, 
        decoration: const InputDecoration(labelText: "Judul Pendaftaran", 
        border: OutlineInputBorder())),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => controller.pickDateRange(context),
          icon: const Icon(Icons.calendar_month),
          label: Obx(() => Text(
            (controller.tanggalBuka.value == null || controller.tanggalTutup.value == null)
              ? "Pilih Tanggal Buka & Tutup"
              : "${DateFormat('dd MMM yyyy').format(controller.tanggalBuka.value!)} - ${DateFormat('dd MMM yyyy').format(controller.tanggalTutup.value!)}",
          )),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 24),
        Obx(() => ElevatedButton.icon(
          onPressed: controller.isSaving.value ? null : controller.bukaPendaftaran,
          icon: const Icon(Icons.play_circle_fill_rounded),
          label: const Text("Buka Pendaftaran Sekarang"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        )),
      ],
    );
  }

  // Widget untuk menampilkan dashboard saat pendaftaran sedang aktif/dibuka
  Widget _buildDashboardPendaftaranAktif(BuildContext context) {
    final data = controller.pendaftaranAktif.value!.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("PENDAFTARAN BUKU SEDANG DIBUKA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(data['judul'], style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text("Berakhir pada: ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format((data['tanggalTutup'] as Timestamp).toDate())}"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Rekap Pendaftar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildFilterKelas(), // Dropdown filter kelas
            ],
          ),
          const Divider(),
          Expanded(
            child: Obx(() {
              if (controller.daftarBukuDitawarkan.isEmpty) {
                return const Center(child: Text("Belum ada buku yang ditawarkan."));
              }
              return ListView.builder(
                itemCount: controller.daftarBukuDitawarkan.length,
                itemBuilder: (context, index) {
                  final buku = controller.daftarBukuDitawarkan[index];
                  final pendaftar = controller.pendaftarPerBuku[buku.id] ?? [];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text(buku.namaItem, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Chip(
                        label: Text("${pendaftar.length} Pendaftar"),
                        backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
                      ),
                      children: pendaftar.isEmpty
                          ? [const ListTile(title: Text("Belum ada pendaftar.", style: TextStyle(fontStyle: FontStyle.italic)))]
                          : pendaftar.map((p) => ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(p['nama']),
                              subtitle: Text(p['kelas'].split('-').first),
                            )).toList(),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Obx(() => ElevatedButton.icon(
            onPressed: controller.isSaving.value ? null : controller.tutupPendaftaran,
            icon: controller.isSaving.value
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.stop_circle_rounded),
            label: const Text("Tutup Periode Pendaftaran"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )),
        ],
      ),
    );
  }

  // Widget untuk dropdown filter kelas
  Widget _buildFilterKelas() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.kelasTerpilih.value,
          items: controller.daftarKelasFilter.map((kelas) => DropdownMenuItem(
            value: kelas,
            child: Text(kelas),
          )).toList(),
          onChanged: (value) {
            if (value != null) controller.kelasTerpilih.value = value;
          },
        ),
      ),
    ));
  }
}