import 'package:flutter/foundation.dart';
import 'package:bus_ticket_scanner/models/ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryProvider with ChangeNotifier {
  List<Ticket> _scans = [];
  String _filter = 'all'; // 'all', 'valid', 'invalid'

  List<Ticket> get scans => _filteredScans;
  String get currentFilter => _filter;

  List<Ticket> get _filteredScans {
    switch (_filter) {
      case 'valid':
        return _scans.where((t) => t.isValid).toList();
      case 'invalid':
        return _scans.where((t) => !t.isValid).toList();
      default:
        return _scans;
    }
  }

  Map<String, List<Ticket>> get groupedByBus {
    final map = <String, List<Ticket>>{};
    for (var scan in _filteredScans) {
      if (!map.containsKey(scan.busNumber)) {
        map[scan.busNumber] = [];
      }
      map[scan.busNumber]!.add(scan);
    }

    // Sort each bus's tickets by scan time (newest first)
    for (var entry in map.entries) {
      entry.value.sort((a, b) => b.scanTime.compareTo(a.scanTime));
    }

    return map;
  }

  bool _isDevMode = false;

  Future<void> loadScans() async {
    if (_isDevMode) {
      _scans = [
        Ticket(
          bookingId: 'B001',
          isValid: true,
          route: 'City A → City B',
          busNumber: 'BUS123',
          departureTime: DateTime.now().subtract(const Duration(hours: 2)),
          arrivalTime: DateTime.now().subtract(const Duration(hours: 1)),
          seats: [4],
          paymentReference: 'PAY123',
          fullPaymentInfo: {'method': 'PayPal', 'status': 'Paid'},
        ),
        Ticket(
          bookingId: 'B002',
          isValid: false,
          route: 'City C → City D',
          busNumber: 'BUS456',
          departureTime: DateTime.now().subtract(const Duration(hours: 5)),
          arrivalTime: DateTime.now().subtract(const Duration(hours: 4)),
          // seatNumbers: ['1C'],
          seats: [1],
          paymentReference: 'PAY456',
          fullPaymentInfo: {'method': 'PayPal', 'status': 'Paid'},
        ),
        Ticket(
          bookingId: 'B003',
          isValid: true,
          route: 'City E → City F',
          busNumber: 'BUS123',
          departureTime: DateTime.now().subtract(const Duration(days: 1)),
          arrivalTime: DateTime.now().subtract(const Duration(hours: 20)),
          seats: [2],
          paymentReference: 'PAY789',
          fullPaymentInfo: {'method': 'PayPal', 'status': 'Paid'},
        ),
      ];
    } else {
      final prefs = await SharedPreferences.getInstance();
      final scansJson = prefs.getStringList('scanHistory') ?? [];
      _scans =
          scansJson.map((json) => Ticket.fromJson(jsonDecode(json))).toList();
    }
    notifyListeners();
  }

  Future<void> addScan(Ticket ticket) async {
    // Ensure we don't duplicate identical scans
    if (_scans.any((s) => s.bookingId == ticket.bookingId)) {
      return;
    }

    _scans.insert(0, ticket);

    // Keep only the last 100 scans to prevent storage issues
    if (_scans.length > 100) {
      _scans = _scans.sublist(0, 100);
    }

    await _saveScans();
    notifyListeners();
  }

  Future<void> setFilter(String filter) async {
    _filter = filter;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _scans = [];
    await _saveScans();
    notifyListeners();
  }

  Future<void> _saveScans() async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = _scans.map((scan) => jsonEncode(scan.toJson())).toList();
    await prefs.setStringList('scanHistory', scansJson);
  }
}
