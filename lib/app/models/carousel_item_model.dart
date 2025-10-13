// lib/app/models/carousel_item_model.dart

import 'package:flutter/material.dart';

enum CarouselContentType { Prioritas, Info, KBM, Default }

class CarouselItemModel {
  final String namaKelas;
  final CarouselContentType tipe;
  final String judul;
  final String isi;
  final String? subJudul;
  final IconData ikon;
  final Color warna;

  CarouselItemModel({
    required this.namaKelas, required this.tipe, required this.judul,
    required this.isi, this.subJudul, required this.ikon, required this.warna,
  });
}