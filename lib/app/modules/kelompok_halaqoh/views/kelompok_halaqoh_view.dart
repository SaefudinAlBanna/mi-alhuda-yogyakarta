import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/kelompok_halaqoh_controller.dart';

class KelompokHalaqohView extends GetView<KelompokHalaqohController> {
  KelompokHalaqohView({super.key});

  // final dataHalaqoh = Get.arguments;

  @override
  Widget build(BuildContext context) {
    // var datacc = dataHalaqoh[0];

    return Scaffold(
      // floatingActionButton: FloatingActionButton.extended(
      //   elevation: 0.0,
      //   onPressed: () {
      //     Get.offAllNamed(Routes.HOME);
      //   },
      //   label: Text('kembali'),
      //   icon: Icon(Icons.home),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // body: SafeArea(
      //   child: Column(
      //     children: [
      //       Stack(
      //         fit: StackFit.passthrough,
      //         children: [
      //           Container(
      //             height: 150,
      //             width: Get.width,
      //             decoration: BoxDecoration(
      //               color: Colors.indigo[400],
      //               // image: DecorationImage(
      //               //   image: AssetImage("assets/images/profile.png"),
      //               // ),
      //             ),
      //             child: Padding(
      //               padding: const EdgeInsets.only(top: 15),
      //               child: Column(
      //                 children: [
      //                   Text(
      //                     'Tahun Ajaran : ${datacc["tahunajaran"]}',
      //                     textAlign: TextAlign.center,
      //                     style: TextStyle(
      //                       fontSize: 16,
      //                       color: Colors.white,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                   ),
      //                   // Text(
      //                   //   "${datacc['namasemester']}",
      //                   //   style: TextStyle(
      //                   //     fontSize: 16,
      //                   //     color: Colors.white,
      //                   //     fontWeight: FontWeight.bold,
      //                   //   ),
      //                   // ),
      //                 ],
      //               ),
      //             ),
      //           ),

      //           Container(
      //             margin: EdgeInsets.only(top: 80),
      //             child: Column(
      //               children: [
      //                 Column(
      //                   children: [
      //                     Container(
      //                       padding: EdgeInsets.symmetric(
      //                         horizontal: 15,
      //                         vertical: 10,
      //                       ),
      //                       margin: EdgeInsets.symmetric(horizontal: 25),
      //                       width: Get.width,
      //                       decoration: BoxDecoration(
      //                         boxShadow: [
      //                           BoxShadow(
      //                             color: Colors.grey.withValues(alpha: 0.5),
      //                             // spreadRadius: 1,
      //                             blurRadius: 3,
      //                             offset: Offset(2, 2),
      //                           ),
      //                         ],
      //                         color: Colors.grey.shade50,
      //                         borderRadius: BorderRadius.circular(20),
      //                       ),
      //                       child: Column(
      //                         crossAxisAlignment: CrossAxisAlignment.start,
      //                         children: [
      //                           Text(
      //                             'nama pengampu : ${datacc["namapengampu"]}',
      //                           ),
      //                           SizedBox(height: 10),
      //                           // Text(
      //                           //   'nama tempat : ${datacc["tempatmengaji"]}',
      //                           // ),
      //                           // SizedBox(height: 10),
      //                           Text('Fase : ${datacc["fase"]}'),
      //                         ],
      //                       ),
      //                     ),
      //                   ],
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ],
      //       ),

      //       // SizedBox(height: 20),

      //       FutureBuilder<List<String>>(
      //         future: controller.getDataKelasYangAda(),
      //         builder: (context, snapshotkelas) {
      //           if (snapshotkelas.connectionState == ConnectionState.waiting) {
      //             return CircularProgressIndicator();
      //           } else if (snapshotkelas.hasData) {
      //             List<String> kelasAjarGuru = snapshotkelas.data!;
      //             return Padding(
      //               padding: const EdgeInsets.only(top: 20, left: 20),
      //               child: SingleChildScrollView(
      //                 child: Row(
      //                   children:
      //                       kelasAjarGuru.map((k) {
      //                         return GestureDetector(
      //                           onTap: () {
      //                             controller.kelasSiswaC.text = k;
      //                             Get.bottomSheet(
      //                               Container(
      //                                 padding: EdgeInsets.symmetric(
      //                                   horizontal: 30,
      //                                   vertical: 30,
      //                                 ),
      //                                 color: Colors.white,
      //                                 child: Center(
      //                                   child: StreamBuilder<
      //                                     QuerySnapshot<Map<String, dynamic>>
      //                                   >(
      //                                     stream:
      //                                         controller.getDataSiswaStreamBaru(),
      //                                     builder: (context, snapshotsiswa) {
      //                                       if (snapshotsiswa.connectionState ==
      //                                           ConnectionState.waiting) {
      //                                         return CircularProgressIndicator();
      //                                       }
      //                                       // ignore: prefer_is_empty
      //                                       if (snapshotsiswa.data?.docs.length == 0 ||
      //                                           snapshotsiswa.data == null) {
      //                                         return Center(
      //                                           child: Text(
      //                                             'Siswa sudah terpilih semua',
      //                                           ),
      //                                         );
      //                                       } else if (snapshotsiswa.hasData) {
      //                                         return ListView.builder(
      //                                           itemCount:
      //                                               snapshotsiswa
      //                                                   .data!
      //                                                   .docs
      //                                                   .length,
      //                                           itemBuilder: (context, index) {
      //                                             String namaSiswa =
      //                                                 snapshotsiswa
      //                                                     .data!
      //                                                     .docs[index]
      //                                                     .data()['namasiswa'] ??
      //                                                 'No Name';
      //                                             String nisnSiswa =
      //                                                 snapshotsiswa
      //                                                     .data!
      //                                                     .docs[index]
      //                                                     .data()['nisn'] ??
      //                                                 'No NISN';
      //                                             // ignore: prefer_is_empty
      //                                             if (snapshotsiswa
      //                                                         .data!
      //                                                         .docs
      //                                                         .length ==
      //                                                     0 ||
      //                                                 snapshotsiswa
      //                                                     .data!
      //                                                     .docs
      //                                                     .isEmpty) {
      //                                               return Center(
      //                                                 child: Text(
      //                                                   'Semua siswa sudah terpilih',
      //                                                 ),
      //                                               );
      //                                             } else {
      //                                               return ListTile(
      //                                                 onTap: () {
      //                                                   controller
      //                                                       .simpanSiswaKelompok(
      //                                                         namaSiswa,
      //                                                         nisnSiswa,
      //                                                       );
      //                                                   // tampilkan siswa yang sudah terpilih
      //                                                   controller.tampilkan();
      //                                                   controller
      //                                                       .refreshTampilan();
      //                                                 },
      //                                                 title: Text(
      //                                                   snapshotsiswa
      //                                                       .data!
      //                                                       .docs[index]
      //                                                       .data()['namasiswa'],
      //                                                 ),
      //                                                 subtitle: Text(
      //                                                   snapshotsiswa
      //                                                       .data!
      //                                                       .docs[index]
      //                                                       .data()['namakelas'],
      //                                                 ),
      //                                                 leading: CircleAvatar(
      //                                                   child: Text(
      //                                                     snapshotsiswa
      //                                                         .data!
      //                                                         .docs[index]
      //                                                         .data()['namasiswa'][0],
      //                                                   ),
      //                                                 ),
      //                                                 trailing: Row(
      //                                                   mainAxisSize:
      //                                                       MainAxisSize.min,
      //                                                   children: <Widget>[
      //                                                     IconButton(
      //                                                       tooltip: 'Simpan',
      //                                                       icon: const Icon(
      //                                                         Icons.save_outlined,
      //                                                       ),
      //                                                       onPressed: () {
      //                                                         controller
      //                                                             .simpanSiswaKelompok(
      //                                                               namaSiswa,
      //                                                               nisnSiswa,
      //                                                             );
      //                                                         // tampilkan siswa yang sudah terpilih
      //                                                         controller
      //                                                             .tampilkan();
      //                                                         controller
      //                                                             .refreshTampilan();
      //                                                         // print('simpan siswa');
      //                                                       },
      //                                                     ),
      //                                                   ],
      //                                                 ),
      //                                               );
      //                                             }
      //                                           },
      //                                         );
      //                                       } else {
      //                                         return Center(
      //                                           child: Text('No data available'),
      //                                         );
      //                                       }
      //                                     },
      //                                   ),
      //                                 ),
      //                               ),
      //                             );
      //                           },
      //                           child: Container(
      //                             margin: EdgeInsets.only(left: 15),
      //                             height: 50,
      //                             width: 45,
      //                             decoration: BoxDecoration(
      //                               color: Colors.indigo,
      //                               borderRadius: BorderRadius.circular(10),
      //                             ),
      //                             child: Center(
      //                               child: Text(
      //                                 k,
      //                                 style: TextStyle(
      //                                   fontSize: 14,
      //                                   color: Colors.white,
      //                                   fontWeight: FontWeight.bold,
      //                                 ),
      //                               ),
      //                             ),
      //                           ),
      //                         );
      //                       }).toList(),
      //                 ),
      //               ),
      //             );
      //           } else {
      //             return SizedBox();
      //           }
      //         },
      //       ),

      //       SizedBox(height: 20),

      //       Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 15),
      //         child: Text(
      //           'Daftar Siswa Halaqoh',
      //           style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      //         ),
      //       ),
      //       Divider(),

      //       Expanded(
      //         child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      //           stream: controller.tampilkan(),
      //           builder: (context, snapshotKelompok) {
      //             if (snapshotKelompok.connectionState ==
      //                 ConnectionState.waiting) {
      //               return Center(child: CircularProgressIndicator());
      //             }
      //             // ignore: prefer_is_empty
      //             if (snapshotKelompok.data?.docs.length == 0 ||
      //                 snapshotKelompok.data == null) {
      //               return Center(child: Text('belum ada data'));
      //             }
      //             // else {
      //             return ListView.builder(
      //               itemCount: snapshotKelompok.data!.docs.length,
      //               itemBuilder: (context, index) {
      //                 String namaSiswa =
      //                     snapshotKelompok.data!.docs[index]
      //                         .data()['namasiswa'] ??
      //                     'No Name';
      //                 String kelasSiswa =
      //                     snapshotKelompok.data!.docs[index].data()['kelas'] ??
      //                     'No KELAS';
      //                 return ListTile(
      //                   // onTap: () {
      //                   //   String getNama =
      //                   //       snapshotKelompok.data!.docs[index].data()['nisn'];
      //                   //   Get.toNamed(Routes.DETAIL_SISWA, arguments: getNama);
      //                   // },
      //                   title: Text(namaSiswa),
      //                   subtitle: Text(kelasSiswa),
      //                   trailing: Row(
      //                     mainAxisSize: MainAxisSize.min,
      //                     children: <Widget>[
      //                     ],
      //                   ),
      //                 );
      //               },
      //             );
      //             // }
      //           },
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
