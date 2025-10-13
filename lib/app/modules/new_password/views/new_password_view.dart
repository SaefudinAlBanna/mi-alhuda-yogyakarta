// lib/app/modules/new_password/views/new_password_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/new_password_controller.dart';

class NewPasswordView extends GetView<NewPasswordController> {
  const NewPasswordView({Key? key}) : super(key: key);

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Form( // <--- Widget Form di sini
              key: controller.formKey,
              // --- TAMBAHKAN BARIS INI ---
              autovalidateMode: AutovalidateMode.onUserInteraction,
              // --------------------------
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Center(
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 60,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Buat Password Baru",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Untuk keamanan, Anda harus membuat password baru yang kuat.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                   Obx(() => TextFormField(
                        controller: controller.oldPassC,
                        obscureText: controller.isOldPassObscure.value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password lama tidak boleh kosong';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password Lama (Default)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(controller.isOldPassObscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => controller.isOldPassObscure.toggle(),
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),

                  // Field Password Baru
                  Obx(() => TextFormField(
                        controller: controller.newPassC,
                        obscureText: controller.isNewPassObscure.value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password baru tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal harus 6 karakter';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(controller.isNewPassObscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => controller.isNewPassObscure.toggle(),
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),

                  // Field Konfirmasi Password
                  Obx(() => TextFormField(
                        controller: controller.confirmPassC,
                        obscureText: controller.isConfirmPassObscure.value,
                        validator: (value) {
                          if (value != controller.newPassC.text) {
                            return 'Password tidak cocok';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          // prefixIcon: const Icon(Icons.lock_check_outline),
                          prefixIcon: const Icon(Icons.lock_open_rounded),
                           suffixIcon: IconButton(
                            icon: Icon(controller.isConfirmPassObscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => controller.isConfirmPassObscure.toggle(),
                          ),
                        ),
                      )),
                  const SizedBox(height: 40),

                  // Tombol Simpan
                  Obx(() => SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: controller.isLoading.value ? null : controller.changePassword,
                          child: controller.isLoading.value
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'SIMPAN & LANJUTKAN',
                                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}