import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../controllers/manajemen_dashboard_controller.dart';

class ManajemenDashboardView extends GetView<ManajemenDashboardController> {
  const ManajemenDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Menu Dashboard'),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
                icon: controller.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Icon(Icons.save),
                onPressed: controller.isLoading.value ? null : () => controller.saveConfiguration(),
                tooltip: 'Simpan Konfigurasi',
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGroupSection(),
            const SizedBox(height: 24),
            _buildItemSection(),
          ],
        );
      }),
    );
  }

  Widget _buildGroupSection() {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Kelola Grup Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: true,
        children: [
          ...controller.menuGroups.map((group) => ListTile(
                title: Text(group['title']),
                subtitle: Text("ID: ${group['groupId']} | Urutan: ${group['order']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit, color: Colors.blue.shade700), onPressed: () => controller.showGroupForm(initialData: group)),
                    IconButton(icon: Icon(Icons.delete, color: Colors.red.shade700), onPressed: () => controller.deleteGroup(group['groupId'])),
                  ],
                ),
              )),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Tambah Grup"),
              onPressed: () => controller.showGroupForm(),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSection() {
    // Buat daftar item yang diurutkan berdasarkan judul untuk tampilan yang konsisten
    final sortedItems = controller.menuItems.entries.toList()
      ..sort((a, b) => a.value['title'].compareTo(b.value['title']));

    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Kelola Item Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: true,
        children: [
          ...sortedItems.map((entry) {
            final String itemId = entry.key;
            final Map<String, dynamic> itemData = Map<String, dynamic>.from(entry.value);
            return ListTile(
              leading: Image.asset('assets/png/${itemData['icon']}', width: 24, height: 24, errorBuilder: (c, e, s) => const Icon(Icons.error)),
              title: Text(itemData['title']),
              subtitle: Text("ID: $itemId | Grup: ${itemData['groupId']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit, color: Colors.blue.shade700), onPressed: () => controller.showItemForm(itemId: itemId, initialData: itemData)),
                  IconButton(icon: Icon(Icons.delete, color: Colors.red.shade700), onPressed: () => controller.deleteItem(itemId)),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Tambah Item"),
              onPressed: () => controller.showItemForm(),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET FORM DIALOG UNTUK GRUP ---

class GroupFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic> data) onSave;

  const GroupFormDialog({Key? key, this.initialData, required this.onSave}) : super(key: key);

  @override
  _GroupFormDialogState createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _titleController;
  late TextEditingController _orderController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialData?['groupId'] ?? '');
    _titleController = TextEditingController(text: widget.initialData?['title'] ?? '');
    _orderController = TextEditingController(text: widget.initialData?['order']?.toString() ?? '99');
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'groupId': _idController.text.trim(),
        'title': _titleController.text.trim(),
        'order': int.tryParse(_orderController.text.trim()) ?? 99,
      };
      widget.onSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialData == null ? 'Tambah Grup' : 'Edit Grup'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID Grup (unik, tanpa spasi)'),
                validator: (value) => value!.isEmpty ? 'ID tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Nama Tampilan Grup'),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(labelText: 'Urutan Tampil'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Urutan tidak boleh kosong';
                  if (int.tryParse(value) == null) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Batal')),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

// --- WIDGET FORM DIALOG UNTUK ITEM ---

class ItemFormDialog extends StatefulWidget {
  final String? itemId;
  final Map<String, dynamic>? initialData;
  final List<Map<String, dynamic>> availableGroups;
  final List<String> availableRoles;
  final List<String> availableTugas;
  final Function(String id, Map<String, dynamic> data) onSave;

  const ItemFormDialog({
    Key? key,
    this.itemId,
    this.initialData,
    required this.availableGroups,
    required this.availableRoles,
    required this.availableTugas,
    required this.onSave,
  }) : super(key: key);

  @override
  _ItemFormDialogState createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _titleController;
  late TextEditingController _iconController;
  late TextEditingController _routeController;
  
  String? _selectedGroupId;
  List<dynamic> _selectedRoles = [];
  List<dynamic> _selectedTugas = [];
  
  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.itemId ?? '');
    _titleController = TextEditingController(text: widget.initialData?['title'] ?? '');
    _iconController = TextEditingController(text: widget.initialData?['icon'] ?? '');
    _routeController = TextEditingController(text: widget.initialData?['route'] ?? '');

    _selectedGroupId = widget.initialData?['groupId'];
    _selectedRoles = List<String>.from(widget.initialData?['roles'] ?? []);
    _selectedTugas = List<String>.from(widget.initialData?['tugas'] ?? []);
  }
  
  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _iconController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'title': _titleController.text.trim(),
        'icon': _iconController.text.trim(),
        'route': _routeController.text.trim(),
        'groupId': _selectedGroupId,
        'roles': _selectedRoles,
        'tugas': _selectedTugas,
      };
      widget.onSave(_idController.text.trim(), data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialData == null ? 'Tambah Item Menu' : 'Edit Item Menu'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID Item (unik, tanpa spasi)'),
                validator: (value) => value!.isEmpty ? 'ID tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Tampilan'),
                validator: (value) => value!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(labelText: 'Nama File Ikon (.png)'),
                 validator: (value) => value!.isEmpty ? 'Ikon tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _routeController,
                decoration: const InputDecoration(labelText: 'Rute Navigasi (Contoh: /nama-rute)'),
                validator: (value) => value!.isEmpty ? 'Rute tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGroupId,
                items: widget.availableGroups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group['groupId'],
                    child: Text(group['title']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedGroupId = value),
                decoration: const InputDecoration(labelText: 'Pilih Grup'),
                validator: (value) => value == null ? 'Grup harus dipilih' : null,
              ),
              const SizedBox(height: 16),
              MultiSelectDialogField(
                items: widget.availableRoles.map((role) => MultiSelectItem<String>(role, role)).toList(),
                title: const Text("Pilih Peran"),
                buttonText: const Text("Peran yang Diizinkan"),
                initialValue: _selectedRoles.cast<String>(),
                onConfirm: (values) {
                  setState(() => _selectedRoles = values);
                },
              ),
              const SizedBox(height: 8),
               MultiSelectDialogField(
                items: widget.availableTugas.map((tugas) => MultiSelectItem<String>(tugas, tugas)).toList(),
                title: const Text("Pilih Tugas"),
                buttonText: const Text("Tugas yang Diizinkan"),
                initialValue: _selectedTugas.cast<String>(),
                onConfirm: (values) {
                  setState(() => _selectedTugas = values);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Batal')),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}