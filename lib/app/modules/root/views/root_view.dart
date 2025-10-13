// lib/app/modules/root/views/root_view.dart (Aplikasi SEKOLAH)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/root_controller.dart';

class RootView extends GetView<RootController> {
  const RootView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // RootView sekarang hanya akan menampilkan UI splash,
    // dan RootController akan memutuskan ke mana harus pergi.
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: Image.asset("assets/png/logo.png"),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              "Memverifikasi sesi...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}