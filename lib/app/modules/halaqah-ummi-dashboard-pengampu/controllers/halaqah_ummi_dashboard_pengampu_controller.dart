import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../routes/app_pages.dart';

class HalaqahUmmiDashboardPengampuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();
  
  late Future<List<HalaqahGroupUmmiModel>> listGroupFuture;

  @override
  void onInit() {
    super.onInit();
    listGroupFuture = fetchMyGroups();
  }

  Future<List<HalaqahGroupUmmiModel>> fetchMyGroups() async {
    final uid = authC.auth.currentUser!.uid;
    final tahunAjaran = configC.tahunAjaranAktif.value;
    
    final Map<String, HalaqahGroupUmmiModel> combinedGroups = {};
  
    // 1. Ambil grup di mana pengguna adalah pengampu utama
    final permanentSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup_ummi')
        .where('idPengampu', isEqualTo: uid)
        .get();
  
    for (var doc in permanentSnapshot.docs) {
      combinedGroups[doc.id] = HalaqahGroupUmmiModel.fromFirestore(doc);
    }
  
    // 2. Ambil grup di mana pengguna adalah pengganti hari ini
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final substituteSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup_ummi') // <-- PATH DIUBAH
        .where('penggantiHarian.$todayKey.idPengganti', isEqualTo: uid)
        .get();
  
    for (var doc in substituteSnapshot.docs) {
      final group = HalaqahGroupUmmiModel.fromFirestore(doc);
      group.isPengganti = true;
      combinedGroups[doc.id] = group;
    }
  
    final finalGroupList = combinedGroups.values.toList();
    finalGroupList.sort((a, b) => a.namaGrup.compareTo(b.namaGrup));
    
    return finalGroupList;
  }

  void goToGradingPage(HalaqahGroupUmmiModel group) {
    Get.toNamed(Routes.HALAQAH_UMMI_GRADING, arguments: group);
  }
}