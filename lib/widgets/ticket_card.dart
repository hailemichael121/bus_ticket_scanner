import 'package:flutter/material.dart';
import 'package:bus_ticket_scanner/models/ticket.dart';
import 'package:provider/provider.dart';
import 'package:bus_ticket_scanner/providers/scanner_provider.dart';
import 'package:flutter/animation.dart';

class TicketCard extends StatefulWidget {
  final Ticket ticket;

  const TicketCard({super.key, required this.ticket});

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            shadowColor: Colors.black.withOpacity(0.2),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: widget.ticket.isValid
                          ? Colors.limeAccent
                          : Colors.redAccent,
                      width: 8,
                    ),
                  ),
                  color: widget.ticket.isValid ? Colors.white : Colors.red[50],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BUS TICKET',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              widget.ticket.isValid
                                  ? Icons.verified
                                  : Icons.warning_rounded,
                              key: ValueKey<bool>(widget.ticket.isValid),
                              color: widget.ticket.isValid
                                  ? Colors.lime[700]
                                  : Colors.red[700],
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        color: Colors.grey[300],
                        thickness: 1.5,
                      ),
                      const SizedBox(height: 16),

                      // Ticket Info Rows
                      _buildInfoRow(
                        icon: Icons.confirmation_number,
                        label: 'Booking ID',
                        value: widget.ticket.formattedBookingId,
                      ),
                      _buildInfoRow(
                        icon: Icons.directions_bus,
                        label: 'Bus Number',
                        value: widget.ticket.formattedBusNumber,
                      ),
                      _buildInfoRow(
                        icon: Icons.credit_card,
                        label: 'Payment Ref',
                        value: widget.ticket.formattedPaymentReference,
                      ),
                      _buildInfoRow(
                        icon: Icons.route,
                        label: 'Route',
                        value: widget.ticket.formattedRoute,
                      ),
                      _buildInfoRow(
                        icon: Icons.chair,
                        label: 'Seat Number',
                        value: widget.ticket.formattedSeat,
                      ),
                      _buildInfoRow(
                        icon: Icons.departure_board,
                        label: 'Departure',
                        value: widget.ticket.formattedDepartureTime,
                      ),
                      _buildInfoRow(
                        icon: Icons.share_arrival_time_sharp,
                        label: 'Arrival',
                        value: widget.ticket.formattedArrivalTime,
                      ),

                      // Payment Info Section
                      if (widget.ticket.fullPaymentInfo.isNotEmpty)
                        _buildPaymentInfoSection(
                            widget.ticket.formattedFullPaymentInfo),

                      // Validation Badge
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.ticket.isValid
                                ? [Colors.lime[100]!, Colors.lime[50]!]
                                : [Colors.red[100]!, Colors.red[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.ticket.isValid
                                ? Colors.lime[400]!
                                : Colors.red[300]!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.ticket.isValid
                                ? 'VALID TICKET'
                                : 'INVALID TICKET',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: widget.ticket.isValid
                                  ? Colors.lime[800]!
                                  : Colors.red[700]!,
                            ),
                          ),
                        ),
                      ),

                      // Scan Next Button
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text(
                            'SCAN NEXT TICKET',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.limeAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.2),
                          ),
                          onPressed: () {
                            Provider.of<ScannerProvider>(context, listen: false)
                                .clearScan();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: Colors.grey[200],
                  thickness: 1,
                  height: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoSection(String paymentInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.payment,
              size: 22,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              'Payment Details',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Text(
            paymentInfo,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
