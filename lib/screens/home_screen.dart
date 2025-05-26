import 'package:bus_ticket_scanner/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_ticket_scanner/providers/auth_provider.dart';
import 'package:bus_ticket_scanner/screens/scanner_screen.dart';
import 'package:bus_ticket_scanner/widgets/custom_button.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Ticket Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOperatorCard(authProvider),
          Expanded(
            child: Center(
              child: LimeButton(
                text: 'SCAN TICKET',
                icon: Icons.qr_code_scanner,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScannerScreen()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorCard(AuthProvider authProvider) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
              radius: 30,
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(authProvider.operatorName ?? 'Operator',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(authProvider.operatorEmail ?? '',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
