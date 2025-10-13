import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/detail_siswa_controller.dart';

class DetailSiswaView extends GetView<DetailSiswaController> {
  const DetailSiswaView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Siswa'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Detail Siswa Akan Ditampilkan Disini',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
