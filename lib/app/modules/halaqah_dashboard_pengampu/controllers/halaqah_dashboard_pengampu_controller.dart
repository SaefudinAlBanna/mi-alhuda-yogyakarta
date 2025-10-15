import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/halaqah_group_model.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';

import '../../../controllers/auth_controller.dart';

class HalaqahDashboardPengampuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();
  
  // Gunakan Future karena daftar grup yang diampu relatif statis per semester
  late Future<List<HalaqahGroupModel>> listGroupFuture;

  @override
  void onInit() {
    super.onInit();
    listGroupFuture = fetchMyGroups();
  }

  Future<List<HalaqahGroupModel>> fetchMyGroups() async {
    final uid = authC.auth.currentUser!.uid;
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final semester = configC.semesterAktif.value;
    final keySemester = "${tahunAjaran}_$semester";
    
    // Map untuk menampung hasil gabungan dan menghindari duplikat
    final Map<String, HalaqahGroupModel> combinedGroups = {};

    // --- QUERY 1: Ambil grup permanen (dari denormalisasi) ---
    final user = configC.infoUser;
    final Map<String, dynamic> diampuData = user['grupHalaqahDiampu'] ?? {};
    final List<String> permanentGroupIds = List<String>.from(diampuData[keySemester] ?? []);

    if (permanentGroupIds.isNotEmpty) {
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('halaqah_grup')
          .where(FieldPath.documentId, whereIn: permanentGroupIds)
          .get();
      
      for (var doc in snapshot.docs) {
        combinedGroups[doc.id] = HalaqahGroupModel.fromFirestore(doc);
      }
    }

    // --- QUERY 2: Ambil grup pengganti untuk HARI INI ---
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final substituteSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup')
        .where('penggantiHarian.$todayKey.idPengganti', isEqualTo: uid)
        .get();

    for (var doc in substituteSnapshot.docs) {
      final group = HalaqahGroupModel.fromFirestore(doc);
      group.isPengganti = true; // Tandai sebagai grup pengganti
      combinedGroups[doc.id] = group; // Timpa jika sudah ada, atau tambahkan baru
    }

    // Konversi Map kembali ke List dan urutkan
    final finalGroupList = combinedGroups.values.toList();
    finalGroupList.sort((a, b) => a.namaGrup.compareTo(b.namaGrup));
    
    return finalGroupList;
  }

  void goToGradingPage(HalaqahGroupModel group) {
    Get.toNamed(Routes.HALAQAH_GRADING, arguments: group);
  }
}