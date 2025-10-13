import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => CustomScrollView(
          slivers: [
            // --- SLIVER APP BAR DENGAN PROFIL ---
            SliverAppBar(
              expandedHeight: 230.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.indigo.shade800,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(controller.configC.infoUser['alias'] ?? 'Nama Pengguna', 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black45)])
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset("assets/webp/profile.webp", fit: BoxFit.contain),
                    Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.4))),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white.withOpacity(0.8),
                          ),
                          _buildProfileAvatar(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Colors.blue,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => controller.pickImage(),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- BAGIAN FORM EDIT ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      title: "Informasi Utama",
                      children: [
                        TextFormField(controller: controller.namaController, decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person))),
                        const SizedBox(height: 16),
                        TextFormField(controller: controller.aliasController, decoration: const InputDecoration(labelText: "Nama Panggilan (Alias)", helperText: "Ditampilkan di jadwal, pengumuman, dll.", prefixIcon: Icon(Icons.label_important_outline))),
                        const SizedBox(height: 16),
                        TextFormField(controller: controller.nipController, decoration: const InputDecoration(labelText: "NIP / NIK", prefixIcon: Icon(Icons.badge_outlined))),
                      ],
                    ),
                    _buildSectionCard(
                      title: "Detail Kontak & Pribadi",
                      children: [
                        TextFormField(controller: controller.noTelpController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Nomor Telepon", prefixIcon: Icon(Icons.phone))),
                        const SizedBox(height: 16),
                        TextFormField(controller: controller.alamatController, decoration: const InputDecoration(labelText: "Alamat", prefixIcon: Icon(Icons.location_on_outlined)), maxLines: 2),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: controller.jenisKelamin.value.isEmpty ? null : controller.jenisKelamin.value,
                          items: ["Laki-Laki", "Perempuan"].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                          onChanged: (newValue) {
                              if (newValue != null) controller.jenisKelamin.value = newValue;
                            },
                            decoration: const InputDecoration(labelText: 'Jenis Kelamin', prefixIcon: Icon(Icons.wc)),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controller.tglGabungController,
                          readOnly: true,
                          onTap: () => controller.selectJoinDate(context),
                          decoration: const InputDecoration(
                            labelText: "Tanggal Bergabung",
                            prefixIcon: Icon(Icons.calendar_today),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                        ),
                      ],
                    ),

                     // --- TOMBOL AKSI ---
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: controller.isLoading.value ? null : () => controller.updateProfile(),
                      icon: controller.isLoading.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_as_outlined),
                      label: Text(controller.isLoading.value ? "Menyimpan..." : "Simpan Perubahan"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => controller.logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                       style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Obx(() {
      final pickedFile = controller.pickedImage.value;
      final userImageUrl = controller.configC.infoUser['profileImageUrl'] as String?;

      ImageProvider imageProvider;
      if (pickedFile != null) {
        imageProvider = FileImage(pickedFile);
      } else if (userImageUrl != null && userImageUrl.isNotEmpty) {
        // Gunakan CachedNetworkImageProvider untuk cache yang lebih baik
        imageProvider = CachedNetworkImageProvider(userImageUrl);
      } else {
        // Fallback jika tidak ada gambar
        return CircleAvatar(
          radius: 48,
          backgroundColor: Colors.indigo.shade400,
          child: Text(
            (controller.configC.infoUser['nama'] ?? "U")[0].toUpperCase(),
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
        );
      }

      return CircleAvatar(
        radius: 48,
        backgroundImage: imageProvider,
        // Tampilkan loading indicator jika gambar sedang di-cache
        child: imageProvider is CachedNetworkImageProvider ? 
          CachedNetworkImage(
            imageUrl: userImageUrl!,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
          ) : null,
      );
    });
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}