import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mi_alhuda_yogyakarta/app/models/acara_kalender_model.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/manajemen_kalender_akademik_controller.dart';

class ManajemenKalenderAkademikView extends GetView<ManajemenKalenderAkademikController> {
  const ManajemenKalenderAkademikView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kalender Akademik")),
      floatingActionButton: controller.isPimpinan ? FloatingActionButton.extended(
        onPressed: () => controller.showFormDialog(), label: const Text("Tambah Agenda"), icon: const Icon(Icons.add),
      ) : null,
      body: Column(
        children: [
          _buildTableCalendar(),
          _buildAgendaHeader(),
          Expanded(child: _buildMonthlyEventList()),
        ],
      ),
    );
  }

  Widget _buildTableCalendar() {
    return Obx(() => TableCalendar<AcaraKalender>(
          locale: 'id_ID',
          firstDay: DateTime.utc(2022, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: controller.focusedDay.value,
          selectedDayPredicate: (day) => isSameDay(controller.selectedDay.value, day),
          calendarFormat: controller.calendarFormat.value,
          eventLoader: controller.getEventsForDay,
          
          // --- [IMPROVISASI] Logika untuk menandai hari libur ---
          holidayPredicate: (day) {
            // Sebuah hari dianggap libur jika salah satu acaranya memiliki flag isLibur
            return controller.getEventsForDay(day).any((acara) => acara.isLibur);
          },

          onDaySelected: controller.onDaySelected,
          onFormatChanged: (format) => controller.calendarFormat.value = format,
          onPageChanged: controller.onPageChanged,
          
          // --- [IMPROVISASI] Builder kustom untuk visualisasi acara ---
          calendarBuilders: CalendarBuilders(
            // Builder untuk penanda (titik-titik di bawah tanggal)
            markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((event) { // Batasi maksimal 3 titik
                      final acara = event as AcaraKalender;
                      return Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: acara.warna,
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
              return null;
            },
          ),
          
          // --- [IMPROVISASI] Gaya visual untuk kalender ---
          calendarStyle: CalendarStyle(
            // Gaya untuk hari ini (lingkaran oranye)
            todayDecoration: BoxDecoration(
              color: Colors.orange.shade200,
              shape: BoxShape.circle,
            ),
            // Gaya untuk hari yang dipilih pengguna (lingkaran biru)
            selectedDecoration: BoxDecoration(
              color: Get.theme.primaryColor.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            // Gaya untuk hari libur (teks menjadi merah)
            holidayTextStyle: const TextStyle(color: Colors.red), 
            // Sembunyikan marker default karena kita pakai markerBuilder kustom
            // markersVisible: true,
          ),
          headerStyle: const HeaderStyle(
            formatButtonShowsNext: false,
            titleCentered: true,
          ),
        ));
  }

  Widget _buildAgendaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Obx(() => Text(
        "Agenda Bulan ${DateFormat('MMMM yyyy', 'id_ID').format(controller.focusedDay.value)}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      )),
    );
  }

  Widget _buildMonthlyEventList() {
    return Obx(() {
      if (controller.monthlyEvents.isEmpty) { return const Center(child: Text("Tidak ada agenda pada bulan ini.", style: TextStyle(color: Colors.grey))); }
      return ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: controller.monthlyEvents.length,
        itemBuilder: (context, index) {
          final acara = controller.monthlyEvents[index];
          final tglMulai = DateFormat('d', 'id_ID').format(acara.mulai);
          final tglSelesai = DateFormat('d MMM yyyy', 'id_ID').format(acara.selesai);
          final tanggal = acara.mulai.day == acara.selesai.day ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(acara.mulai) : "$tglMulai - $tglSelesai";
              
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: Container(width: 8, decoration: BoxDecoration(color: acara.warna, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)))),
              title: Text(acara.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tanggal),
                  if (acara.deskripsi.isNotEmpty) 
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(acara.deskripsi, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                ],
              ),
              trailing: controller.isPimpinan ? Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600), onPressed: () => controller.showFormDialog(acara: acara)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => controller.hapusAcara(acara.id)),
              ]) : null,
              isThreeLine: acara.deskripsi.isNotEmpty,
            ),
          );
        },
      );
    });
  }
}