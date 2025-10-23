
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/dashboard_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/carousel_item_model.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../financial_dashboard_pimpinan/controllers/financial_dashboard_pimpinan_controller.dart';
import '../../financial_dashboard_pimpinan/views/financial_dashboard_pimpinan_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});


  @override
  Widget build(BuildContext context) {
    // [DIHAPUS] final configC = Get.find<ConfigController>(); 
    // Kita akan akses melalui controller.configC agar lebih konsisten

    return Scaffold(
      body: RefreshIndicator( // [DITAMBAHKAN] Bungkus dengan RefreshIndicator
        onRefresh: () async {
          await controller.fetchCarouselData();
          // Jika ada controller dasbor pimpinan, refresh juga datanya
          if (Get.isRegistered<FinancialDashboardPimpinanController>()) {
             Get.find<FinancialDashboardPimpinanController>().fetchFinancialData();
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220.0, floating: false, pinned: true,
              backgroundColor: Colors.indigo.shade800,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset("assets/webp/profile.webp", fit: BoxFit.contain),
                    Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 42, backgroundColor: Colors.white.withOpacity(0.3),
                            child: Obx(() => CircleAvatar(
                              radius: 38,
                              backgroundImage: controller.configC.infoUser['profileImageUrl'] != null 
                                  ? NetworkImage(controller.configC.infoUser['profileImageUrl']) 
                                  : null,
                              backgroundColor: Colors.indigo.shade400,
                              child: controller.configC.infoUser['profileImageUrl'] == null 
                                  ? Text((controller.configC.infoUser['nama'] ?? "U")[0].toUpperCase(), style: const TextStyle(fontSize: 30, color: Colors.white)) 
                                  : null,
                            )),
                          ),
                          const SizedBox(height: 12),
                           Obx(() => Text(
                                controller.configC.infoUser['alias'] ?? 'Nama Pengguna',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // [INTEGRASI BARU DI SINI]
            // SliverToBoxAdapter akan menampilkan widget ini hanya jika kondisi terpenuhi
            SliverToBoxAdapter(
              child: Obx(() {
                // if (controller.kepalaSekolah) {
                if (controller.isBendaharaOrPimpinan) {
                  // [PERBAIKAN KUNCI] Inisialisasi controller di sini
                  // agar state-nya terikat dengan lifecycle DashboardView.
                  Get.put(FinancialDashboardPimpinanController());
                  return const FinancialDashboardPimpinanView();
                } else {
                  return const SizedBox(height: 24.0);
                }
              }),
            ),

            SliverToBoxAdapter(
              child: Padding(
                // [DIUBAH] Jarak atas disesuaikan, karena sudah diatur oleh widget di atas
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), 
                child: Text("Menu Akses Cepat", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              sliver: Obx(() => SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, childAspectRatio: 0.9,
                ),
                delegate: SliverChildListDelegate(
                  controller.quickAccessMenus.map((menu) => DashboardView.buildMenuItem(
                    imagePath: menu['image'], title: menu['title'],
                    onTap: menu.containsKey('route') ? () => Get.toNamed(menu['route']) : menu['onTap'],
                  )).toList(),
                ),
              )),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // [DIUBAH] Teks "Pantauan Hari Ini" agar lebih jelas
                    const Text("Pantauan Hari Ini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Obx(() => controller.isPimpinan
                        ? IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.grey),
                            onPressed: controller.showPesanEditorDialog,
                            tooltip: "Edit Pesan Dasbor",
                          )
                        : const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                if (controller.isCarouselLoading.value) {
                  return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                }
                if (controller.daftarCarousel.isEmpty) {
                  return const SizedBox(height: 160, child: Center(child: Text("Tidak ada informasi untuk ditampilkan.")));
                }
                return CarouselSlider.builder(
                  itemCount: controller.daftarCarousel.length,
                  itemBuilder: (context, index, realIndex) {
                    final item = controller.daftarCarousel[index];
                    return _buildCarouselCard(item);
                  },
                  options: CarouselOptions(
                    height: 160, autoPlay: controller.daftarCarousel.length > 1,
                    autoPlayInterval: const Duration(seconds: 10),
                    enlargeCenterPage: true, viewportFraction: 0.9,
                    aspectRatio: 16 / 9,
                  ),
                );
              }),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

             _SectionHeader(
              title: "Informasi Sekolah",
              onSeeAll: () => Get.toNamed(Routes.INFO_SEKOLAH),
            ),

            _InformasiList(),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

   Widget _SectionHeader({required String title, required VoidCallback onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(onPressed: onSeeAll, child: const Text("Lihat Semua")),
          ],
        ),
      ),
    );
  }

  Widget _InformasiList() {
    return Obx(() {
      if (controller.daftarInfoSekolah.isEmpty) {
        return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Belum ada informasi.'))));
      }
      final daftarInfo = controller.daftarInfoSekolah;
      
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = daftarInfo[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final tanggal = timestamp?.toDate() ?? DateTime.now();
              final imageUrl = data['imageUrl'] as String? ?? '';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.INFO_SEKOLAH_DETAIL, arguments: doc.id),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: Colors.grey.shade200),
                          errorWidget: (c, u, e) => Container(color: Colors.grey.shade200, child: const Icon(Icons.newspaper, color: Colors.grey)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['judul'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(data['isi'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(timeago.format(tanggal, locale: 'id'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: daftarInfo.length,
          ),
        ),
      );
    });
  }

  Widget _buildCarouselCard(CarouselItemModel item) {
    return Card(
      elevation: 4, shadowColor: item.warna.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [item.warna.withOpacity(0.8), item.warna], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(item.ikon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.judul.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(item.namaKelas, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              const Spacer(),
              Text(item.isi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (item.subJudul != null && item.subJudul!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(item.subJudul!, style: const TextStyle(fontSize: 12, color: Colors.white70))),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
  
  // [PERBAIKAN] Jadikan _buildMenuItem sebagai method static
  static Widget buildMenuItem({required String imagePath, required String title, VoidCallback? onTap}) {
    bool isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)],
              ),
              child: Image.asset(
                'assets/png/$imagePath',
                width: 30,
                height: 30,
                color: isEnabled ? null : Colors.grey.shade400,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 32, color: Colors.grey);
                },
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                height: 1.2,
                color: isEnabled ? Colors.black87 : Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}