import 'package:get/get.dart';
import '../../../models/siswa_keuangan_model.dart';
import '../../../models/tagihan_model.dart';
import '../controllers/alokasi_pembayaran_controller.dart';

class AlokasiPembayaranBinding extends Bindings {
  @override
  void dependencies() {
    // [LOGIKA KUNCI]
    // 1. Ambil argumen di sini dengan aman.
    final Map<String, dynamic> args = Get.arguments;
    final SiswaKeuanganModel siswa = args['siswa'];
    final List<TagihanModel> tagihan = args['tagihan'];

    // 2. Buat instance controller dan langsung "suntikkan" data yang dibutuhkan.
    Get.lazyPut<AlokasiPembayaranController>(
      () => AlokasiPembayaranController(
        siswa: siswa,
        tagihanBelumLunas: tagihan,
      ),
    );
  }
}

// import 'package:get/get.dart';

// import '../controllers/alokasi_pembayaran_controller.dart';

// class AlokasiPembayaranBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<AlokasiPembayaranController>(
//       () => AlokasiPembayaranController(),
//     );
//   }
// }
