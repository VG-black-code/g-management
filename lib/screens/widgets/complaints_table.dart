import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import 'complaint_details_dialog.dart';

class ComplaintsTable extends StatelessWidget {
  final List<Issue> issues;
  final Function(Issue, String) onStatusChanged;
  final Function(Issue) onDelete;

  const ComplaintsTable({
    super.key,
    required this.issues,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1100, // Fixed width to ensure vertical alignment across rows
                child: ListView.builder(
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    return _buildRow(context, issues[index], index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 1100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5).withOpacity(0.5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: const [
            SizedBox(width: 220, child: Text('Student Name', style: _headerStyle)),
            SizedBox(width: 100, child: Text('ID', textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(width: 180, child: Text('Category', textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(width: 120, child: Text('Date', textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(width: 110, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(width: 320, child: Text('Update Status', textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(width: 50, child: Text('', textAlign: TextAlign.center, style: _headerStyle)),
          ],
        ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 13,
    color: Color(0xFF4A148C),
  );

  Widget _buildRow(BuildContext context, Issue issue, int index) {
    final status = issue.status?.toLowerCase() ?? 'pending';
    final isPending = status == 'pending';
    final isProcessing = status == 'processing' || status == 'in progress';
    final isResolved = status == 'resolved' || status == 'approved' || status == 'completed';

    final date = issue.createdAt != null 
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(issue.createdAt!))
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 1 ? const Color(0xFFF9F9F9) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          // Student Name
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.userName ?? 'N/A', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(issue.usn ?? 'N/A', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ),
          // ID
          SizedBox(
            width: 100,
            child: Text('CMP${issue.id}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          // Category
          SizedBox(
            width: 180,
            child: Text(
              issue.problemType ?? issue.category ?? 'N/A',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Date
          SizedBox(
            width: 120,
            child: Text(date, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ),
          // Current Status Text
          SizedBox(
            width: 110,
            child: Center(
              child: Text(
                issue.status ?? 'Pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
            ),
          ),
          // Update Status Buttons
          SizedBox(
            width: 320,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusCircleBtn('Pending', Colors.red, isPending, () => onStatusChanged(issue, 'Pending')),
                const SizedBox(width: 8),
                _buildStatusCircleBtn('Processing', Colors.orange, isProcessing, () => onStatusChanged(issue, 'Processing')),
                const SizedBox(width: 8),
                _buildStatusCircleBtn('Resolve', Colors.green, isResolved, () => onStatusChanged(issue, 'Resolved')),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 22, color: Color(0xFF7C4DFF)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ComplaintDetailsDialog(issue: issue),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Delete Action
          SizedBox(
            width: 50,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: () => onDelete(issue),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCircleBtn(String label, Color color, bool isActive, VoidCallback onTap) {
    return Container(
      width: 90,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? color : color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.red;
      case 'processing': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'rejected': return Colors.grey;
      default: return Colors.blue;
    }
  }
}
