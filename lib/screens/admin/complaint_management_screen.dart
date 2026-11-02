import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class ComplaintManagementScreen extends StatelessWidget {
  const ComplaintManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final complaints = app.getAllComplaints();

    return Scaffold(
      appBar: AppBar(title: const Text('Şikayət İdarəetməsi')),
      body: complaints.isEmpty
          ? Center(child: Text('Şikayət yoxdur'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = complaints[index];
                return Card(
                  child: ListTile(
                    title: Text(c.subject),
                    subtitle: Text('${c.description}\n${c.type.label}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'inProgress') {
                          app.updateComplaintStatus(
                            c.id,
                            ComplaintStatus.inProgress,
                          );
                        } else if (v == 'resolved') {
                          app.updateComplaintStatus(
                            c.id,
                            ComplaintStatus.resolved,
                          );
                        } else if (v == 'rejected') {
                          app.updateComplaintStatus(
                            c.id,
                            ComplaintStatus.rejected,
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'inProgress',
                          child: Text('Araşdırılır'),
                        ),
                        const PopupMenuItem(
                          value: 'resolved',
                          child: Text('Həll edildi'),
                        ),
                        const PopupMenuItem(
                          value: 'rejected',
                          child: Text('Rədd edildi'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
