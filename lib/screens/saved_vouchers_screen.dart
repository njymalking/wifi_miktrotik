import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedVouchersScreen extends StatefulWidget {
  const SavedVouchersScreen({super.key});

  @override
  State<SavedVouchersScreen> createState() => _SavedVouchersScreenState();
}

class _SavedVouchersScreenState extends State<SavedVouchersScreen> {
  List<String> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vouchers = prefs.getStringList('saved_vouchers') ?? [];
    });
  }

  Future<void> _deleteVoucher(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _vouchers.removeAt(index);
    await prefs.setStringList('saved_vouchers', _vouchers);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الكروت المحفوظة'),
        actions: [
          if (_vouchers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('حذف الكل'),
                    content: const Text('هل أنت متأكد من حذف جميع الكروت المحفوظة؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('حذف الكل', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('saved_vouchers');
                  setState(() => _vouchers = []);
                }
              },
            ),
        ],
      ),
      body: _vouchers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد كروت محفوظة',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vouchers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.vpn_key, color: Colors.blue),
                    title: Text(
                      _vouchers[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('كرت رقم ${index + 1}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteVoucher(index),
                    ),
                    onTap: () {
                      Navigator.pop(context, _vouchers[index]);
                    },
                  ),
                );
              },
            ),
    );
  }
}
