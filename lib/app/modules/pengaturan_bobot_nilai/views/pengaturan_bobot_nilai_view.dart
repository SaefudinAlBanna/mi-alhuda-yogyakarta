import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pengaturan_bobot_nilai_controller.dart';

class PengaturanBobotNilaiView extends GetView<PengaturanBobotNilaiController> {
  const PengaturanBobotNilaiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Bobot Nilai')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!controller.isAuthorized.value) {
          return const Center(
            child: Text("Anda tidak memiliki izin untuk mengakses halaman ini.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
          );
        }
        return _buildBody();
      }),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildBobotSlider(
                label: "Tugas Harian / PR",
                value: controller.bobotTugasHarian,
              ),
              _buildBobotSlider(
                label: "Ulangan Harian",
                value: controller.bobotUlanganHarian,
              ),
              _buildBobotSlider(
                label: "Nilai Tambahan",
                value: controller.bobotNilaiTambahan,
              ),
              _buildBobotSlider(
                label: "Penilaian Tengah Semester (PTS)",
                value: controller.bobotPts,
              ),
              _buildBobotSlider(
                label: "Penilaian Akhir Semester (PAS)",
                value: controller.bobotPas,
              ),
            ],
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildBobotSlider({required String label, required RxDouble value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Obx(() => Text('${value.value.toInt()}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo))),
            ],
          ),
          Obx(() => Slider(
                value: value.value,
                min: 0,
                max: 100,
                divisions: 20, // step 5%
                label: '${value.value.toInt()}%',
                onChanged: (newValue) => value.value = newValue,
              )),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, spreadRadius: 1)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final total = controller.totalBobot.round();
            final isTotalValid = total == 100;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Bobot:", style: TextStyle(fontSize: 16)),
                Text(
                  '$total%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isTotalValid ? Colors.green.shade700 : Colors.red,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final isTotalValid = controller.totalBobot.round() == 100;
            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isTotalValid ? Colors.indigo.shade300 : Colors.grey,
              ),
              onPressed: (controller.isSaving.value || !isTotalValid) ? null : controller.simpanBobot,
              icon: controller.isSaving.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                  : const Icon(Icons.save_rounded),
              label: Text(controller.isSaving.value ? 'MENYIMPAN...' : 'SIMPAN PENGATURAN'),
            );
          }),
        ],
      ),
    );
  }
}