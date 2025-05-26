import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_ticket_scanner/providers/history_provider.dart';
import 'package:bus_ticket_scanner/models/ticket.dart';
import 'package:bus_ticket_scanner/theme/app_theme.dart';
// import 'package:intl/intl.dart';
import 'package:bus_ticket_scanner/screens/ticket_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider =
        Provider.of<HistoryProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      historyProvider.loadScans();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              Provider.of<HistoryProvider>(context, listen: false)
                  .setFilter(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Show All')),
              const PopupMenuItem(value: 'valid', child: Text('Valid Only')),
              const PopupMenuItem(
                  value: 'invalid', child: Text('Invalid Only')),
            ],
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.scans.isEmpty) {
            return const Center(child: Text('No scan history yet'));
          }

          final grouped = provider.groupedByBus;
          final busNumbers = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: busNumbers.length,
            itemBuilder: (context, index) {
              final busNumber = busNumbers[index];
              final tickets = grouped[busNumber]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: AppTheme.lightGray,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          color: AppTheme.almostBlack,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bus: $busNumber',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.almostBlack,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'RobotoMono',
                                  ),
                        ),
                      ],
                    ),
                  ),
                  ...tickets
                      .map((ticket) => _buildScanItem(context, ticket))
                      .toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScanItem(BuildContext context, Ticket scan) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scan.isValid
                ? AppTheme.darkGreen.withOpacity(0.2)
                : AppTheme.errorRed.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            scan.isValid ? Icons.verified : Icons.error_outline,
            color: scan.isValid ? AppTheme.green : AppTheme.errorRed,
          ),
        ),
        title: Text(
          scan.formattedRoute,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${scan.formattedDepartureTime} • ${scan.formattedBusNumber}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Seats: ${scan.formattedSeat}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scan.isValid
                ? AppTheme.brightLime.withOpacity(0.1)
                : AppTheme.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            scan.isValid ? 'VALID' : 'INVALID',
            style: TextStyle(
              color: scan.isValid ? AppTheme.green : AppTheme.errorRed,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticket: scan),
            ),
          );
        },
      ),
    );
  }
}
