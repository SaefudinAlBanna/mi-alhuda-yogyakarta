import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

class DaftarSiswaPerkelasController extends GetxController {

  // var dataArgumen = Get.arguments;

  // FirebaseAuth auth = FirebaseAuth.instance;
  // FirebaseFirestore firestore = FirebaseFirestore.instance;

  // String idUser = FirebaseAuth.instance.currentUser!.uid;
  // String idSekolah = "P9984539";
  // String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  // String? idTahunAjaran;

  //  @override
  // void onInit() async {
  //   super.onInit();
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   idTahunAjaran = tahunajaranya.replaceAll("/", "-");
  //   update();
  // }

  // // @override
  // // void onClose() {
  // //   super.onClose();
  // // }


  // Future<String> getTahunAjaranTerakhir() async {
  //   CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran');
  //   QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
  //       await colTahunAjaran.get();
  //   List<Map<String, dynamic>> listTahunAjaran =
  //       snapshotTahunAjaran.docs.map((e) => e.data()).toList();
  //   String tahunAjaranTerakhir =
  //       listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
  //   return tahunAjaranTerakhir;
  // }


  // Future<QuerySnapshot<Map<String, dynamic>>> getDataSiswa() async {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    
  //   return await firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran')
  //       .doc(idTahunAjaran)
  //       .collection('kelastahunajaran')
  //       .doc(dataArgumen)
  //       .collection('daftarsiswa')
  //       .get();
  // }

  // void test() {
  //   print(dataArgumen);
  // }
}
