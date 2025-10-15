// lib/app/modules/halaqah_riwayat_pengampu/views/halaqah_riwayat_pengampu_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Pastikan package intl sudah ada
import 'package:mi_alhuda_yogyakarta/app/models/halaqah_setoran_model.dart';
import '../controllers/halaqah_riwayat_pengampu_controller.dart';

class HalaqahRiwayatPengampuView extends GetView<HalaqahRiwayatPengampuController> {
  const HalaqahRiwayatPengampuView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat: ${controller.siswa.nama}"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamRiwayat(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text(
              "Belum ada riwayat setoran untuk siswa ini.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ));
          }
          final riwayatList = snapshot.data!.docs;

          // Gunakan ListView.builder dengan itemCount + 1 untuk header
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: riwayatList.length + 1, // +1 untuk Card ringkasan
            itemBuilder: (context, index) {
              // Item pertama (index 0) adalah Card ringkasan
              if (index == 0) {
                return _buildSummaryCard(riwayatList.length);
              }

              // Item selanjutnya adalah data riwayat
              final setoran = HalaqahSetoranModel.fromFirestore(riwayatList[index - 1]);
              final setoranNumber = riwayatList.length - (index - 1);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  // --- Header ExpansionTile ---
                  leading: CircleAvatar(
                    child: Text(setoranNumber.toString()),
                  ),
                  title: Text(
                    "Setoran ${DateFormat('dd MMMM yyyy').format(setoran.tanggalTugas.toDate())}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    setoran.status,
                    style: TextStyle(
                      color: _getStatusColor(setoran.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // --- Konten ExpansionTile (Saat Dibuka) ---
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Detail Tugas", style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildDetailRow("Sabak/Terbaru", setoran.tugas['sabak']),
                          _buildDetailRow("Sabqi", setoran.tugas['sabqi']),
                          _buildDetailRow("Manzil", setoran.tugas['manzil']),
                          _buildDetailRow("Tambahan", setoran.tugas['tambahan']),
                          const Divider(height: 24),
                          const Text("Hasil Penilaian", style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildDetailRow("Nilai Sabak", setoran.nilai['sabak']),
                          _buildDetailRow("Nilai Sabqi", setoran.nilai['sabqi']),
                          _buildDetailRow("Nilai Manzil", setoran.nilai['manzil']),
                          _buildDetailRow("Nilai Tambahan", setoran.nilai['tambahan']),
                          const Divider(height: 24),
                          const Text("Catatan", style: TextStyle(fontWeight: FontWeight.bold)),
                          // _buildDetailRow("Pengampu", setoran.catatanPengampu),
                          _buildCatatanPengampuSection(setoran),
                          //---------------------- >> tambahan
                          const SizedBox(height: 5),
                          const Text("Catatan", style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildDetailRow("Orangtua", setoran.catatanOrangTua),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }


  // --- Widget Helper ---

   Widget _buildCatatanPengampuSection(HalaqahSetoranModel setoran) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Catatan Pengampu", style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
              tooltip: "Edit Catatan",
              onPressed: () => controller.editCatatanPengampu(setoran.id, setoran.catatanPengampu),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: Text(
            setoran.catatanPengampu.isNotEmpty ? setoran.catatanPengampu : "Belum ada catatan.",
            style: TextStyle(
              fontStyle: setoran.catatanPengampu.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              color: setoran.catatanPengampu.isNotEmpty ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int total) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListTile(
        leading: const Icon(Icons.history_edu_rounded),
        title: const Text("Total Riwayat Setoran", style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          total.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Sudah Dinilai') return Colors.green.shade700;
    if (status == 'Tugas Diberikan') return Colors.orange.shade800;
    return Colors.grey;
  }

  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title:", style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              (value != null && value.isNotEmpty) ? value : "-",
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}