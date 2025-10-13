import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/halaqah_setoran_ummi_model.dart';
import '../controllers/halaqah_ummi_riwayat_pengampu_controller.dart';

class HalaqahUmmiRiwayatPengampuView extends GetView<HalaqahUmmiRiwayatPengampuController> {
  const HalaqahUmmiRiwayatPengampuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat: ${controller.siswa.nama}"),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamRiwayatSetoran(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada riwayat setoran."));
          }
          final riwayatList = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: riwayatList.length,
            itemBuilder: (context, index) {
              final setoran = HalaqahSetoranUmmiModel.fromFirestore(riwayatList[index]);
              return _buildRiwayatItem(setoran);
            },
          );
        },
      ),
    );
  }

  Widget _buildRiwayatItem(HalaqahSetoranUmmiModel setoran) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(setoran.penilaian.status),
          child: Text(
            setoran.penilaian.nilaiHuruf,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(setoran.tanggalSetor)),
        subtitle: Text("Materi: ${setoran.materi.tingkat} ${setoran.materi.detailTingkat} Hal ${setoran.materi.halaman}"),
        trailing: Text(
          setoran.penilaian.status,
          style: TextStyle(color: _getStatusColor(setoran.penilaian.status), fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Nilai Angka", setoran.penilaian.nilaiAngka.toString()),
                _buildDetailRow("Dinilai oleh", setoran.namaPenilai),
                _buildDetailRow("Lokasi", setoran.lokasiAktual),
                const Divider(),
                _buildCatatanSection("Catatan Pengampu", setoran.catatanPengampu, Icons.school),
                const SizedBox(height: 16),
                _buildCatatanSection("Tanggapan Orang Tua", setoran.catatanOrangTua, Icons.family_restroom),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit"),
                      onPressed: () => controller.editPenilaian(setoran),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text("Hapus"),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => controller.hapusPenilaian(setoran),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCatatanSection(String title, String content, IconData icon, {VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (onTap != null)
              IconButton(icon: Icon(Icons.edit, color: Get.theme.primaryColor), onPressed: onTap)
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content.isNotEmpty ? content : "Tidak ada catatan.",
            style: TextStyle(fontStyle: content.isNotEmpty ? FontStyle.normal : FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Lancar':
        return Colors.green.shade700;
      case 'Perlu Perbaikan':
        return Colors.orange.shade800;
      case 'Mengulang':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }
}