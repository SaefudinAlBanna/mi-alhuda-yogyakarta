// lib/app/modules/import_siswa/controllers/import_siswa_controller.dart (SEKOLAH - DIPERBAIKI)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';

class ImportSiswaController extends GetxController {
  // --- DEPENDENSI ---
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // --- STATE UI & PROSES ---
  final isLoading = false.obs;
  final isDownloading = false.obs;
  final RxString selectedFileName = 'Tidak ada file dipilih'.obs;
  final Rx<PlatformFile?> pickedFile = Rx<PlatformFile?>(null);

  // --- STATE HASIL IMPORT ---
  final RxInt totalRows = 0.obs;
  final RxInt processedRows = 0.obs;
  final RxInt successCount = 0.obs;
  final RxInt errorCount = 0.obs;
  final RxList<String> errorDetails = <String>[].obs;

  late TextEditingController passAdminC;

  @override
  void onInit() {
    super.onInit();
    passAdminC = TextEditingController();
  }

  @override
  void onClose() {
    passAdminC.dispose();
    super.onClose();
  }

  void resetState() {
    isLoading.value = false;
    selectedFileName.value = 'Tidak ada file dipilih';
    totalRows.value = 0;
    processedRows.value = 0;
    successCount.value = 0;
    errorCount.value = 0;
    errorDetails.clear();
    pickedFile.value = null;
  }

  Future<void> pickFile() async {
    resetState();
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null) {
      pickedFile.value = result.files.first;
      selectedFileName.value = pickedFile.value!.name;
    }
  }

  void startImport() {
    if (pickedFile.value == null) {
      Get.snackbar("Gagal", "Silakan pilih file Excel terlebih dahulu.");
      return;
    }
    Get.defaultDialog(
      title: 'Verifikasi Admin',
      content: TextField(controller: passAdminC, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Password Admin')),
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(onPressed: _processExcel, child: const Text('Mulai Import')),
      ],
    );
  }

  Future<void> _processExcel() async {
    isLoading.value = true;
    Get.back();
    final adminEmail = _auth.currentUser?.email;
    final adminPassword = passAdminC.text;

    if (adminEmail == null || adminPassword.isEmpty) {
      Get.snackbar('Gagal', 'Sesi admin tidak valid atau password kosong.');
      isLoading.value = false;
      return;
    }

    configC.isCreatingNewUser.value = true;

    try {
      await _auth.currentUser!.reauthenticateWithCredential(EmailAuthProvider.credential(email: adminEmail, password: adminPassword));
      
      var bytes = File(pickedFile.value!.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      var sheet = excel.tables[excel.tables.keys.first]!;
      
      if (sheet.rows.isEmpty || 
          sheet.rows.first[0]?.value.toString().trim() != 'NISN' ||
          sheet.rows.first[1]?.value.toString().trim() != 'Nama' ||
          sheet.rows.first[2]?.value.toString().trim() != 'SPP') {
        throw Exception("Format file tidak sesuai. Header harus: NISN, Nama, SPP.");
      }
      
      totalRows.value = sheet.maxRows - 1;

      for (var i = 1; i < sheet.maxRows; i++) {
        processedRows.value = i;
        var row = sheet.rows[i];
        final nisn = row[0]?.value?.toString().trim();
        final nama = row[1]?.value?.toString().trim();
        final spp = num.tryParse(row[2]?.value?.toString().trim() ?? '') ?? 0;

        if (nisn == null || nama == null || nisn.isEmpty || nama.isEmpty) {
          errorCount.value++;
          errorDetails.add("Baris ${i + 1}: Data NISN/Nama kosong.");
          continue;
        }

        final String emailSiswa = "$nisn@telagailmu.com";

        try {
          UserCredential siswaCredential = await _auth.createUserWithEmailAndPassword(email: emailSiswa, password: 'telagailmu');
          
          // --- PERBAIKAN KRUSIAL: REBUT KEMBALI SESI ADMIN DI DALAM LOOP ---
          await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);
          
          String uidSiswa = siswaCredential.user!.uid;
          final dataToSave = {
              "uid": uidSiswa, "nisn": nisn, "namaLengkap": nama, "email": emailSiswa, "spp": spp,
              "isProfileComplete": false, "mustChangePassword": true, "statusSiswa": "Aktif",
              "createdAt": FieldValue.serverTimestamp(), "createdBy": adminEmail,
              'kelasId': null,
          };
          await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('siswa').doc(uidSiswa).set(dataToSave);
          successCount.value++;
          
        } on FirebaseAuthException catch (e) {
            errorCount.value++;
            String errorMsg = e.code == 'email-already-in-use' ? "NISN (email) sudah ada." : "Gagal membuat user Auth.";
            errorDetails.add("Baris ${i + 1} ($nisn): $errorMsg");
            // Pastikan sesi admin tetap aktif bahkan jika ada error
            await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);
        }
      }
      
      Get.snackbar("Selesai", "Proses import selesai. ${successCount.value} berhasil, ${errorCount.value} gagal.", duration: const Duration(seconds: 5));

    } catch (e) {
      Get.snackbar("Error Fatal", "Proses dihentikan: ${e.toString()}");
    } finally {
      isLoading.value = false;
      passAdminC.clear();
      configC.isCreatingNewUser.value = false;
    }
  }

  Future<void> downloadTemplate() async {
    // ... (fungsi downloadTemplate tidak berubah)
    isDownloading.value = true;
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
      var headers = ["NISN", "Nama", "SPP"];
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      sheetObject.appendRow([
        TextCellValue("1234567890"),
        TextCellValue("Fulan bin Fulan"),
        IntCellValue(250000)
      ]);
      String? outputFile = await FilePicker.platform.saveFile(dialogTitle: 'Simpan Template Siswa', fileName: 'template_import_siswa.xlsx');
      if (outputFile != null) {
        List<int>? fileBytes = excel.encode();
        if (fileBytes != null) {
          File(outputFile)..writeAsBytesSync(fileBytes);
          Get.snackbar("Berhasil", "Template berhasil diunduh.", backgroundColor: Colors.green, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat template: $e");
    } finally {
      isDownloading.value = false;
    }
  }
}