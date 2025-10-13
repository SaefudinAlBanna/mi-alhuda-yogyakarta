import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/pengaturan_biaya_controller.dart';

class PengaturanBiayaView extends GetView<PengaturanBiayaController> {
  const PengaturanBiayaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Biaya Tahunan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Get.toNamed(Routes.PENGATURAN_ALASAN_KEUANGAN),
            tooltip: "Alasan Perubahan",
          ),
        ],
      ),
      body: Obx(() {
        if (!controller.isAuthorized.value) {
          return const Center(child: Text("Anda tidak memiliki izin.", style: TextStyle(color: Colors.red)));
        }
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildForm();
      }),
      floatingActionButton: Obx(() => controller.isAuthorized.value
          ? FloatingActionButton.extended(
              onPressed: controller.isSaving.value ? null : controller.simpanMasterBiaya,
              icon: controller.isSaving.value ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text("Simpan Biaya Umum"),
            )
          : const SizedBox.shrink()),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text("Atur nominal default untuk biaya tahunan. Biaya SPP diatur pada profil masing-masing siswa."),
        ),
        const Divider(),
        _buildTextField(
          controller: controller.daftarUlangC,
          label: "Biaya Daftar Ulang",
          icon: Icons.app_registration,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.uangKegiatanC,
          label: "Biaya Uang Kegiatan",
          icon: Icons.celebration,
        ),
        const Divider(height: 32),
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.foundation),
            title: const Text("Pengaturan Uang Pangkal"),
            subtitle: const Text("Atur nominal uang pangkal untuk setiap siswa baru (Kelas 1)."),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: _showUangPangkalModal,
          ),
        ),
      ],
    );
  }

  void _showUangPangkalModal() {
    Get.dialog(
      AlertDialog(
        title: const Text("Atur Uang Pangkal Siswa Kelas 1"),
        content: SizedBox(
          width: Get.width * 0.9,
          height: Get.height * 0.6,
          child: Obx(() {
            if (controller.daftarSiswaKelas1.isEmpty) {
              return const Center(child: Text("Tidak ada siswa kelas 1 ditemukan."));
            }
            return ListView.separated(
              itemCount: controller.daftarSiswaKelas1.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final siswa = controller.daftarSiswaKelas1[index];
                return Row(
                  children: [
                    Expanded(child: Text(siswa.namaLengkap, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        controller: controller.uangPangkalControllers[siswa.uid],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(prefixText: "Rp ", border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          Obx(() => ElevatedButton(
            onPressed: controller.isSavingUangPangkal.value ? null : controller.simpanUangPangkalSiswa,
            child: controller.isSavingUangPangkal.value ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Simpan Uang Pangkal"),
          )),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: "Rp ",
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}