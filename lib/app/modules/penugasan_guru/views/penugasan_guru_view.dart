// lib/app/modules/penugasan_guru/views/penugasan_guru_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/penugasan_guru_controller.dart';

class PenugasanGuruView extends GetView<PenugasanGuruController> {
  const PenugasanGuruView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.kelasTerpilih.value == null ? 'Atur Guru Mapel' : 'Atur Mapel Kelas ${controller.kelasTerpilih.value!['namaKelas']}')),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        return Column(
          children: [ _buildKelasSelector(), const Divider(height: 1), Expanded(child: _buildMapelList())],
        );
      }),
    );
  }

  Widget _buildKelasSelector() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 2))]
      ),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.daftarKelas.length,
          itemBuilder: (context, index) {
            final kelasDoc = controller.daftarKelas[index];
            final namaKelas = (controller.daftarKelas[index].data() as Map<String, dynamic>)['namaKelas'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Obx(() {
                final isSelected = controller.kelasTerpilih.value?.id == kelasDoc.id;
                // -----------------------------------------------------------------
                return ChoiceChip(
                  label: Text(namaKelas),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.gantiKelasTerpilih(kelasDoc);
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapelList() {
    return Obx(() {
      if (controller.kelasTerpilih.value == null) return const Center(child: Text("Silakan pilih kelas di atas."));
      if (controller.isLoadingMapel.value) return const Center(child: CircularProgressIndicator());
      if (controller.daftarMapel.isEmpty) return const Center(child: Text("Kurikulum untuk fase ini belum diatur."));

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.getAssignedMapelStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          // --- [PERBAIKAN KRUSIAL] ---
          // Sekarang kita mengambil 'aliasGuru' dengan fallback ke 'namaGuru'
          final assignedMapelData = { 
            for (var doc in snapshot.data?.docs ?? []) 
              doc.id: doc.data()['aliasGuru'] ?? doc.data()['namaGuru']
          };
          // --- AKHIR PERBAIKAN ---

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: controller.daftarMapel.length,
            itemBuilder: (context, index) {
              final mapel = controller.daftarMapel[index];
              final mapelId = mapel['idMapel'];
              final guruDitugaskan = assignedMapelData[mapelId];

              return Card(
               margin: const EdgeInsets.only(bottom: 12.0),
               child: ListTile(
                title: Text(mapel['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  // --- [PERBAIKAN UI] Tampilkan nama guru (alias) secara langsung ---
                  subtitle: Text(
                    guruDitugaskan ?? 'Belum ada guru', // Simpel dan bersih
                    style: TextStyle(color: guruDitugaskan != null ? Colors.indigo : Colors.grey)
                  ),
                  // ------------------------------------------------------------------
                    trailing: guruDitugaskan != null 
                    ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => controller.removeGuruFromMapel(mapelId))
                    : ElevatedButton(child: const Text('Atur Guru'), onPressed: () => _showGuruSelectionDialog(mapel)),
                ),
              );
            },
          );
        },
      );
    });
  }

  
  void _showGuruSelectionDialog(Map<String, dynamic> mapel) {
    // Reset state setiap kali dialog dibuka
    controller.guruTerpilihSementara.value = null;
  
    Get.defaultDialog(
      title: 'Pilih Guru untuk ${mapel['nama']}',
      content: SizedBox(
        width: Get.width * 0.8,
        child: DropdownSearch<Map<String, dynamic>>(
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: "Cari guru..."))
          ),
          items: (f, cs) => controller.daftarGuru,
          itemAsString: (guru) => guru['alias'],
          compareFn: (item1, item2) => item1['uid'] == item2['uid'],
          
          // onChanged HANYA MENGUBAH STATE, TIDAK MENUTUP DIALOG
          onChanged: (guru) {
            controller.guruTerpilihSementara.value = guru;
          },
        ),
      ),
      // --- TOMBOL AKSI YANG TERPISAH ---
      cancel: OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
      confirm: Obx(() => ElevatedButton(
        // Tombol hanya aktif jika seorang guru sudah dipilih
        onPressed: controller.guruTerpilihSementara.value == null
            ? null
            : () {
                // Aksi simpan dan tutup dialog ada di sini
                final guruDipilih = controller.guruTerpilihSementara.value!;
                Get.back();
                controller.assignGuruToMapel(guruDipilih, mapel);
              },
        child: const Text('Tugaskan'),
      )),
    );
  }
}