import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? _selectedCategory;
  String? _selectedStatus;
  String? _selectedPriority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Filter Complaints',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(
              'Category',
              Constants.categories,
              _selectedCategory,
              (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 16),
            _buildFilterSection(
              'Status',
              ['Pending', 'Processing', 'Resolved', 'Rejected'],
              _selectedStatus,
              (val) => setState(() => _selectedStatus = val),
            ),
            const SizedBox(height: 16),
            _buildFilterSection(
              'Priority',
              ['Low', 'Medium', 'High'],
              _selectedPriority,
              (val) => setState(() => _selectedPriority = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedCategory = null;
              _selectedStatus = null;
              _selectedPriority = null;
            });
          },
          child: const Text('Reset'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Apply Filters'),
        ),
      ],
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return ChoiceChip(
              label: Text(option, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
              selectedColor: const Color(0xFF7C4DFF),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}
