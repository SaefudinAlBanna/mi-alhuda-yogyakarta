// lib/app/modules/import_pegawai/controllers/import_pegawai_controller.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImportPegawaiController extends GetxController {
  // final isLoading = false.obs;
  // final isDownloading = false.obs;
  // final RxString selectedFileName = 'Tidak ada file dipilih'.obs;
  // final RxInt totalRows = 0.obs;
  // final RxInt processedRows = 0.obs;
  // final RxInt successCount = 0.obs;
  // final RxInt errorCount = 0.obs;
  // final RxList<String> errorDetails = <String>[].obs;

  // late TextEditingController passAdminC;
  
  // FirebaseAuth auth = FirebaseAuth.instance;
  // FirebaseFirestore firestore = FirebaseFirestore.instance;
  // String idSekolah = "P9984539";
  
  // final Rx<PlatformFile?> pickedFile = Rx<PlatformFile?>(null);

  // @override
  // void onInit() {
  //   super.onInit();
  //   passAdminC = TextEditingController();
  // }

  // @override
  // void onClose() {
  //   passAdminC.dispose();
  //   super.onClose();
  // }

  // void resetState() {
  //   isLoading.value = false;
  //   selectedFileName.value = 'Tidak ada file dipilih';
  //   totalRows.value = 0;
  //   processedRows.value = 0;
  //   successCount.value = 0;
  //   errorCount.value = 0;
  //   errorDetails.clear();
  //   pickedFile.value = null;
  // }

  // Future<void> pickFile() async {
  //   resetState();
  //   final result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['xlsx'],
  //   );
  //   if (result != null) {
  //     pickedFile.value = result.files.first;
  //     selectedFileName.value = pickedFile.value!.name;
  //   }
  // }

  // void startImport() {
  //   if (pickedFile.value == null) {
  //     Get.snackbar("Gagal", "Silakan pilih file Excel terlebih dahulu.");
  //     return;
  //   }

  //   Get.defaultDialog(
  //     title: 'Verifikasi Admin',
  //     content: Column(
  //       children: [
  //         const Text('Masukkan password Anda untuk melanjutkan proses import.'),
  //         const SizedBox(height: 10),
  //         TextField(
  //           controller: passAdminC,
  //           obscureText: true,
  //           autocorrect: false,
  //           decoration: const InputDecoration(
  //             border: OutlineInputBorder(),
  //             labelText: 'Password Admin',
  //           ),
  //         ),
  //       ],
  //     ),
  //     confirm: Obx(() => ElevatedButton(
  //           onPressed: isLoading.value ? null : _processExcel,
  //           child: Text(isLoading.value ? 'MEMPROSES...' : 'Mulai Import'),
  //         )),
  //     cancel: TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
  //   );
  // }

  // Future<void> _processExcel() async {
  //   if (passAdminC.text.isEmpty) {
  //     Get.snackbar("Gagal", "Password admin wajib diisi.");
  //     return;
  //   }

  //   final String? emailAdmin = auth.currentUser?.email;
  //   if (emailAdmin == null) {
  //     Get.snackbar("Error", "Sesi admin tidak valid. Silakan login ulang.");
  //     return;
  //   }
    
  //   isLoading.value = true;
  //   final adminPassword = passAdminC.text;

  //   try {
  //     var bytes = File(pickedFile.value!.path!).readAsBytesSync();
  //     var excel = Excel.decodeBytes(bytes);
  //     var sheet = excel.tables[excel.tables.keys.first]!;
      
  //     if (sheet.rows.isEmpty || 
  //         sheet.rows.first[0]?.value.toString().trim() != 'Nama' ||
  //         sheet.rows.first[1]?.value.toString().trim() != 'Email' ||
  //         sheet.rows.first[2]?.value.toString().trim() != 'Jabatan') {
  //       throw Exception("Format file tidak sesuai. Pastikan kolom pertama adalah Nama, kedua Email, dan ketiga Jabatan.");
  //     }
      
  //     totalRows.value = sheet.maxRows - 1;

  //     for (var i = 1; i < sheet.maxRows; i++) {
  //       processedRows.value = i;
  //       var row = sheet.rows[i];

  //       final nama = row[0]?.value?.toString().trim();
  //       final email = row[1]?.value?.toString().trim();
  //       final jabatan = row[2]?.value?.toString().trim();

  //       if (nama == null || email == null || jabatan == null || nama.isEmpty || email.isEmpty || jabatan.isEmpty) {
  //         errorCount.value++;
  //         errorDetails.add("Baris ${i + 1}: Data tidak lengkap.");
  //         continue;
  //       }

  //       try {
  //         UserCredential pegawaiCredential = await auth.createUserWithEmailAndPassword(email: email, password: 'telagailmu');
          
  //         // --- PENAMBAHAN PENTING DI SINI ---
  //         // Kirim email verifikasi ke pegawai yang baru dibuat
  //         await pegawaiCredential.user!.sendEmailVerification();
  //         // --- AKHIR PENAMBAHAN ---
          
  //         await auth.signInWithEmailAndPassword(email: emailAdmin, password: adminPassword);
          
  //         if (pegawaiCredential.user != null) {
  //           await firestore.collection("Sekolah").doc(idSekolah).collection('pegawai').doc(pegawaiCredential.user!.uid).set({
  //             "nama": nama, "email": email, "role": jabatan, "uid": pegawaiCredential.user!.uid,
  //             "alias": nama, "jeniskelamin": null, "nip": null, "telepon": null,
  //             "alamat": null, "tglgabung": null, "tanggalinput": DateTime.now().toIso8601String(),
  //             "emailpenginput": emailAdmin, "profileImageUrl": null,
  //           });
  //           successCount.value++;
  //         }
  //       } on FirebaseAuthException catch (e) {
  //           errorCount.value++;
  //           String errorMsg = e.code == 'email-already-in-use' ? "Email sudah terdaftar." : "Gagal membuat user.";
  //           errorDetails.add("Baris ${i + 1} ($email): $errorMsg");
  //           await auth.signInWithEmailAndPassword(email: emailAdmin, password: adminPassword);
  //       }
  //     }
  //     Get.back();
  //     Get.snackbar("Selesai", "Proses import selesai. ${successCount.value} berhasil, ${errorCount.value} gagal.", duration: const Duration(seconds: 5));

  //   } catch (e) {
  //     Get.back();
  //     resetState();
  //     Get.snackbar("Error Fatal", "Gagal memproses file: ${e.toString()}");
  //   } finally {
  //     isLoading.value = false;
  //     passAdminC.clear();
  //   }
  // }

  // Future<void> downloadTemplate() async {
  //   isDownloading.value = true;
  //   try {
  //     var excel = Excel.createExcel();
  //     Sheet sheetObject = excel['Sheet1'];

  //     CellStyle headerStyle = CellStyle(bold: true);
      
  //     var cellNama = sheetObject.cell(CellIndex.indexByString("A1"));
  //     cellNama.value = TextCellValue("Nama");
  //     cellNama.cellStyle = headerStyle;

  //     var cellEmail = sheetObject.cell(CellIndex.indexByString("B1"));
  //     cellEmail.value = TextCellValue("Email");
  //     cellEmail.cellStyle = headerStyle;

  //     var cellJabatan = sheetObject.cell(CellIndex.indexByString("C1"));
  //     cellJabatan.value = TextCellValue("Jabatan");
  //     cellJabatan.cellStyle = headerStyle;
      
  //     sheetObject.appendRow([
  //       TextCellValue("Contoh Nama Pegawai"),
  //       TextCellValue("contoh@email.com"),
  //       TextCellValue("Guru Kelas")
  //     ]);

  //     String? outputFile = await FilePicker.platform.saveFile(
  //       dialogTitle: 'Simpan Template Pegawai',
  //       fileName: 'template_import_pegawai.xlsx',
  //       type: FileType.custom,
  //       allowedExtensions: ['xlsx'],
  //     );

  //     if (outputFile != null) {
  //       List<int>? fileBytes = excel.encode();
  //       if (fileBytes != null) {
  //         File(outputFile)
  //           ..createSync(recursive: true)
  //           ..writeAsBytesSync(fileBytes);
          
  //         Get.snackbar("Berhasil", "Template berhasil diunduh.",
  //           snackPosition: SnackPosition.BOTTOM,
  //           backgroundColor: Colors.green,
  //           colorText: Colors.white,
  //         );
  //       }
  //     } else {
  //       print("Pengguna membatalkan penyimpanan file.");
  //     }

  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal membuat template: $e");
  //   } finally {
  //     isDownloading.value = false;
  //   }
  // }
}