import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import 'status_badge.dart';
import 'priority_badge.dart';

class ComplaintDetailsDialog extends StatelessWidget {
  final Issue issue;
  const ComplaintDetailsDialog({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: size.width > 800 ? 700 : size.width * 0.9,
        constraints: BoxConstraints(maxHeight: size.height * 0.9),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    child: const Icon(Icons.assignment, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complaint ID: CMP${issue.id}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage detailed information and track progress',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      'Student Information',
                      Icons.person_outline,
                      [
                        _buildInfoRow(context, 'Full Name', issue.userName ?? 'N/A'),
                        _buildInfoRow(context, 'USN / ID', issue.usn ?? 'N/A'),
                        _buildInfoRow(context, 'Department', issue.department ?? 'N/A'),
                      ],
                    ),
                    Divider(height: 32, color: colorScheme.outlineVariant),
                    _buildSection(
                      context,
                      'Complaint Details',
                      Icons.description_outlined,
                      [
                        _buildInfoRow(context, 'Category', issue.category ?? 'N/A'),
                        _buildInfoRow(context, 'Problem Type', issue.problemType ?? 'N/A'),
                        _buildInfoRow(context, 'Location', issue.location ?? 'N/A'),
                        _buildInfoRow(context, 'Raised Date', issue.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(issue.createdAt!)) : 'N/A'),
                        const SizedBox(height: 12),
                        Text('Description:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Text(
                            issue.description ?? 'No description provided.',
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 32, color: colorScheme.outlineVariant),
                    _buildSection(
                      context,
                      'Admin Actions & Status',
                      Icons.admin_panel_settings_outlined,
                      [
                        Row(
                          children: [
                            Text('Current Status: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                            StatusBadge(status: issue.status ?? 'Pending'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Priority Level: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                            PriorityBadge(priority: issue.priority ?? 'Low'),
                          ],
                        ),
                        _buildInfoRow(context, 'Assigned Staff', issue.assignedTo ?? 'Not Assigned'),
                      ],
                    ),
                    
                    if (issue.photoUrl != null && issue.photoUrl!.isNotEmpty) ...[
                      Divider(height: 32, color: colorScheme.outlineVariant),
                      _buildSection(
                        context,
                        'Attachments',
                        Icons.attachment,
                        [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: issue.photoUrl!,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: colorScheme.surfaceVariant,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: colorScheme.surfaceVariant,
                                child: Icon(Icons.broken_image, size: 50, color: colorScheme.onSurfaceVariant),
                              ),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    _buildTimeline(context, issue),
                  ],
                ),
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('DONE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, Issue issue) {
    final status = (issue.status ?? 'Pending').toLowerCase();
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grievance Timeline', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        _buildTimelineItem(
          context, 
          'Complaint Raised', 
          issue.createdAt, 
          true,
          activeColor: theme.colorScheme.primary,
        ),
        
        _buildTimelineItem(
          context, 
          'Admin Accepted', 
          issue.processingAt, 
          status == 'processing' || status == 'resolved' || issue.processingAt != null,
          activeColor: Colors.orange,
        ),
        
        _buildTimelineItem(
          context, 
          'Resolved', 
          issue.resolvedAt, 
          status == 'resolved' || issue.resolvedAt != null, 
          isLast: true,
          activeColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, String title, String? date, bool isDone, {bool isLast = false, Color? activeColor}) {
    final theme = Theme.of(context);
    final color = isDone ? (activeColor ?? theme.colorScheme.primary) : theme.colorScheme.outline;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isDone ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: isDone 
                  ? const Icon(Icons.check, size: 12, color: Colors.white) 
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 35,
                color: color.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal, 
                  color: isDone ? color : theme.colorScheme.onSurface.withOpacity(0.5),
                )
              ),
              if (date != null)
                Text(
                  DateFormat('dd MMM, hh:mm a').format(DateTime.parse(date)), 
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
                ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
