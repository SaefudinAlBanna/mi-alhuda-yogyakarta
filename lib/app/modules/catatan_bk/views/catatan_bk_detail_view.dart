import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/catatan_bk_controller.dart';

class CatatanBkDetailView extends GetView<CatatanBkController> {
  const CatatanBkDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String catatanId = Get.arguments['catatanId'];
    controller.fetchDetailAndKomentar(catatanId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Catatan'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isDetailLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.catatanDetail.value == null) {
                return const Center(child: Text('Gagal memuat detail.'));
              }
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildDetailHeader(controller.catatanDetail.value!),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Diskusi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  _buildKomentarList(),
                ],
              );
            }),
          ),
          _buildKomentarInput(catatanId),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(dynamic catatan) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(catatan.judul, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Dibuat oleh ${catatan.pembuatNama} pada ${DateFormat('dd MMM yyyy', 'id_ID').format(catatan.tanggalDibuat)}', style: const TextStyle(color: Colors.grey)),
          const Divider(height: 24),
          Text(catatan.isi, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildKomentarList() {
    return Obx(() {
      if (controller.komentarList.isEmpty) {
        return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada komentar.'))));
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final komentar = controller.komentarList[index].data() as Map<String, dynamic>;
            final bool isMe = komentar['penulisId'] == controller.configC.infoUser['uid'];
            return _buildKomentarBubble(komentar, isMe);
          },
          childCount: controller.komentarList.length,
        ),
      );
    });
  }

  Widget _buildKomentarBubble(Map<String, dynamic> komentar, bool isMe) {
    final timestamp = komentar['timestamp'] as Timestamp?;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.indigo.shade500 : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${komentar['penulisNama']} (${komentar['penulisPeran']})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(komentar['isi'], style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Text(
                    timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '',
                    style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKomentarInput(String catatanId) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.grey.withOpacity(0.2), spreadRadius: 1)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.komentarController,
                decoration: const InputDecoration(
                  hintText: 'Tulis komentar...',
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            Obx(() => IconButton(
                  icon: controller.isSendingKomentar.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.send),
                  onPressed: controller.isSendingKomentar.value ? null : () => controller.addKomentar(catatanId),
                  color: Colors.indigo,
                )),
          ],
        ),
      ),
    );
  }
}