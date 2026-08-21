import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../models/models.dart';
import 'status_badge.dart';
import 'priority_badge.dart';
import 'complaint_details_dialog.dart';

class ComplaintRow {
  static DataRow build({
    required BuildContext context,
    required Issue issue,
    required Function(Issue, String) onStatusChanged,
    required Function(Issue) onDelete,
  }) {
    return DataRow2(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                issue.userName ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                issue.usn ?? 'N/A',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ),
        DataCell(Text('CMP${issue.id}', style: const TextStyle(fontSize: 12))),
        DataCell(Text(issue.category ?? 'General', style: const TextStyle(fontSize: 12))),
        DataCell(Text(issue.createdAt?.split('T')[0] ?? 'N/A', style: const TextStyle(fontSize: 12))),
        DataCell(StatusBadge(status: issue.status ?? 'Pending')),
        DataCell(PriorityBadge(priority: issue.priority ?? 'Low')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _isValidStatus(issue.status) ? issue.status : 'Pending',
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, size: 18),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: ['Pending', 'Processing', 'Resolved', 'Rejected'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) onStatusChanged(issue, newValue);
                },
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20, color: Color(0xFF7C4DFF)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ComplaintDetailsDialog(issue: issue),
                  );
                },
                tooltip: 'View Details',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                onPressed: () => onDelete(issue),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static bool _isValidStatus(String? status) {
    return ['Pending', 'Processing', 'Resolved', 'Rejected'].contains(status);
  }
}
