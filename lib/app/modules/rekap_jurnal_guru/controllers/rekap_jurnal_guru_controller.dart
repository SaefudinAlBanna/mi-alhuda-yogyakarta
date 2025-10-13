import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class RekapJurnalGuruController extends GetxController {
  // FirebaseAuth auth = FirebaseAuth.instance;
  // FirebaseFirestore firestore = FirebaseFirestore.instance;

  // String idUser = FirebaseAuth.instance.currentUser!.uid;
  // // idSekolah tidak perlu di sini karena collectionGroup mencari di seluruh DB,
  // // dan kita sudah filter by idpenginput yang unik.

  // Stream<QuerySnapshot<Map<String, dynamic>>> getRekapJurnalGuru() async* {
  //   // === KODE YANG DIPERBAIKI ===
  //   // Memanggil collectionGroup dari root firestore, lalu memfilternya
  //   yield* firestore
  //       .collectionGroup('jurnalkelas') // Mencari semua koleksi dengan nama 'jurnalkelas'
  //       .where('idpenginput', isEqualTo: idUser) // Filter hanya untuk guru yang login
  //       .orderBy('tanggalinput', descending: true) // Urutkan dari yang terbaru
  //       .snapshots();
  // }
}