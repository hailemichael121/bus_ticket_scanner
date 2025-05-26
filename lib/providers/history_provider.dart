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

  Map<String, List<Ticket>> get groupedScans {
    final map = <String, List<Ticket>>{};
    for (var scan in _filteredScans) {
      final date = scan.formattedDate;
      if (!map.containsKey(date)) {
        map[date] = [];
      }
      map[date]!.add(scan);
    }
    return map;
  }

  Future<void> loadScans() async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('scanHistory') ?? [];
    _scans =
        scansJson.map((json) => Ticket.fromJson(jsonDecode(json))).toList();
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
