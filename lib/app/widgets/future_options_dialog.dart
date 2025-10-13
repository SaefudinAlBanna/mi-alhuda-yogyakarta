import 'package:flutter/material.dart';

class FutureOptionsDialog extends StatelessWidget {
  final String title;
  final String middleText;
  final Future<List<String>> future;
  final Function(String) onItemSelected;
  final String emptyDataText;

  const FutureOptionsDialog({
    super.key,
    required this.title,
    required this.middleText,
    required this.future,
    required this.onItemSelected,
    this.emptyDataText = "Tidak ada data tersedia.",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Agar tinggi Column pas dengan konten
        children: [
          Text(middleText, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 16),
          SizedBox(
            height: 60, // Tinggi tetap untuk area loading/tombol
            width: double.maxFinite, // Lebar penuh dialog
            child: FutureBuilder<List<String>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(emptyDataText));
                }
                
                final List<String> options = snapshot.data!;
                
                return Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: options.map((option) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: ElevatedButton(
                            onPressed: () => onItemSelected(option),
                            child: Text(option),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Gunakan Navigator.pop untuk menutup
          child: const Text("Batal"),
        ),
      ],
    );
  }
}