import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_bk_controller.dart';

class DashboardBkView extends GetView<DashboardBkController> {
  const DashboardBkView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.title.value)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Panel Kontrol (Dropdown, Search, Filter)
          _buildControlPanel(),

          // Garis pemisah
          const Divider(height: 1),

          // Daftar Siswa
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              // [DIUBAH] Gunakan getter filteredSiswaList
              if (controller.filteredSiswaList.isEmpty) {
                return const Center(child: Text('Data siswa tidak ditemukan.'));
              }
              return ListView.builder(
                // [DIUBAH] Gunakan getter filteredSiswaList
                itemCount: controller.filteredSiswaList.length,
                itemBuilder: (context, index) {
                  // [DIUBAH] Gunakan getter filteredSiswaList
                  final siswa = controller.filteredSiswaList[index];
                  final hasNote = controller.siswaDenganCatatan.contains(siswa.uid);
                  
                  return Card(
                    elevation: hasNote ? 4 : 2,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: hasNote 
                        ? BorderSide(color: Colors.amber.shade700, width: 1.5) 
                        : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(radius: 25, child: Text(siswa.namaLengkap[0])),
                      title: Text(siswa.namaLengkap, style: TextStyle(fontWeight: hasNote ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text("NISN: ${siswa.nisn}"),
                      trailing: hasNote 
                        ? Badge(
                            label: const Icon(Icons.star, size: 12, color: Colors.white),
                            backgroundColor: Colors.amber.shade800,
                            child: const Icon(Icons.chevron_right),
                          )
                        : const Icon(Icons.chevron_right),
                      onTap: () => controller.goToCatatanSiswa(siswa),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- [WIDGET BARU] Untuk semua panel kontrol ---
  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => Column(
        children: [
          // Dropdown hanya untuk Kepsek & Kesiswaan
          if (controller.canSelectClass.value) ...[
            DropdownButtonFormField<String>(
              value: controller.selectedKelasId.value,
              items: controller.daftarKelas.map((kelas) {
                return DropdownMenuItem(value: kelas['id'], child: Text(kelas['nama']!));
              }).toList(),
              onChanged: (value) {
                if (value != null) controller.selectedKelasId.value = value;
              },
              decoration: const InputDecoration(labelText: 'Pilih Kelas', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
          ],
          
          // TextField untuk Pencarian
          TextField(
            controller: controller.searchC,
            onChanged: (value) => controller.searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Cari nama atau NISN...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          // Switch Filter hanya untuk Kepsek & Kesiswaan
          if (controller.canSelectClass.value) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Hanya tampilkan siswa dengan catatan'),
              value: controller.showOnlyWithNotes.value,
              onChanged: (value) {
                controller.showOnlyWithNotes.value = value;
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      )),
    );
  }
}