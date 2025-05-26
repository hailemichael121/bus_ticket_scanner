import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:lottie/lottie.dart';
import 'package:logger/logger.dart';
import 'package:bus_ticket_scanner/models/ticket.dart';
import 'package:bus_ticket_scanner/theme/app_theme.dart';
import 'package:bus_ticket_scanner/providers/auth_provider.dart';

enum TicketStatus { pending, valid, invalid, error }

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final String? errorMessage;
  final TicketStatus initialStatus;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
    this.errorMessage,
    this.initialStatus = TicketStatus.pending,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  late TicketStatus _status;
  bool _isValidating = false;
  String? _validationMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final Logger _logger = Logger();
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _validationMessage = widget.errorMessage;
    _dio = Dio();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.95), weight: 50),
    ]).animate(_animationController);

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);

    // Auto-validate if pending and no error message
    if (_status == TicketStatus.pending && widget.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateTicket();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _validateTicket() async {
    if (_isValidating) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) {
      _logger.e('Authentication token not available');
      setState(() {
        _status = TicketStatus.error;
        _validationMessage = 'Authentication required';
      });
      return;
    }

    _logger.i(
        'Starting ticket validation for booking ID: ${widget.ticket.bookingId}');
    setState(() {
      _isValidating = true;
      _status = TicketStatus.pending;
      _validationMessage = 'Validating ticket...';
    });

    try {
      final bookingId = widget.ticket.bookingId;
      print(
          'Calling: https://n7gjzkm4-3001.euw.devtunnels.ms/api/bookings/$bookingId/mark/attended');

      final response = await _dio
          .put(
            'https://n7gjzkm4-3002.euw.devtunnels.ms/api/bookings/mark/attended',
            data: {
              'bookingId': bookingId,
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer ${authProvider.token}',
                'Content-Type': 'application/json',
              },
            ),
          )
          .timeout(const Duration(seconds: 10));

      _logger.i('Validation response: ${response.data}');

      setState(() {
        _status = response.data['success'] == true
            ? TicketStatus.valid
            : TicketStatus.invalid;
        _validationMessage = response.data['message'] ??
            (_status == TicketStatus.valid ? 'Valid ticket' : 'Invalid ticket');
      });
    } on DioException catch (e) {
      _logger.e('Validation failed: ${e.message}',
          error: e, stackTrace: e.stackTrace);
      setState(() {
        _status = TicketStatus.error;
        _validationMessage = _handleDioError(e);
      });
    } catch (e) {
      _logger.e('Unexpected validation error: $e');
      setState(() {
        _status = TicketStatus.error;
        _validationMessage = 'Validation failed';
      });
    } finally {
      setState(() => _isValidating = false);
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please try again';
      case DioExceptionType.badResponse:
        return e.response?.data?['message'] ?? 'Server error occurred';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      default:
        return 'Network error. Please check your connection';
    }
  }

  Widget _buildValidationStatus() {
    final statusData = {
      TicketStatus.valid: {
        'color': Colors.green,
        'icon': Icons.verified,
        'animation': 'assets/animations/sucess.json',
        'text': 'VALID TICKET',
      },
      TicketStatus.invalid: {
        'color': Colors.red,
        'icon': Icons.error_outline,
        'animation': 'assets/animations/error.json',
        'text': 'INVALID TICKET',
      },
      TicketStatus.error: {
        'color': Colors.orange,
        'icon': Icons.warning,
        'animation': 'assets/animations/warning.json',
        'text': 'VALIDATION ERROR',
      },
      TicketStatus.pending: {
        'color': Colors.blue,
        'icon': Icons.pending,
        'animation': 'assets/animations/scanning.json',
        'text': 'VALIDATING...',
      },
    };

    final currentStatus = statusData[_status]!;
    final statusColor = currentStatus['color'] as Color;
    final statusText = currentStatus['text'] as String;
    final animationAsset = currentStatus['animation'] as String;

    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset(
                  animationAsset,
                  fit: BoxFit.contain,
                  repeat: _status == TicketStatus.pending,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _validationMessage ?? statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: statusColor.withOpacity(0.2),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (_status != TicketStatus.valid && !_isValidating)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Verify Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _validateTicket,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ... [Keep all other existing methods unchanged] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('Ticket Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.errorMessage != null && _status != TicketStatus.error)
              _buildErrorCard(widget.errorMessage!),
            const SizedBox(height: 24),
            _buildValidationStatus(),
            const SizedBox(height: 24),
            _buildDetailCard('Route', widget.ticket.formattedRoute),
            _buildDetailCard('Seat', widget.ticket.formattedSeat),
            _buildDetailCard('Bus Number', widget.ticket.formattedBusNumber),
            _buildDetailCard('Departure', widget.ticket.formattedDepartureTime),
            _buildDetailCard('Arrival', widget.ticket.formattedArrivalTime),
            _buildDetailCard('Booking ID', widget.ticket.formattedBookingId),
            _buildDetailCard(
                'Payment Reference', widget.ticket.formattedPaymentReference),
            _buildDetailCard(
                'Passenger Info', widget.ticket.formattedFullPaymentInfo),
            _buildDetailCard('Scanned On',
                '${widget.ticket.formattedScanDate} at ${widget.ticket.formattedTime}'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return AnimatedOpacity(
      opacity: _status == TicketStatus.pending ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        color: AppTheme.errorRed.withOpacity(0.15),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.subtitleGray,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.almostBlack,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
