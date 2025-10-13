import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/daftar_siswa_pindah_halaqoh_controller.dart';

class DaftarSiswaPindahHalaqohView
    extends GetView<DaftarSiswaPindahHalaqohController> {
  const DaftarSiswaPindahHalaqohView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DaftarSiswaPindahHalaqohView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'DaftarSiswaPindahHalaqohView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
