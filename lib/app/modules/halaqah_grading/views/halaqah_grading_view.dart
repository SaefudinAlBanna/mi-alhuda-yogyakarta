// lib/app/modules/halaqah_grading/views/halaqah_grading_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/models/siswa_simple_model.dart';

import '../controllers/halaqah_grading_controller.dart';

class HalaqahGradingView extends GetView<HalaqahGradingController> {
  const HalaqahGradingView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.group.namaGrup),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SiswaSimpleModel>>(
        future: controller.listAnggotaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Belum ada anggota di dalam grup ini."),
            );
          }

          final anggotaList = snapshot.data!;
          
          // Lakukan pengurutan di sini, di dalam builder
          anggotaList.sort((a, b) {
            final waktuA = controller.antrianMap[a.uid];
            final waktuB = controller.antrianMap[b.uid];
            if (waktuA != null && waktuB != null) return waktuA.compareTo(waktuB); // Urutkan berdasarkan waktu
            if (waktuA != null) return -1; // Siswa yang sudah antri selalu di atas
            if (waktuB != null) return 1;
            return a.nama.compareTo(b.nama); // Jika sama-sama belum, urutkan nama
          });

          // Buat list entri antrian yang sudah diurutkan untuk menentukan nomor
          final sortedAntrian = controller.antrianMap.entries.toList()
              ..sort((a, b) => a.value.compareTo(b.value));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: anggotaList.length,
            itemBuilder: (context, index) {
              final anggota = anggotaList[index];
              final antrianData = sortedAntrian.indexWhere((e) => e.key == anggota.uid);
              final urutan = antrianData != -1 ? antrianData + 1 : null;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  onTap: () => controller.goToRiwayatSiswa(anggota),
                  leading: CircleAvatar(
                    radius: 25,
                    child: urutan != null
                        ? Text(urutan.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
                        : Text(anggota.nama.isNotEmpty ? anggota.nama[0] : '-'),
                  ),
                  title: Text(anggota.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Kelas Asal: ${anggota.kelasId}"),
                  trailing: ElevatedButton.icon(
                    onPressed: () => controller.goToSetoranPage(anggota),
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text("Setoran"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}