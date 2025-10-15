import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mi_alhuda_yogyakarta/app/models/pegawai_simple_model.dart';
import '../controllers/atur_penggantian_rentang_controller.dart';

class AturPenggantianRentangView extends GetView<AturPenggantianRentangController> {
  const AturPenggantianRentangView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildGuruDropdown(isAsli: true),
            const SizedBox(height: 16),
            _buildGuruDropdown(isAsli: false),
            const SizedBox(height: 24),
            _buildDatePicker(context, isMulai: true),
            const SizedBox(height: 16),
            _buildDatePicker(context, isMulai: false),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: controller.isSaving.value 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Icon(Icons.save),
              label: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Penugasan"),
              onPressed: controller.isSaving.value ? null : controller.simpanPenugasan,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildGuruDropdown({required bool isAsli}) {
    return Obx(() => DropdownButtonFormField<PegawaiSimpleModel>(
      value: isAsli ? controller.guruAsli.value : controller.guruPengganti.value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isAsli ? "Pilih Guru yang Digantikan" : "Pilih Guru Pengganti",
        border: const OutlineInputBorder(),
      ),
      items: controller.daftarGuru.map((p) => DropdownMenuItem(
        value: p,
        child: Text(p.displayName, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (value) {
        if (isAsli) {
          controller.guruAsli.value = value;
        } else {
          controller.guruPengganti.value = value;
        }
      },
    ));
  }

  Widget _buildDatePicker(BuildContext context, {required bool isMulai}) {
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: Text(isMulai ? "Tanggal Mulai" : "Tanggal Selesai"),
      subtitle: Obx(() => Text(
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(
            isMulai ? controller.tanggalMulai.value : controller.tanggalSelesai.value),
        style: const TextStyle(fontWeight: FontWeight.bold),
      )),
      onTap: () => controller.pickDate(context, isMulai: isMulai),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}