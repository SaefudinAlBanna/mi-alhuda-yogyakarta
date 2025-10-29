import 'package:get/get.dart';

import '../modules/absensi_wali_kelas/bindings/absensi_wali_kelas_binding.dart';
import '../modules/absensi_wali_kelas/views/absensi_wali_kelas_view.dart';
import '../modules/alokasi_pembayaran/bindings/alokasi_pembayaran_binding.dart';
import '../modules/alokasi_pembayaran/views/alokasi_pembayaran_view.dart';
import '../modules/atp_form/bindings/atp_form_binding.dart';
import '../modules/atp_form/views/atp_form_view.dart';
import '../modules/atur_guru_pengganti/bindings/atur_guru_pengganti_binding.dart';
import '../modules/atur_guru_pengganti/views/atur_guru_pengganti_view.dart';
import '../modules/atur_penggantian_host/bindings/atur_penggantian_host_binding.dart';
import '../modules/atur_penggantian_host/views/atur_penggantian_host_view.dart';
import '../modules/atur_penggantian_rentang/bindings/atur_penggantian_rentang_binding.dart';
import '../modules/atur_penggantian_rentang/views/atur_penggantian_rentang_view.dart';
import '../modules/buat_sarpras/bindings/buat_sarpras_binding.dart';
import '../modules/buat_sarpras/views/buat_sarpras_view.dart';
import '../modules/buat_tagihan_tahunan/bindings/buat_tagihan_tahunan_binding.dart';
import '../modules/buat_tagihan_tahunan/views/buat_tagihan_tahunan_view.dart';
import '../modules/cari_siswa_keuangan/bindings/cari_siswa_keuangan_binding.dart';
import '../modules/cari_siswa_keuangan/views/cari_siswa_keuangan_view.dart';
import '../modules/catatan_bk/bindings/catatan_bk_binding.dart';
import '../modules/catatan_bk/views/catatan_bk_detail_view.dart';
import '../modules/catatan_bk/views/catatan_bk_list_view.dart';
import '../modules/create_edit_buku/bindings/create_edit_buku_binding.dart';
import '../modules/create_edit_buku/views/create_edit_buku_view.dart';
import '../modules/create_edit_ekskul/bindings/create_edit_ekskul_binding.dart';
import '../modules/create_edit_ekskul/views/create_edit_ekskul_view.dart';
import '../modules/create_edit_halaqah_group/bindings/create_edit_halaqah_group_binding.dart';
import '../modules/create_edit_halaqah_group/views/create_edit_halaqah_group_view.dart';
import '../modules/create_edit_halaqah_ummi_group/bindings/create_edit_halaqah_ummi_group_binding.dart';
import '../modules/create_edit_halaqah_ummi_group/views/create_edit_halaqah_ummi_group_view.dart';
import '../modules/daftar_nilai/bindings/daftar_nilai_binding.dart';
import '../modules/daftar_nilai/views/daftar_nilai_view.dart';
import '../modules/daftar_siswa/bindings/daftar_siswa_binding.dart';
import '../modules/daftar_siswa/views/daftar_siswa_view.dart';
import '../modules/daftar_siswa_perkelas/bindings/daftar_siswa_perkelas_binding.dart';
import '../modules/daftar_siswa_perkelas/views/daftar_siswa_perkelas_view.dart';
import '../modules/daftar_siswa_permapel/bindings/daftar_siswa_permapel_binding.dart';
import '../modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart';
import '../modules/daftar_siswa_pindah_halaqoh/bindings/daftar_siswa_pindah_halaqoh_binding.dart';
import '../modules/daftar_siswa_pindah_halaqoh/views/daftar_siswa_pindah_halaqoh_view.dart';
import '../modules/dashboard_bk/bindings/dashboard_bk_binding.dart';
import '../modules/dashboard_bk/views/dashboard_bk_view.dart';
import '../modules/data_sarpras/bindings/data_sarpras_binding.dart';
import '../modules/data_sarpras/views/data_sarpras_view.dart';
import '../modules/detail_keuangan_siswa/bindings/detail_keuangan_siswa_binding.dart';
import '../modules/detail_keuangan_siswa/views/detail_keuangan_siswa_view.dart';
import '../modules/editor_jadwal/bindings/editor_jadwal_binding.dart';
import '../modules/editor_jadwal/views/editor_jadwal_view.dart';
import '../modules/ekskul_pendaftaran_management/bindings/ekskul_pendaftaran_management_binding.dart';
import '../modules/ekskul_pendaftaran_management/views/ekskul_pendaftaran_management_view.dart';
import '../modules/financial_dashboard_pimpinan/bindings/financial_dashboard_pimpinan_binding.dart';
import '../modules/financial_dashboard_pimpinan/views/financial_dashboard_pimpinan_view.dart';
import '../modules/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/guru_akademik/bindings/guru_akademik_binding.dart';
import '../modules/guru_akademik/views/guru_akademik_view.dart';
import '../modules/halaqah-ummi-dashboard-pengampu/bindings/halaqah_ummi_dashboard_pengampu_binding.dart';
import '../modules/halaqah-ummi-dashboard-pengampu/views/halaqah_ummi_dashboard_pengampu_view.dart';
import '../modules/halaqah-ummi-grading/bindings/halaqah_ummi_grading_binding.dart';
import '../modules/halaqah-ummi-grading/views/halaqah_ummi_grading_view.dart';
import '../modules/halaqah-ummi-riwayat-pengampu/bindings/halaqah_ummi_riwayat_pengampu_binding.dart';
import '../modules/halaqah-ummi-riwayat-pengampu/views/halaqah_ummi_riwayat_pengampu_view.dart';
import '../modules/halaqah_dashboard_pengampu/bindings/halaqah_dashboard_pengampu_binding.dart';
import '../modules/halaqah_dashboard_pengampu/views/halaqah_dashboard_pengampu_view.dart';
import '../modules/halaqah_grading/bindings/halaqah_grading_binding.dart';
import '../modules/halaqah_grading/views/halaqah_grading_view.dart';
import '../modules/halaqah_management/bindings/halaqah_management_binding.dart';
import '../modules/halaqah_management/views/halaqah_management_view.dart';
import '../modules/halaqah_riwayat_pengampu/bindings/halaqah_riwayat_pengampu_binding.dart';
import '../modules/halaqah_riwayat_pengampu/views/halaqah_riwayat_pengampu_view.dart';
import '../modules/halaqah_set_pengganti/bindings/halaqah_set_pengganti_binding.dart';
import '../modules/halaqah_set_pengganti/views/halaqah_set_pengganti_view.dart';
import '../modules/halaqah_setoran_siswa/bindings/halaqah_setoran_siswa_binding.dart';
import '../modules/halaqah_setoran_siswa/views/halaqah_setoran_siswa_view.dart';
import '../modules/halaqah_ummi_dashboard_koordinator/bindings/halaqah_ummi_dashboard_koordinator_binding.dart';
import '../modules/halaqah_ummi_dashboard_koordinator/views/halaqah_ummi_dashboard_koordinator_view.dart';
import '../modules/halaqah_ummi_grading_massal/bindings/halaqah_ummi_grading_massal_binding.dart';
import '../modules/halaqah_ummi_grading_massal/views/halaqah_ummi_grading_massal_view.dart';
import '../modules/halaqah_ummi_jadwal_penguji/bindings/halaqah_ummi_jadwal_penguji_binding.dart';
import '../modules/halaqah_ummi_jadwal_penguji/views/halaqah_ummi_jadwal_penguji_view.dart';
import '../modules/halaqah_ummi_management/bindings/halaqah_ummi_management_binding.dart';
import '../modules/halaqah_ummi_management/views/halaqah_ummi_management_view.dart';
import '../modules/halaqah_ummi_manajemen_penguji/bindings/halaqah_ummi_manajemen_penguji_binding.dart';
import '../modules/halaqah_ummi_manajemen_penguji/views/halaqah_ummi_manajemen_penguji_view.dart';
import '../modules/halaqah_ummi_set_pengganti/bindings/halaqah_ummi_set_pengganti_binding.dart';
import '../modules/halaqah_ummi_set_pengganti/views/halaqah_ummi_set_pengganti_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/import_pegawai/bindings/import_pegawai_binding.dart';
import '../modules/import_pegawai/views/import_pegawai_view.dart';
import '../modules/import_siswa/bindings/import_siswa_binding.dart';
import '../modules/import_siswa/views/import_siswa_view.dart';
import '../modules/info_sekolah/bindings/info_sekolah_binding.dart';
import '../modules/info_sekolah/views/info_sekolah_view.dart';
import '../modules/info_sekolah_detail/bindings/info_sekolah_detail_binding.dart';
import '../modules/info_sekolah_detail/views/info_sekolah_detail_view.dart';
import '../modules/info_sekolah_form/bindings/info_sekolah_form_binding.dart';
import '../modules/info_sekolah_form/views/info_sekolah_form_view.dart';
import '../modules/input_nilai_massal_akademik/bindings/input_nilai_massal_akademik_binding.dart';
import '../modules/input_nilai_massal_akademik/views/input_nilai_massal_akademik_view.dart';
import '../modules/input_nilai_siswa/bindings/input_nilai_siswa_binding.dart';
import '../modules/input_nilai_siswa/views/input_nilai_siswa_view.dart';
import '../modules/jadwal_pelajaran/bindings/jadwal_pelajaran_binding.dart';
import '../modules/jadwal_pelajaran/views/jadwal_pelajaran_view.dart';
import '../modules/jurnal_harian_guru/bindings/jurnal_harian_guru_binding.dart';
import '../modules/jurnal_harian_guru/views/jurnal_harian_guru_view.dart';
import '../modules/kelompok_halaqoh/bindings/kelompok_halaqoh_binding.dart';
import '../modules/kelompok_halaqoh/views/kelompok_halaqoh_view.dart';
import '../modules/laporan_akademik/bindings/laporan_akademik_binding.dart';
import '../modules/laporan_akademik/views/laporan_akademik_view.dart';
import '../modules/laporan_halaqah/bindings/laporan_halaqah_binding.dart';
import '../modules/laporan_halaqah/views/laporan_halaqah_view.dart';
import '../modules/laporan_jurnal_kelas/bindings/laporan_jurnal_kelas_binding.dart';
import '../modules/laporan_jurnal_kelas/views/laporan_jurnal_kelas_view.dart';
import '../modules/laporan_jurnal_pribadi/bindings/laporan_jurnal_pribadi_binding.dart';
import '../modules/laporan_jurnal_pribadi/views/laporan_jurnal_pribadi_view.dart';
import '../modules/laporan_keuangan/bindings/laporan_keuangan_binding.dart';
import '../modules/laporan_keuangan/views/laporan_keuangan_view.dart';
import '../modules/laporan_keuangan_sekolah/bindings/laporan_keuangan_sekolah_binding.dart';
import '../modules/laporan_keuangan_sekolah/views/laporan_keuangan_sekolah_view.dart';
import '../modules/laporan_komite_pimpinan/bindings/laporan_komite_pimpinan_binding.dart';
import '../modules/laporan_komite_pimpinan/views/laporan_komite_pimpinan_view.dart';
import '../modules/laporan_perubahan_up/bindings/laporan_perubahan_up_binding.dart';
import '../modules/laporan_perubahan_up/views/laporan_perubahan_up_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/manajemen_anggaran/bindings/manajemen_anggaran_binding.dart';
import '../modules/manajemen_anggaran/views/manajemen_anggaran_view.dart';
import '../modules/manajemen_dashboard/bindings/manajemen_dashboard_binding.dart';
import '../modules/manajemen_dashboard/views/manajemen_dashboard_view.dart';
import '../modules/manajemen_kalender_akademik/bindings/manajemen_kalender_akademik_binding.dart';
import '../modules/manajemen_kalender_akademik/views/manajemen_kalender_akademik_view.dart';
import '../modules/manajemen_kategori_keuangan/bindings/manajemen_kategori_keuangan_binding.dart';
import '../modules/manajemen_kategori_keuangan/views/manajemen_kategori_keuangan_view.dart';
import '../modules/manajemen_komite/bindings/manajemen_komite_binding.dart';
import '../modules/manajemen_komite/views/manajemen_komite_view.dart';
import '../modules/manajemen_penawaran_buku/bindings/manajemen_penawaran_buku_binding.dart';
import '../modules/manajemen_penawaran_buku/views/manajemen_penawaran_buku_view.dart';
import '../modules/manajemen_pendaftaran_buku/bindings/manajemen_pendaftaran_buku_binding.dart';
import '../modules/manajemen_pendaftaran_buku/views/manajemen_pendaftaran_buku_view.dart';
import '../modules/manajemen_peran/bindings/manajemen_peran_binding.dart';
import '../modules/manajemen_peran/views/manajemen_peran_view.dart';
import '../modules/manajemen_tugas/bindings/manajemen_tugas_binding.dart';
import '../modules/manajemen_tugas/views/manajemen_tugas_view.dart';
import '../modules/manajemen_tunggakan_awal/bindings/manajemen_tunggakan_awal_binding.dart';
import '../modules/manajemen_tunggakan_awal/views/manajemen_tunggakan_awal_view.dart';
import '../modules/marketplace/bindings/marketplace_binding.dart';
import '../modules/marketplace/views/marketplace_view.dart';
import '../modules/master_ekskul_management/bindings/master_ekskul_management_binding.dart';
import '../modules/master_ekskul_management/views/master_ekskul_management_view.dart';
import '../modules/master_jam/bindings/master_jam_binding.dart';
import '../modules/master_jam/views/master_jam_view.dart';
import '../modules/master_mapel/bindings/master_mapel_binding.dart';
import '../modules/master_mapel/views/master_mapel_view.dart';
import '../modules/modul_ajar_form/bindings/modul_ajar_form_binding.dart';
import '../modules/modul_ajar_form/views/modul_ajar_form_view.dart';
import '../modules/new_password/bindings/new_password_binding.dart';
import '../modules/new_password/views/new_password_view.dart';
import '../modules/onboarding_school/bindings/onboarding_school_binding.dart';
import '../modules/onboarding_school/views/onboarding_school_view.dart';
import '../modules/pegawai/bindings/pegawai_binding.dart';
import '../modules/pegawai/views/pegawai_view.dart';
import '../modules/pemberian_kelas_siswa/bindings/pemberian_kelas_siswa_binding.dart';
import '../modules/pemberian_kelas_siswa/views/pemberian_kelas_siswa_view.dart';
import '../modules/pengaturan_akademik/bindings/pengaturan_akademik_binding.dart';
import '../modules/pengaturan_akademik/views/pengaturan_akademik_view.dart';
import '../modules/pengaturan_alasan_keuangan/bindings/pengaturan_alasan_keuangan_binding.dart';
import '../modules/pengaturan_alasan_keuangan/views/pengaturan_alasan_keuangan_view.dart';
import '../modules/pengaturan_biaya/bindings/pengaturan_biaya_binding.dart';
import '../modules/pengaturan_biaya/views/pengaturan_biaya_view.dart';
import '../modules/pengaturan_bobot_nilai/bindings/pengaturan_bobot_nilai_binding.dart';
import '../modules/pengaturan_bobot_nilai/views/pengaturan_bobot_nilai_view.dart';
import '../modules/penugasan_guru/bindings/penugasan_guru_binding.dart';
import '../modules/penugasan_guru/views/penugasan_guru_view.dart';
import '../modules/perangkat_ajar/bindings/perangkat_ajar_binding.dart';
import '../modules/perangkat_ajar/views/perangkat_ajar_view.dart';
import '../modules/pindah_siswa_halaqah/bindings/pindah_siswa_halaqah_binding.dart';
import '../modules/pindah_siswa_halaqah/views/pindah_siswa_halaqah_view.dart';
import '../modules/printer_settings/bindings/printer_settings_binding.dart';
import '../modules/printer_settings/views/printer_settings_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/proses_kenaikan_kelas/bindings/proses_kenaikan_kelas_binding.dart';
import '../modules/proses_kenaikan_kelas/views/proses_kenaikan_kelas_view.dart';
import '../modules/prota_prosem/bindings/prota_prosem_binding.dart';
import '../modules/prota_prosem/views/prota_prosem_view.dart';
import '../modules/pusat_informasi_penggantian/bindings/pusat_informasi_penggantian_binding.dart';
import '../modules/pusat_informasi_penggantian/views/pusat_informasi_penggantian_view.dart';
import '../modules/rapor_siswa/bindings/rapor_siswa_binding.dart';
import '../modules/rapor_siswa/views/rapor_siswa_view.dart';
import '../modules/rekap_absensi/bindings/rekap_absensi_binding.dart';
import '../modules/rekap_absensi/views/rekap_absensi_view.dart';
import '../modules/rekap_jurnal_admin/bindings/rekap_jurnal_admin_binding.dart';
import '../modules/rekap_jurnal_admin/views/rekap_jurnal_admin_view.dart';
import '../modules/rekap_jurnal_guru/bindings/rekap_jurnal_guru_binding.dart';
import '../modules/rekap_jurnal_guru/views/rekap_jurnal_guru_view.dart';
import '../modules/rincian_tunggakan/bindings/rincian_tunggakan_binding.dart';
import '../modules/rincian_tunggakan/views/rincian_tunggakan_view.dart';
import '../modules/root/bindings/root_binding.dart';
import '../modules/root/views/root_view.dart';
import '../modules/tampilkan_info_sekolah/bindings/tampilkan_info_sekolah_binding.dart';
import '../modules/tampilkan_info_sekolah/views/tampilkan_info_sekolah_view.dart';
import '../modules/upsert_pegawai/bindings/upsert_pegawai_binding.dart';
import '../modules/upsert_pegawai/views/upsert_pegawai_view.dart';
import '../modules/upsert_siswa/bindings/upsert_siswa_binding.dart';
import '../modules/upsert_siswa/views/upsert_siswa_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.ROOT;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () =>
          const HomeView(), // Pastikan HomeView adalah const jika memungkinkan
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.PEMBERIAN_KELAS_SISWA,
      page: () => PemberianKelasSiswaView(),
      binding: PemberianKelasSiswaBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: _Paths.NEW_PASSWORD,
      page: () => const NewPasswordView(),
      binding: NewPasswordBinding(),
    ),
    GetPage(
      name: _Paths.JADWAL_PELAJARAN,
      page: () => const JadwalPelajaranView(),
      binding: JadwalPelajaranBinding(),
    ),
    GetPage(
      name: _Paths.BUAT_SARPRAS,
      page: () => const BuatSarprasView(),
      binding: BuatSarprasBinding(),
    ),
    GetPage(
      name: _Paths.DATA_SARPRAS,
      page: () => const DataSarprasView(),
      binding: DataSarprasBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PERKELAS,
      page: () => DaftarSiswaPerkelasView(),
      binding: DaftarSiswaPerkelasBinding(),
    ),
    GetPage(
      name: _Paths.TAMPILKAN_INFO_SEKOLAH,
      page: () => const TampilkanInfoSekolahView(),
      binding: TampilkanInfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PERMAPEL,
      page: () => DaftarSiswaPermapelView(),
      binding: DaftarSiswaPermapelBinding(),
    ),
    GetPage(
      name: _Paths.KELOMPOK_HALAQOH,
      page: () => KelompokHalaqohView(),
      binding: KelompokHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_NILAI,
      page: () => DaftarNilaiView(),
      binding: DaftarNilaiBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PINDAH_HALAQOH,
      page: () => const DaftarSiswaPindahHalaqohView(),
      binding: DaftarSiswaPindahHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH_DETAIL,
      page: () => const InfoSekolahDetailView(),
      binding: InfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_NILAI_SISWA,
      page: () => InputNilaiSiswaView(),
      binding: InputNilaiSiswaBinding(),
    ),
    GetPage(
      name: _Paths.RAPOR_SISWA,
      page: () => const RaporSiswaView(),
      binding: RaporSiswaBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_JURNAL_GURU,
      page: () => const RekapJurnalGuruView(),
      binding: RekapJurnalGuruBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_JURNAL_ADMIN,
      page: () => const RekapJurnalAdminView(),
      binding: RekapJurnalAdminBinding(),
    ),
    GetPage(
      name: _Paths.IMPORT_PEGAWAI,
      page: () => const ImportPegawaiView(),
      binding: ImportPegawaiBinding(),
    ),
    GetPage(
      name: _Paths.ROOT,
      page: () => const RootView(),
      binding: RootBinding(), // <-- INI PERBAIKANNYA!
    ),
    GetPage(
      name: _Paths.PEGAWAI,
      page: () => const PegawaiView(),
      binding: PegawaiBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_PERAN,
      page: () => const ManajemenPeranView(),
      binding: ManajemenPeranBinding(),
    ),
    GetPage(
      name: _Paths.UPSERT_PEGAWAI,
      page: () => const UpsertPegawaiView(),
      binding: UpsertPegawaiBinding(),
    ),
    GetPage(
      name: _Paths.IMPORT_SISWA,
      page: () => const ImportSiswaView(),
      binding: ImportSiswaBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA,
      page: () => const DaftarSiswaView(),
      binding: DaftarSiswaBinding(),
    ),
    GetPage(
      name: _Paths.UPSERT_SISWA,
      page: () => const UpsertSiswaView(),
      binding: UpsertSiswaBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_MAPEL,
      page: () => const MasterMapelView(),
      binding: MasterMapelBinding(),
    ),
    GetPage(
      name: _Paths.PENUGASAN_GURU,
      page: () => const PenugasanGuruView(),
      binding: PenugasanGuruBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_JAM,
      page: () => const MasterJamView(),
      binding: MasterJamBinding(),
    ),
    GetPage(
      name: _Paths.EDITOR_JADWAL,
      page: () => const EditorJadwalView(),
      binding: EditorJadwalBinding(),
    ),
    GetPage(
      name: _Paths.GURU_AKADEMIK,
      page: () => const GuruAkademikView(),
      binding: GuruAkademikBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_NILAI_MASSAL_AKADEMIK,
      page: () => const InputNilaiMassalAkademikView(),
      binding: InputNilaiMassalAkademikBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_MANAGEMENT,
      page: () => const HalaqahManagementView(),
      binding: HalaqahManagementBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_EDIT_HALAQAH_GROUP,
      page: () => const CreateEditHalaqahGroupView(),
      binding: CreateEditHalaqahGroupBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_DASHBOARD_PENGAMPU,
      page: () => const HalaqahDashboardPengampuView(),
      binding: HalaqahDashboardPengampuBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_GRADING,
      page: () => const HalaqahGradingView(),
      binding: HalaqahGradingBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_RIWAYAT_PENGAMPU,
      page: () => const HalaqahRiwayatPengampuView(),
      binding: HalaqahRiwayatPengampuBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_SETORAN_SISWA,
      page: () => const HalaqahSetoranSiswaView(),
      binding: HalaqahSetoranSiswaBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_SET_PENGGANTI,
      page: () => const HalaqahSetPenggantiView(),
      binding: HalaqahSetPenggantiBinding(),
    ),
    GetPage(
      name: _Paths.JURNAL_HARIAN_GURU,
      page: () => const JurnalHarianGuruView(),
      binding: JurnalHarianGuruBinding(),
    ),
    GetPage(
      name: _Paths.ABSENSI_WALI_KELAS,
      page: () => const AbsensiWaliKelasView(),
      binding: AbsensiWaliKelasBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_ABSENSI,
      page: () => const RekapAbsensiView(),
      binding: RekapAbsensiBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_EKSKUL_MANAGEMENT,
      page: () => const MasterEkskulManagementView(),
      binding: MasterEkskulManagementBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_EDIT_EKSKUL,
      page: () => const CreateEditEkskulView(),
      binding: CreateEditEkskulBinding(),
    ),
    GetPage(
      name: _Paths.EKSKUL_PENDAFTARAN_MANAGEMENT,
      page: () => const EkskulPendaftaranManagementView(),
      binding: EkskulPendaftaranManagementBinding(),
    ),
    GetPage(
      name: _Paths.ATUR_GURU_PENGGANTI,
      page: () => const AturGuruPenggantiView(),
      binding: AturGuruPenggantiBinding(),
    ),
    GetPage(
      name: _Paths.ATUR_PENGGANTIAN_HOST,
      page: () => const AturPenggantianHostView(),
      binding: AturPenggantianHostBinding(),
    ),
    GetPage(
      name: _Paths.ATUR_PENGGANTIAN_RENTANG,
      page: () => const AturPenggantianRentangView(),
      binding: AturPenggantianRentangBinding(),
    ),
    GetPage(
      name: _Paths.PUSAT_INFORMASI_PENGGANTIAN,
      page: () => const PusatInformasiPenggantianView(),
      binding: PusatInformasiPenggantianBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_JURNAL_PRIBADI,
      page: () => const LaporanJurnalPribadiView(),
      binding: LaporanJurnalPribadiBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_JURNAL_KELAS,
      page: () => const LaporanJurnalKelasView(),
      binding: LaporanJurnalKelasBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_KALENDER_AKADEMIK,
      page: () => const ManajemenKalenderAkademikView(),
      binding: ManajemenKalenderAkademikBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH,
      page: () => const InfoSekolahView(),
      binding: InfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH_FORM,
      page: () => const InfoSekolahFormView(),
      binding: InfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.ATP_FORM,
      page: () => const AtpFormView(),
      binding: AtpFormBinding(),
    ),
    GetPage(
      name: _Paths.PERANGKAT_AJAR,
      page: () => const PerangkatAjarView(),
      binding: PerangkatAjarBinding(),
    ),
    GetPage(
      name: _Paths.PROTA_PROSEM,
      page: () => const ProtaProsemView(),
      binding: ProtaProsemBinding(),
    ),
    GetPage(
      name: _Paths.MODUL_AJAR_FORM,
      page: () => const ModulAjarFormView(),
      binding: ModulAjarFormBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.PENGATURAN_BOBOT_NILAI,
      page: () => const PengaturanBobotNilaiView(),
      binding: PengaturanBobotNilaiBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_AKADEMIK,
      page: () => const LaporanAkademikView(),
      binding: LaporanAkademikBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_HALAQAH,
      page: () => const LaporanHalaqahView(),
      binding: LaporanHalaqahBinding(),
    ),
    GetPage(
      name: _Paths.MARKETPLACE,
      page: () => const MarketplaceView(),
      binding: MarketplaceBinding(),
    ),
    GetPage(
      name: _Paths.PENGATURAN_AKADEMIK,
      page: () => const PengaturanAkademikView(),
      binding: PengaturanAkademikBinding(),
    ),
    GetPage(
      name: _Paths.PROSES_KENAIKAN_KELAS,
      page: () => const ProsesKenaikanKelasView(),
      binding: ProsesKenaikanKelasBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING_SCHOOL,
      page: () => const OnboardingSchoolView(),
      binding: OnboardingSchoolBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_TUGAS,
      page: () => const ManajemenTugasView(),
      binding: ManajemenTugasBinding(),
    ),
    GetPage(
      name: _Paths.PENGATURAN_BIAYA,
      page: () => const PengaturanBiayaView(),
      binding: PengaturanBiayaBinding(),
    ),
    GetPage(
      name: _Paths.BUAT_TAGIHAN_TAHUNAN,
      page: () => const BuatTagihanTahunanView(),
      binding: BuatTagihanTahunanBinding(),
    ),
    GetPage(
      name: _Paths.DETAIL_KEUANGAN_SISWA,
      page: () => const DetailKeuanganSiswaView(),
      binding: DetailKeuanganSiswaBinding(),
    ),
    GetPage(
      name: _Paths.CARI_SISWA_KEUANGAN,
      page: () => const CariSiswaKeuanganView(),
      binding: CariSiswaKeuanganBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_PENAWARAN_BUKU,
      page: () => const ManajemenPenawaranBukuView(),
      binding: ManajemenPenawaranBukuBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_EDIT_BUKU,
      page: () => const CreateEditBukuView(),
      binding: CreateEditBukuBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_PENDAFTARAN_BUKU,
      page: () => const ManajemenPendaftaranBukuView(),
      binding: ManajemenPendaftaranBukuBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_KEUANGAN,
      page: () => const LaporanKeuanganView(),
      binding: LaporanKeuanganBinding(),
    ),
    GetPage(
      name: _Paths.RINCIAN_TUNGGAKAN,
      page: () => const RincianTunggakanView(),
      binding: RincianTunggakanBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_KOMITE,
      page: () => const ManajemenKomiteView(),
      binding: ManajemenKomiteBinding(),
    ),
    GetPage(
      name: _Paths.FINANCIAL_DASHBOARD_PIMPINAN,
      page: () => const FinancialDashboardPimpinanView(),
      binding: FinancialDashboardPimpinanBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_KOMITE_PIMPINAN,
      page: () => const LaporanKomitePimpinanView(),
      binding: LaporanKomitePimpinanBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_MANAGEMENT,
      page: () => const HalaqahUmmiManagementView(),
      binding: HalaqahUmmiManagementBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_EDIT_HALAQAH_UMMI_GROUP,
      page: () => const CreateEditHalaqahUmmiGroupView(),
      binding: CreateEditHalaqahUmmiGroupBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_DASHBOARD_PENGAMPU,
      page: () => const HalaqahUmmiDashboardPengampuView(),
      binding: HalaqahUmmiDashboardPengampuBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_GRADING,
      page: () => const HalaqahUmmiGradingView(),
      binding: HalaqahUmmiGradingBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_RIWAYAT_PENGAMPU,
      page: () => const HalaqahUmmiRiwayatPengampuView(),
      binding: HalaqahUmmiRiwayatPengampuBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_GRADING_MASSAL,
      page: () => const HalaqahUmmiGradingMassalView(),
      binding: HalaqahUmmiGradingMassalBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_MANAJEMEN_PENGUJI,
      page: () => const HalaqahUmmiManajemenPengujiView(),
      binding: HalaqahUmmiManajemenPengujiBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_DASHBOARD_KOORDINATOR,
      page: () => const HalaqahUmmiDashboardKoordinatorView(),
      binding: HalaqahUmmiDashboardKoordinatorBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_JADWAL_PENGUJI,
      page: () => const HalaqahUmmiJadwalPengujiView(),
      binding: HalaqahUmmiJadwalPengujiBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_UMMI_SET_PENGGANTI,
      page: () => const HalaqahUmmiSetPenggantiView(),
      binding: HalaqahUmmiSetPenggantiBinding(),
    ),
    GetPage(
      name: _Paths.PENGATURAN_ALASAN_KEUANGAN,
      page: () => const PengaturanAlasanKeuanganView(),
      binding: PengaturanAlasanKeuanganBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_PERUBAHAN_UP,
      page: () => const LaporanPerubahanUpView(),
      binding: LaporanPerubahanUpBinding(),
    ),
    GetPage(
      name: _Paths.PINDAH_SISWA_HALAQAH,
      page: () => const PindahSiswaHalaqahView(),
      binding: PindahSiswaHalaqahBinding(),
    ),
    GetPage(
      name: _Paths.PRINTER_SETTINGS,
      page: () => const PrinterSettingsView(),
      binding: PrinterSettingsBinding(),
    ),
    GetPage(
      name: _Paths.ALOKASI_PEMBAYARAN,
      page: () => const AlokasiPembayaranView(),
      binding: AlokasiPembayaranBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_DASHBOARD,
      page: () => const ManajemenDashboardView(),
      binding: ManajemenDashboardBinding(),
    ),
    GetPage(
      name: _Paths.CATATAN_BK_LIST,
      page: () => const CatatanBkListView(),
      binding: CatatanBkBinding(),
    ),
    GetPage(
      name: _Paths.CATATAN_BK_DETAIL,
      page: () => const CatatanBkDetailView(),
      binding: CatatanBkBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD_BK,
      page: () => const DashboardBkView(),
      binding: DashboardBkBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_TUNGGAKAN_AWAL,
      page: () => const ManajemenTunggakanAwalView(),
      binding: ManajemenTunggakanAwalBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_KATEGORI_KEUANGAN,
      page: () => const ManajemenKategoriKeuanganView(),
      binding: ManajemenKategoriKeuanganBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_KEUANGAN_SEKOLAH,
      page: () => const LaporanKeuanganSekolahView(),
      binding: LaporanKeuanganSekolahBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_ANGGARAN,
      page: () => const ManajemenAnggaranView(),
      binding: ManajemenAnggaranBinding(),
    ),
  ];
}
