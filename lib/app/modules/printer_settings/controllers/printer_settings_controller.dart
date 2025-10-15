// lib/app/modules/printer_settings/controllers/printer_settings_controller.dart

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mi_alhuda_yogyakarta/app/models/printer_model.dart';
import 'package:mi_alhuda_yogyakarta/app/modules/printer_settings/views/printer_settings_view.dart';
import 'package:permission_handler/permission_handler.dart';
// Import package printer bluetooth dengan alias agar tidak bentrok
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as android_printer;

class PrinterSettingsController extends GetxController {
  final _storage = GetStorage();
  
  final isLoading = false.obs;
  // Daftar semua printer yang pernah disimpan oleh user
  final RxList<PrinterDevice> savedPrinters = <PrinterDevice>[].obs;
  // Printer yang saat ini aktif untuk mencetak
  final Rxn<PrinterDevice> selectedPrinter = Rxn<PrinterDevice>();

  // [BARU] Daftar printer yang ditemukan saat pemindaian (khusus Android)
  final RxList<PrinterDevice> foundPrinters = <PrinterDevice>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPrinters();
  }

  /// Memuat semua data printer dari GetStorage
  void loadPrinters() {
    // Memuat daftar semua printer yang tersimpan
    final List<dynamic>? printerListJson = _storage.read<List<dynamic>>('saved_printers');
    if (printerListJson != null) {
      savedPrinters.assignAll(printerListJson.map((json) => PrinterDevice.fromJson(json)).toList());
    }
    
    // Memuat printer yang terakhir kali dipilih sebagai aktif
    final selectedJson = _storage.read('selected_thermal_printer');
    if (selectedJson != null) {
      selectedPrinter.value = PrinterDevice.fromJson(selectedJson);
    }
  }

  Future<void> scanBluetoothPrinters() async {
    isLoading.value = true;
    foundPrinters.clear();
    try {
      // Pastikan hanya berjalan di Android
      if (!GetPlatform.isAndroid) {
        Get.snackbar("Info", "Pemindaian Bluetooth hanya tersedia di Android.");
        return;
      }

      // Minta Izin Bluetooth
      var statusScan = await Permission.bluetoothScan.request();
      var statusConnect = await Permission.bluetoothConnect.request();

      if (statusScan.isGranted && statusConnect.isGranted) {
        // Jika izin diberikan, baru pindai
        android_printer.BlueThermalPrinter bluetooth = android_printer.BlueThermalPrinter.instance;
        List<android_printer.BluetoothDevice> devices = await bluetooth.getBondedDevices();
        for (var device in devices) {
          foundPrinters.add(PrinterDevice(
            name: "[Bluetooth] ${device.name}",
            // Kita gunakan 'driver' sebagai tipe untuk Bluetooth
            type: PrinterType.driver, 
          ));
        }
        
        // Tampilkan dialog pemilihan hasil pindai
        if (foundPrinters.isNotEmpty) {
          Get.dialog(ScanResultDialog());
        } else {
          Get.snackbar("Tidak Ditemukan", "Tidak ada printer Bluetooth yang sudah di-pairing.");
        }

      } else {
        Get.snackbar("Izin Ditolak", "Aplikasi memerlukan izin Bluetooth untuk memindai printer.");
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memindai printer: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Menambah printer baru ke daftar dan menyimpannya
  void addAndSavePrinter({required String name, required String vid, required String pid}) {
    try {
      // Konversi VID dan PID dari string Hex ke integer
      final int vendorId = int.parse(vid, radix: 16);
      final int productId = int.parse(pid, radix: 16);

      final newPrinter = PrinterDevice(
        name: name,
        type: PrinterType.usb,
        vendorId: vendorId,
        productId: productId,
      );

      // Tambahkan ke daftar jika belum ada
      if (!savedPrinters.any((p) => p.vendorId == vendorId && p.productId == productId)) {
        savedPrinters.add(newPrinter);
        _storage.write('saved_printers', savedPrinters.map((p) => p.toJson()).toList());
      }
      
      // Otomatis pilih printer yang baru ditambahkan sebagai aktif
      selectPrinter(newPrinter);
      Get.back(); // Tutup dialog tambah

    } catch (e) {
      Get.snackbar("Error", "Format VID/PID salah. Harap masukkan dalam format Heksadesimal (contoh: 04b8).");
    }
  }

  void saveScannedPrinter(PrinterDevice printer) {
     if (!savedPrinters.any((p) => p.name == printer.name)) {
        savedPrinters.add(printer);
        _storage.write('saved_printers', savedPrinters.map((p) => p.toJson()).toList());
      }
      selectPrinter(printer); // Langsung jadikan aktif
      Get.back(); // Tutup dialog hasil pindai
  }
  
  /// Memilih printer dari daftar untuk dijadikan aktif
  void selectPrinter(PrinterDevice printer) {
    selectedPrinter.value = printer;
    _storage.write('selected_thermal_printer', printer.toJson());
    Get.back(); // Tutup dialog pemilihan
    Get.snackbar("Sukses", "${printer.name} sekarang aktif.");
  }

  /// Menampilkan dialog untuk memilih dari printer yang sudah tersimpan
  void showPrinterSelectionDialog() {
    Get.dialog(const PrinterSelectionDialog());
  }
}