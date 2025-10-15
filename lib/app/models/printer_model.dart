// lib/app/models/printer_model.dart

// Enum untuk membedakan tipe koneksi printer
enum PrinterType { usb, driver, unknown }

class PrinterDevice {
  final String name;      // Nama yang ditampilkan ke user (e.g., "YICHIP POS58")
  final PrinterType type; // Tipe koneksi (USB atau Driver)
  
  // Properti khusus untuk tipe USB
  final int? vendorId;
  final int? productId;
  
  // Properti khusus untuk tipe Driver
  // (Nama printer yang digunakan di package `printing`)

  PrinterDevice({
    required this.name,
    required this.type,
    this.vendorId,
    this.productId,
  });

  // Fungsi untuk mengubah objek menjadi Map agar bisa disimpan di GetStorage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name, // simpan sebagai string: 'usb' atau 'driver'
      'vendorId': vendorId,
      'productId': productId,
    };
  }

  // Fungsi untuk membuat objek dari Map yang dibaca dari GetStorage
  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      name: json['name'],
      type: PrinterType.values.firstWhere((e) => e.name == json['type'], orElse: () => PrinterType.unknown),
      vendorId: json['vendorId'],
      productId: json['productId'],
    );
  }
}