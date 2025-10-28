import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';

// Import View untuk mengakses Dialog Form
import '../views/manajemen_dashboard_view.dart';

class ManajemenDashboardController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> menuGroups = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> menuItems = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardConfig();
  }

  void loadDashboardConfig() {
    isLoading.value = true;
    try {
      final config = configC.konfigurasiDashboard;
      final groups = List<Map<String, dynamic>>.from(config['menu_groups'] ?? []);
      // Urutkan grup berdasarkan 'order' saat memuat
      groups.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      menuGroups.assignAll(groups);
      menuItems.assignAll(Map<String, dynamic>.from(config['menu_items'] ?? {}));
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat konfigurasi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveConfiguration() async {
    isLoading.value = true;
    try {
      final ref = _firestore
          .collection('Sekolah')
          .doc(configC.idSekolah)
          .collection('pengaturan')
          .doc('konfigurasi_dashboard');

      await ref.set(
        {
          'menu_groups': menuGroups.toList(),
          'menu_items': Map<String, dynamic>.from(menuItems), // PERBAIKAN DI SINI
        },
        SetOptions(merge: true),
      );
      
      await configC.reloadKonfigurasiDashboard();
      
      Get.back(); // Kembali ke halaman dashboard
      Get.snackbar('Berhasil', 'Konfigurasi dashboard berhasil disimpan.');

    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan konfigurasi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // --- CRUD UNTUK GRUP MENU ---

  void showGroupForm({Map<String, dynamic>? initialData}) {
    Get.dialog(
      GroupFormDialog(
        initialData: initialData,
        onSave: (groupData) {
          if (initialData == null) { // Mode Tambah
            menuGroups.add(groupData);
          } else { // Mode Edit
            int index = menuGroups.indexWhere((g) => g['groupId'] == initialData['groupId']);
            if (index != -1) {
              menuGroups[index] = groupData;
            }
          }
          // Urutkan kembali setelah ada perubahan
          menuGroups.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
          Get.back();
        },
      ),
    );
  }

  void deleteGroup(String groupId) {
    // Cek apakah grup masih digunakan oleh item
    bool isUsed = menuItems.values.any((item) => item['groupId'] == groupId);
    if (isUsed) {
      Get.dialog(AlertDialog(
        title: Text('Gagal Menghapus'),
        content: Text('Grup ini tidak bisa dihapus karena masih digunakan oleh satu atau lebih item menu. Pindahkan item ke grup lain terlebih dahulu.'),
        actions: [TextButton(onPressed: Get.back, child: Text('OK'))],
      ));
      return;
    }

    Get.dialog(AlertDialog(
      title: Text('Konfirmasi Hapus'),
      content: Text('Apakah Anda yakin ingin menghapus grup ini?'),
      actions: [
        TextButton(onPressed: Get.back, child: Text('Batal')),
        TextButton(
          onPressed: () {
            menuGroups.removeWhere((g) => g['groupId'] == groupId);
            Get.back();
            Get.snackbar('Berhasil', 'Grup berhasil dihapus.', margin: EdgeInsets.all(12), snackPosition: SnackPosition.BOTTOM);
          },
          child: Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  // --- CRUD UNTUK ITEM MENU ---

  void showItemForm({String? itemId, Map<String, dynamic>? initialData}) {
    Get.dialog(
      ItemFormDialog(
        itemId: itemId,
        initialData: initialData,
        availableGroups: menuGroups.toList(),
        availableRoles: configC.daftarRoleTersedia.toList(),
        availableTugas: configC.daftarTugasTersedia.toList(),
        onSave: (newItemId, itemData) {
          if (itemId != null && itemId != newItemId) {
            // Hapus ID lama jika berubah
            menuItems.remove(itemId);
          }
          menuItems[newItemId] = itemData;
          Get.back();
        },
      ),
    );
  }

  void deleteItem(String itemId) {
     Get.dialog(AlertDialog(
      title: Text('Konfirmasi Hapus'),
      content: Text('Apakah Anda yakin ingin menghapus item menu ini?'),
      actions: [
        TextButton(onPressed: Get.back, child: Text('Batal')),
        TextButton(
          onPressed: () {
            menuItems.remove(itemId);
            Get.back();
            Get.snackbar('Berhasil', 'Item berhasil dihapus.', margin: EdgeInsets.all(12), snackPosition: SnackPosition.BOTTOM);
          },
          child: Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }
}