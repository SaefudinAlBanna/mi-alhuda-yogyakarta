import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi locale

import '../controllers/buat_sarpras_controller.dart';

class BuatSarprasView extends GetView<BuatSarprasController> {
  const BuatSarprasView({super.key});

  @override
  Widget build(BuildContext context) {
  //   // Inisialisasi locale 'id_ID' untuk DateFormat
  //   initializeDateFormatting('id_ID', null);

    return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Input Data Sarpras'),
  //       centerTitle: true,
  //     ),
  //     body: SingleChildScrollView(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Form(
  //         key: controller.formKey,
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: <Widget>[
  //             _buildTextField(
  //               controller: controller.namaBarangC,
  //               labelText: 'Nama Barang/Sarana',
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Nama barang tidak boleh kosong';
  //                 }
  //                 return null;
  //               },
  //             ),
  //             const SizedBox(height: 16),
  //             _buildTextField(
  //               controller: controller.jumlahC,
  //               labelText: 'Jumlah',
  //               keyboardType: TextInputType.number,
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Jumlah tidak boleh kosong';
  //                 }
  //                 if (int.tryParse(value) == null) {
  //                   return 'Masukkan angka yang valid';
  //                 }
  //                 if (int.parse(value) <= 0) {
  //                   return 'Jumlah harus lebih dari 0';
  //                 }
  //                 return null;
  //               },
  //             ),
  //             const SizedBox(height: 16),
  //             Obx(() => DropdownButtonFormField<String>(
  //                   decoration: const InputDecoration(
  //                     labelText: 'Kondisi',
  //                     border: OutlineInputBorder(),
  //                   ),
  //                   value: controller.selectedKondisi.value,
  //                   items: controller.kondisiOptions
  //                       .map((String kondisi) => DropdownMenuItem<String>(
  //                             value: kondisi,
  //                             child: Text(kondisi),
  //                           ))
  //                       .toList(),
  //                   onChanged: controller.setSelectedKondisi,
  //                   validator: (value) =>
  //                       value == null ? 'Kondisi harus dipilih' : null,
  //                 )),
  //             const SizedBox(height: 16),
  //             _buildTextField(
  //               controller: controller.lokasiC,
  //               labelText: 'Lokasi/Ruangan',
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Lokasi tidak boleh kosong';
  //                 }
  //                 return null;
  //               },
  //             ),
  //             const SizedBox(height: 16),
  //             TextFormField(
  //               controller: controller.tanggalPengadaanC,
  //               decoration: const InputDecoration(
  //                 labelText: 'Tanggal Pengadaan (Opsional)',
  //                 border: OutlineInputBorder(),
  //                 suffixIcon: Icon(Icons.calendar_today),
  //               ),
  //               readOnly: true, // Agar tidak bisa diketik manual
  //               onTap: () => controller.pilihTanggal(context),
  //             ),
  //             const SizedBox(height: 16),
  //             _buildTextField(
  //               controller: controller.keteranganC,
  //               labelText: 'Keterangan (Opsional)',
  //               maxLines: 3,
  //               // Tidak ada validator karena opsional
  //             ),
  //             const SizedBox(height: 32),
  //             Obx(() => ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     padding: const EdgeInsets.symmetric(vertical: 16),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                   ),
  //                   onPressed: controller.isLoading.value
  //                       ? null // Disable button saat loading
  //                       : () => controller.simpanSarpras(),
  //                   child: controller.isLoading.value
  //                       ? const SizedBox(
  //                           width: 20,
  //                           height: 20,
  //                           child: CircularProgressIndicator(
  //                             color: Colors.white,
  //                             strokeWidth: 2.0,
  //                           ),
  //                         )
  //                       : const Text('Simpan Data Sarpras'),
  //                 )),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildTextField({
  //   required TextEditingController controller,
  //   required String labelText,
  //   TextInputType keyboardType = TextInputType.text,
  //   int maxLines = 1,
  //   String? Function(String?)? validator,
  // }) {
  //   return TextFormField(
  //     controller: controller,
  //     decoration: InputDecoration(
  //       labelText: labelText,
  //       border: const OutlineInputBorder(),
  //       alignLabelWithHint: maxLines > 1,
  //     ),
  //     keyboardType: keyboardType,
  //     maxLines: maxLines,
  //     validator: validator,
    );
  }
}