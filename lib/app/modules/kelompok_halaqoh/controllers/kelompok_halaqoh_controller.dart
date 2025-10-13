import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KelompokHalaqohController extends GetxController {
  // var argumenData = Get.arguments;
  // TextEditingController kelasSiswaC = TextEditingController();

  // FirebaseAuth auth = FirebaseAuth.instance;
  // FirebaseFirestore firestore = FirebaseFirestore.instance;

  // String idUser = FirebaseAuth.instance.currentUser!.uid;
  // String idSekolah = 'P9984539';
  // String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

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


  // Future<List<String>> getDataKelasYangAda() async {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  //         List<String> kelasList = [];
  //         await firestore
  //             .collection('Sekolah')
  //             .doc(idSekolah)
  //             .collection('tahunajaran')
  //             .doc(idTahunAjaran)
  //             .collection('kelastahunajaran')
  //             .where('fase', isEqualTo: argumenData[0]['fase'])
  //             .get()
  //             .then((querySnapshot) {
  //           for (var docSnapshot in querySnapshot.docs) {
  //             kelasList.add(docSnapshot.id);
  //           }
  //         });
  //         return kelasList;
  // }


  // Stream<QuerySnapshot<Map<String, dynamic>>> getDataSiswaStreamBaru() async* {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  //   yield* firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran')
  //       .doc(idTahunAjaran)
  //       .collection('kelastahunajaran')
  //       .doc(kelasSiswaC.text)
  //       .collection('daftarsiswa')
  //       .where('statuskelompok', isEqualTo: 'baru')
  //       .snapshots();

  //   // print('ini kelasnya : ${kelasSiswaC.text}');
  // }

  // Future<void> ubahStatusSiswa(String nisnSiSwa) async {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  //   await firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran')
  //       .doc(idTahunAjaran)
  //       .collection('kelastahunajaran')
  //       .doc(kelasSiswaC.text)
  //       .collection('daftarsiswa')
  //       .doc(nisnSiSwa)
  //       .update({
  //     'statuskelompok': 'aktif',
  //   });
  // }

  // Future<void> refreshTampilan() async {
  //   tampilkan();
  // }

  // Stream<QuerySnapshot<Map<String, dynamic>>> tampilkan() async* {
  //   String tahunAjaranX = argumenData[0]['tahunajaran'];
  //   String tahunAjaranya = tahunAjaranX.replaceAll("/", "-");
  //   yield* firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran')
  //       .doc(tahunAjaranya)
  //       // .collection('semester')
  //       // .doc(argumenData[0]['namasemester'])
  //       .collection('kelompokmengaji')
  //       .doc(argumenData[0]['fase'])
  //       .collection('pengampu')
  //       .doc(argumenData[0]['namapengampu'])
  //       // .collection('tempat')
  //       // .doc(argumenData[0]['tempatmengaji'])
  //       .collection('daftarsiswa')
  //       .orderBy('tanggalinput', descending: true)
  //       .snapshots();
  // }

  // Future<void> simpanSiswaKelompok(String namaSiswa, String nisnSiswa) async {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  //   QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok = await firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('pegawai')
  //       .where('alias', isEqualTo: argumenData[0]['namapengampu'])
  //       .get();
  //   if (querySnapshotKelompok.docs.isNotEmpty) {
  //     Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
  //     String idPengampu = dataGuru['uid'];

  //     //buat pada tahunpelajaran sekolah
  //     await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('tahunajaran')
  //         .doc(idTahunAjaran)
  //         .collection('kelompokmengaji')
  //         .doc(argumenData[0]['fase'])
  //         .collection('pengampu')
  //         .doc(argumenData[0]['namapengampu'])
  //         // .collection('tempat')
  //         // .doc(argumenData[0]['tempatmengaji'])
  //         .collection('daftarsiswa')
  //         .doc(nisnSiswa)
  //         .set({
  //       'ummi' : "0",
  //       'namasiswa': namaSiswa,
  //       'nisn': nisnSiswa,
  //       'kelas': kelasSiswaC.text,
  //       'fase': argumenData[0]['fase'],
  //       // 'tempatmengaji': argumenData[0]['tempatmengaji'],
  //       'tahunajaran': argumenData[0]['tahunajaran'],
  //       'kelompokmengaji': argumenData[0]['namapengampu'],
  //       'namapengampu': argumenData[0]['namapengampu'],
  //       'idpengampu': argumenData[0]['idpengampu'],
  //       'emailpenginput': emailAdmin,
  //       'idpenginput': idUser,
  //       'tanggalinput': DateTime.now().toIso8601String(),
  //       'idsiswa': nisnSiswa,
  //     });

  //     await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('tahunajaran')
  //         .doc(idTahunAjaran)
  //         .collection('kelompokmengaji')
  //         .doc(argumenData[0]['fase'])
  //         .collection('pengampu')
  //         .doc(argumenData[0]['namapengampu'])
  //         // .collection('tempat')
  //         // .doc(argumenData[0]['tempatmengaji'])
  //         .collection('daftarsiswa')
  //         .doc(nisnSiswa)
  //         .collection('semester')
  //         .doc('Semester I')
  //         .set({
  //       'ummi' : "0",
  //       'namasiswa': namaSiswa,
  //       'nisn': nisnSiswa,
  //       'kelas': kelasSiswaC.text,
  //       'fase': argumenData[0]['fase'],
  //       // 'tempatmengaji': argumenData[0]['tempatmengaji'],
  //       'tahunajaran': argumenData[0]['tahunajaran'],
  //       'kelompokmengaji': argumenData[0]['namapengampu'],
  //       'namasemester': 'Semester I',
  //       'namapengampu': argumenData[0]['namapengampu'],
  //       'idpengampu': idPengampu,
  //       'emailpenginput': emailAdmin,
  //       'idpenginput': idUser,
  //       'tanggalinput': DateTime.now().toIso8601String(),
  //       'idsiswa': nisnSiswa,
  //     });

  //     await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('siswa')
  //         .doc(nisnSiswa)
  //         .collection('tahunajarankelompok')
  //         .doc(idTahunAjaran)
  //         .set({
  //       'fase': argumenData[0]['fase'],
  //       'nisn': nisnSiswa,
  //       'namatahunajaran': tahunajaranya,
  //       'idpenginput': idUser,
  //       'tanggalinput': DateTime.now().toIso8601String(),
  //     });

      

  //     await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('siswa')
  //         .doc(nisnSiswa)
  //         .collection('tahunajarankelompok')
  //         .doc(idTahunAjaran)
  //         // .collection('semester')
  //         // .doc(argumenData[0]['namasemester'])
  //         .collection('kelompokmengaji')
  //         .doc(argumenData[0]['fase'])
  //         .set({
  //       'fase': argumenData[0]['fase'],
  //       // 'tempatmengaji': argumenData[0]['tempatmengaji'],
  //       'namapengampu': argumenData[0]['namapengampu'],
  //       'kelompokmengaji': argumenData[0]['namapengampu'],
  //       'idpengampu': idPengampu,
  //       // 'namasemester': argumenData[0]['namasemester'],
  //       'tahunajaran': tahunajaranya,
  //       'emailpenginput': emailAdmin,
  //       'idpenginput': idUser,
  //       'tanggalinput': DateTime.now().toIso8601String(),
  //     });

  //     await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('siswa')
  //         .doc(nisnSiswa)
  //         .collection('tahunajarankelompok')
  //         .doc(idTahunAjaran)
  //         .collection('kelompokmengaji')
  //         .doc(argumenData[0]['fase'])
  //         .collection('pengampu')
  //         .doc(argumenData[0]['namapengampu'])
  //         .set({
  //       'nisn': nisnSiswa,
  //       // 'tempatmengaji': argumenData[0]['tempatmengaji'],
  //       'fase': argumenData[0]['fase'],
  //       'tahunajaran': idTahunAjaran,
  //       'kelompokmengaji': argumenData[0]['namapengampu'],
  //       'namapengampu': argumenData[0]['namapengampu'],
  //       'idpengampu': idPengampu,
  //       'emailpenginput': emailAdmin,
  //       'idpenginput': idUser,
  //       'tanggalinput': DateTime.now().toIso8601String(),
  //     });


  //     await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('siswa')
  //         .doc(nisnSiswa)
  //         .collection('tahunajarankelompok')
  //         .doc(idTahunAjaran)
  //         .collection('kelompokmengaji')
  //         .doc(argumenData[0]['fase'])
  //         .collection('pengampu')
  //         .doc(argumenData[0]['namapengampu'])
  //         // .collection('tempat')
  //         // .doc(argumenData[0]['tempatmengaji'])
  //         .set({
  //       'nisn': nisnSiswa,
  //       // 'tempatmengaji': argumenData[0]['tempatmengaji'],
  //       'fase': argumenData[0]['fase'],
  //       'tahunajaran': idTahunAjaran,
  //       'kelompokmengaji': argumenData[0]['namapengampu'],
  //       // 'namasemester': 'Semester I',
  //       'namapengampu': argumenData[0]['namapengampu'],
  //       'idpengampu': idPengampu,
  //       'emailpenginput': emailAdmin,
  //       'idpenginput': idUser,
  //       'tanggalinput': DateTime.now().toIso8601String(),
  //     });

  //     await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('siswa')
  //         .doc(nisnSiswa)
  //         .collection('tahunajarankelompok')
  //         .doc(idTahunAjaran)
  //         // .collection('semester')
  //         // .doc(argumenData[0]['namasemester'])
  //         .collection('kelompokmengaji')
  //         .doc(argumenData[0]['fase'])
  //         .collection('pengampu')
  //         .doc(argumenData[0]['namapengampu'])
  //         // .collection('tempat')
  //         // .doc(argumenData[0]['tempatmengaji'])
  //         .collection('semester')
  //         .doc('Semester I')
  //         .set({
  //       'ummi' : "0",
  //       'nisn': nisnSiswa,
  //       // 'tempatmengaji': argumenData[0]['tempatmengaji'],
  //       'fase': argumenData[0]['fase'],
  //       'tahunajaran': idTahunAjaran,
  //       'kelompokmengaji': argumenData[0]['namapengampu'],
  //       'namasemester': 'Semester I',
  //       'namapengampu': argumenData[0]['namapengampu'],
  //       'idpengampu': idPengampu,
  //       'emailpenginput': emailAdmin,
  //       'idpenginput': idUser,
  //       'tanggalinput': DateTime.now().toIso8601String(),
  //     });

  //     ubahStatusSiswa(nisnSiswa);
  //   }
  // }

}
