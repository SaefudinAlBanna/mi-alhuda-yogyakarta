// lib/app/modules/manajemen_komite/views/manajemen_komite_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/models/komite_anggota_model.dart';
import '../controllers/manajemen_komite_controller.dart';

class ManajemenKomiteView extends GetView<ManajemenKomiteController> {
  const ManajemenKomiteView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Komite'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!controller.canManageSekolah.value && !controller.canManageKelas.value && !controller.isKetuaKomiteSekolah.value) {
          return const Center(child: Text("Anda tidak memiliki akses ke halaman ini."));
        }
        return RefreshIndicator(
          onRefresh: controller.fetchData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.canManageSekolah.value || controller.isKetuaKomiteSekolah.value)
                _buildKomiteSekolahCard(),
              
              if ((controller.canManageSekolah.value || controller.isKetuaKomiteSekolah.value) && controller.canManageKelas.value)
                const SizedBox(height: 24),
              
              if (controller.canManageKelas.value)
                _buildKomiteKelasCard(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildKomiteSekolahCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Komite Sekolah", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Obx(() {
              if (controller.anggotaKomiteSekolah.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Belum ada anggota komite sekolah."),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.anggotaKomiteSekolah.length,
                itemBuilder: (context, index) {
                  final anggota = controller.anggotaKomiteSekolah[index];
                  return _buildAnggotaTile(anggota);
                },
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.canManageSekolah.value && !controller.ketuaKomiteSudahAda) {
                return ElevatedButton.icon(
                  onPressed: () => controller.tambahAnggota('sekolah', 'Ketua Komite Sekolah'),
                  icon: const Icon(Icons.add),
                  label: const Text("Tunjuk Ketua Komite"),
                );
              }
              if (controller.isKetuaKomiteSekolah.value) {
                return ElevatedButton.icon(
                  onPressed: () => controller.tambahAnggota('sekolah', 'Anggota'),
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Anggota"),
                );
              }
              return const SizedBox.shrink();
            })
          ],
        ),
      ),
    );
  }

  Widget _buildKomiteKelasCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Komite Kelas ${controller.kelasDiampuId.value?.split('-').first ?? ''}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Obx(() {
              if (controller.anggotaKomiteKelas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Belum ada anggota komite kelas."),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.anggotaKomiteKelas.length,
                itemBuilder: (context, index) {
                  final anggota = controller.anggotaKomiteKelas[index];
                  return _buildAnggotaTile(anggota);
                },
              );
            }),
            const SizedBox(height: 16),
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  final namaKelas = controller.kelasDiampuId.value!.split('-').first;
                  controller.tambahAnggota(namaKelas, 'Bendahara Kelas');
                },
                child: const Text("Tunjuk Bendahara"),
              ),
              ElevatedButton(
                onPressed: () {
                  final namaKelas = controller.kelasDiampuId.value!.split('-').first;
                  controller.tambahAnggota(namaKelas, 'PJ AGIS');
                },
                child: const Text("Tunjuk PJ AGIS"),
              ),
            ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnggotaTile(KomiteAnggotaModel anggota) {
    bool canDelete = controller.canManageSekolah.value || 
                     controller.isKetuaKomiteSekolah.value ||
                     (controller.canManageKelas.value && anggota.komiteId != 'sekolah');

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(anggota.namaSiswa),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(anggota.jabatan, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (anggota.namaOrangTua != null)
            Text(anggota.namaOrangTua!),
        ],
      ),
      trailing: canDelete ? IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => controller.hapusAnggota(anggota),
      ) : null,
    );
  }
}