import 'package:get/get.dart';

class SiswaAbsensiModel {
  String uid;
  String nama;
  RxString status = 'Hadir'.obs; // Default status

  SiswaAbsensiModel({required this.uid, required this.nama});
}