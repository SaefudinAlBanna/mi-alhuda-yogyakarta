// lib/app/modules/printer_settings/views/printer_settings_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/printer_model.dart'; // Pastikan import model ada
import '../controllers/printer_settings_controller.dart';

class PrinterSettingsView extends GetView<PrinterSettingsController> {
  const PrinterSettingsView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer Struk'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() => Card(
              child: ListTile(
                leading: const Icon(Icons.print, size: 40),
                title: const Text("Printer Struk Aktif"),
                subtitle: Text(
                  controller.selectedPrinter.value?.name ?? "Belum ada printer yang dipilih",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // [BARU] Tambahkan tombol untuk memilih dari daftar yang sudah ada
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                  onPressed: controller.showPrinterSelectionDialog,
                  tooltip: "Pilih dari printer tersimpan",
                ),
              ),
            )),
            const SizedBox(height: 20),
            // // [TOMBOL BARU] Tombol untuk menambah printer secara manual
            // ElevatedButton.icon(
            //   style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            //   icon: const Icon(Icons.add_circle_outline),
            //   label: const Text("Tambah Printer Baru"),
            //   onPressed: () => Get.dialog(AddPrinterDialog()),
            // ),

            if (GetPlatform.isWindows)
              // Tampilkan tombol ini HANYA di Windows
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Tambah Printer USB (Manual)"),
                onPressed: () => Get.dialog(AddPrinterDialog()),
                // onPressed: () => Get.dialog(AddUsbPrinterDialog()),
              )
            else if (GetPlatform.isAndroid)
              // Tampilkan tombol ini HANYA di Android
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                icon: Obx(() => controller.isLoading.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.bluetooth_searching)),
                label: const Text("Pindai Printer Bluetooth"),
                onPressed: controller.scanBluetoothPrinters,
              ),
            const Spacer(),
            const Text(
              "Gunakan 'Tambah Printer Baru' untuk mendaftarkan printer thermal USB Anda (Putian, Epson, dll).",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// [DIALOG BARU] Dialog untuk menambah printer manual
class AddPrinterDialog extends GetView<PrinterSettingsController> {
  AddPrinterDialog({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _vidC = TextEditingController();
  final _pidC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Tambah Printer USB"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameC,
              decoration: const InputDecoration(labelText: "Nama Printer (cth: Kasir Epson)"),
              validator: (v) => v!.isEmpty ? "Nama tidak boleh kosong" : null,
            ),
            TextFormField(
              controller: _vidC,
              decoration: const InputDecoration(labelText: "Vendor ID (VID)", hintText: "Contoh: 04b8"),
              validator: (v) => v!.isEmpty ? "VID tidak boleh kosong" : null,
            ),
            TextFormField(
              controller: _pidC,
              decoration: const InputDecoration(labelText: "Product ID (PID)", hintText: "Contoh: 0202"),
              validator: (v) => v!.isEmpty ? "PID tidak boleh kosong" : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              controller.addAndSavePrinter(
                name: _nameC.text,
                vid: _vidC.text,
                pid: _pidC.text,
              );
            }
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}

class ScanResultDialog extends GetView<PrinterSettingsController> {
  const ScanResultDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Hasil Pindai"),
      content: SizedBox(
        width: double.maxFinite,
        child: Obx(() => ListView.builder(
          shrinkWrap: true,
          itemCount: controller.foundPrinters.length,
          itemBuilder: (context, index) {
            final printer = controller.foundPrinters[index];
            return ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(printer.name),
              onTap: () => controller.saveScannedPrinter(printer),
            );
          },
        )),
      ),
    );
  }
}

// [DIALOG BARU] Dialog untuk memilih printer dari daftar yang tersimpan
class PrinterSelectionDialog extends GetView<PrinterSettingsController> {
  const PrinterSelectionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pilih Printer Aktif"),
      content: SizedBox(
        width: double.maxFinite,
        child: Obx(() => controller.savedPrinters.isEmpty
            ? const Text("Tidak ada printer tersimpan.")
            : ListView.builder(
                shrinkWrap: true,
                itemCount: controller.savedPrinters.length,
                itemBuilder: (context, index) {
                  final printer = controller.savedPrinters[index];
                  return ListTile(
                    leading: const Icon(Icons.usb),
                    title: Text(printer.name),
                    onTap: () => controller.selectPrinter(printer),
                  );
                },
              )),
      ),
    );
  }
}