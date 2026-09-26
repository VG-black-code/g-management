import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'posh_widgets.dart';

class PoshHelplineEditorScreen extends StatefulWidget {
  const PoshHelplineEditorScreen({super.key});

  @override
  State<PoshHelplineEditorScreen> createState() => _PoshHelplineEditorScreenState();
}

class _PoshHelplineEditorScreenState extends State<PoshHelplineEditorScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _helplines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHelplines();
  }

  Future<void> _fetchHelplines() async {
    try {
      final data = await supabase.from('posh_config').select().order('key');
      setState(() {
        _helplines = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _editHelpline(dynamic item) {
    final labelController = TextEditingController(text: item['label']);
    final valueController = TextEditingController(text: item['value']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Helpline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label')),
            TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Phone/Contact')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('posh_config').update({
                'label': labelController.text,
                'value': valueController.text,
              }).eq('id', item['id']);
              Navigator.pop(context);
              _fetchHelplines();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Helpline Settings', style: TextStyle(color: navyText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: navyText),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _helplines.length,
              itemBuilder: (context, index) {
                final h = _helplines[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(h['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(h['value']),
                    trailing: const Icon(Icons.edit, color: poshPurple),
                    onTap: () => _editHelpline(h),
                  ),
                );
              },
            ),
    );
  }
}
