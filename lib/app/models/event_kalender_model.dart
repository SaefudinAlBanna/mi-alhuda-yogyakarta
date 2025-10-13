import 'package:flutter/material.dart';

class EventKalenderModel {
  final String id; // <-- TAMBAHKAN INI
  final String keterangan;
  final bool isLibur;
  final Color color;

  EventKalenderModel({
    required this.id, // <-- TAMBAHKAN INI
    required this.keterangan,
    required this.isLibur,
    required this.color,
  });

  @override
  String toString() => keterangan; // Berguna untuk menampilkan di daftar event
}