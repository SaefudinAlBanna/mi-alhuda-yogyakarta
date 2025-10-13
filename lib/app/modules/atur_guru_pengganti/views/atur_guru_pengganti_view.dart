// lib/app/modules/atur_guru_pengganti/views/atur_guru_pengganti_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/atur_guru_pengganti_controller.dart';

class AturGuruPenggantiView extends GetView<AturGuruPenggantiController> {
  const AturGuruPenggantiView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Guru Pengganti'),
      ),
      body: Column(
        children: [
          // Filter Tanggal
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text("Pilih Tanggal"),
            subtitle: Obx(() => Text(
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(controller.selectedDate.value),
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
            onTap: () => controller.pickDate(context),
          ),
          const Divider(height: 1),

          // Daftar Jadwal
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.jadwalHariIni.isEmpty) {
                return const Center(child: Text("Tidak ada jadwal pelajaran pada tanggal ini."));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: controller.jadwalHariIni.length,
                itemBuilder: (context, index) {
                  final sesi = controller.jadwalHariIni[index];
                  return Card(
                    // --- [PERBAIKAN UX] Beri warna berbeda jika sudah ada pengganti ---
                    color: sesi.namaGuruPengganti != null ? Colors.blue.shade50 : null,
                    child: ListTile(
                      title: Text("${sesi.namaMapel} - ${sesi.idKelas.split('-').first}"),
                      subtitle: Text("Jam ke ${sesi.jamKe} - ${sesi.namaGuru}"),

                      // --- [MODIFIKASI UTAMA PADA TRAILING] ---
                      trailing: sesi.namaGuruPengganti != null
                        ?
                        // JIKA SUDAH ADA PENGGANTI: Tampilkan Info & Tombol Batal
                        Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("Digantikan oleh:", style: TextStyle(fontSize: 10)),
                                  Text(
                                    sesi.namaGuruPengganti!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.cancel_outlined, color: Colors.red.shade400),
                                onPressed: () => controller.batalkanPengganti(sesi),
                                tooltip: "Batalkan Pengganti",
                              ),
                            ],
                          )
                        :
                        // JIKA BELUM ADA PENGGANTI: Tampilkan Tombol "Ganti"
                        ElevatedButton(
                            child: const Text("Ganti"),
                            onPressed: () => controller.openGantiGuruDialog(sesi),
                          ),
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
}