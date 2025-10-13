import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_siswa_perkelas_controller.dart';

class DaftarSiswaPerkelasView extends GetView<DaftarSiswaPerkelasController> {
  DaftarSiswaPerkelasView({super.key});

  // final dataArgumen = Get.arguments;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Daftar Siswa Kelas $dataArgumen'),
      //   centerTitle: true,
      // ),
      // body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      //   future: controller.getDataSiswa(),
      //   builder: (context, snapsiswa) {
      //     if (snapsiswa.connectionState == ConnectionState.waiting) {
      //       return Center(child: CircularProgressIndicator());
      //     }
      //     if (snapsiswa.data == null || snapsiswa.data!.docs.isEmpty) {
      //       print("snapsiswa.lenght = ${snapsiswa.data!.docs.length}");
      //       return Center(child: Text("Siswa tidak ada"));
      //     }
      //     if (snapsiswa.hasData) {
      //       var datasiswa = snapsiswa.data!.docs;
      //       return ListView(
      //         // crossAxisAlignment: CrossAxisAlignment.start,
      //         children: [
      //           Padding(
      //             padding: const EdgeInsets.only(left: 10),
      //             child: Text("wali kelas : ${datasiswa[0]['walikelas']}"),
      //           ),
      //           SizedBox(height: 25),
      //           ListView.builder(
      //             shrinkWrap: true,
      //             physics: NeverScrollableScrollPhysics(),
      //             itemCount: snapsiswa.data!.docs.length,
      //             itemBuilder: (context, index) {
      //               // var datasiswa = snapsiswa.data!.docs;
      //               return InkWell(
      //                 onTap: () {
      //                   Get.toNamed(Routes.INPUT_CATATAN_KHUSUS_SISWA, arguments: datasiswa[index].data());
      //                   // controller.test();
      //                 },
      //                 child: Container(
      //                   margin: EdgeInsets.fromLTRB(15, 0, 15, 10),
      //                   // height: 50,
      //                   decoration: BoxDecoration(
      //                     color: Colors.grey[300],
      //                     borderRadius: BorderRadius.circular(15),
      //                   ),
      //                   child: Padding(
      //                     padding: EdgeInsets.all(10),
      //                     child: Text(datasiswa[index]['namasiswa']),
      //                   ),
      //                 ),
      //               );
      //             },
      //           ),
      //         ],
      //       );
      //     } else {
      //       return Center(
      //         child: Text(
      //           "tidak dapat memuat data, periksa koneksi internet",
      //         ),
      //       );
      //     }
      //   },
      // ),
    );
  }
}
