import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/halaqah_ummi_jadwal_penguji_controller.dart';

class HalaqahUmmiJadwalPengujiView extends GetView<HalaqahUmmiJadwalPengujiController> {
  const HalaqahUmmiJadwalPengujiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jadwal Munaqosyah Saya")),
      body: StreamBuilder<List<UjianSiswaModel>>(
        stream: controller.streamJadwalUjianSaya(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada jadwal ujian untuk Anda saat ini."));
          }
          final jadwalList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jadwalList.length,
            itemBuilder: (context, index) {
              final ujianSiswa = jadwalList[index];
              return Card(
                child: ListTile(
                  title: Text(ujianSiswa.siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Ujian: ${ujianSiswa.ujian.materiUjian}\nTanggal: ${DateFormat('dd MMM yyyy').format(ujianSiswa.ujian.tanggalUjian)}"),
                  trailing: ElevatedButton(
                    child: const Text("Nilai"),
                    onPressed: () => controller.openGradingSheet(ujianSiswa),
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