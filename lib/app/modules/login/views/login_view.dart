import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';
import '../controllers/login_controller.dart';

// [PERBAIKAN] Ubah menjadi GetView<LoginController>
class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // [PERBAIKAN] Hapus Get.put di sini, controller akan di-inject oleh GetView
    // final LoginController controller = Get.put(LoginController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade200, Colors.green.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Layer 2: Konten Login
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo dan Judul
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Image.asset("assets/png/logo.png", fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "MI AL-HUDA YOGYAKARTA",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Silakan masuk untuk melanjutkan",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // Card untuk Form
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: controller.formKey, // [PERBAIKAN] Akses formKey dari controller
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: controller.emailC, // [PERBAIKAN] Akses emailC dari controller
                              keyboardType: TextInputType.emailAddress,
                              validator: controller.validateEmail, // [PERBAIKAN] Akses validator dari controller
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Obx(() => TextFormField(
                                  controller: controller.passC, // [PERBAIKAN] Akses passC dari controller
                                  obscureText: controller.isPasswordHidden.value, // [PERBAIKAN] Akses isPasswordHidden dari controller
                                  validator: controller.validatePassword, // [PERBAIKAN] Akses validator dari controller
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    suffixIcon: IconButton(
                                      icon: Icon(controller.isPasswordHidden.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      onPressed: () => controller.isPasswordHidden.toggle(), // [PERBAIKAN] Akses toggle dari controller
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
                                child: Text("Lupa Password?", style: TextStyle(color: Colors.indigo.shade700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Login
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          onPressed: authController.isLoading.value ? null : controller.login, // [PERBAIKAN] Akses login dari controller
                          child: authController.isLoading.value
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}