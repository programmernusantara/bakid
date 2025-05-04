import 'package:bakid/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late SupabaseService _supabaseService;
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
    _fetchPayments();
  }

  String formatDate(String? date) {
    if (date == null) return 'Belum Dibayar';
    final DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd MMM yyyy').format(parsedDate);
  }

  String formatCurrency(dynamic value) {
    if (value == null) return 'Rp0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  void _fetchPayments() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId != null) {
      try {
        final payments = await _supabaseService.fetchPayments(userId);
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error fetching payments: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildPaymentItem(Map<String, dynamic> payment) {
    final isPaid = (payment['status']?.toLowerCase() == 'lunas');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                payment['nama_pembayaran'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaid ? Colors.green[100]! : Colors.red[100]!,
                  ),
                ),
                child: Text(
                  payment['status'] ?? 'Belum Dibayar',
                  style: TextStyle(
                    color: isPaid ? Colors.green[800] : Colors.red[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey[200]),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                LucideIcons.coins,
                'Jumlah',
                formatCurrency(payment['jumlah']),
              ),
              _buildInfoColumn(
                LucideIcons.calendarClock,
                'Jatuh Tempo',
                formatDate(payment['jatuh_tempo']),
              ),
              _buildInfoColumn(
                LucideIcons.calendarCheck,
                'Dibayar',
                formatDate(payment['tanggal_bayar']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.blueGrey[400]),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
              )
              : _payments.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.fileSearch,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ada data pembayaran',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: _payments.length,
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemBuilder:
                    (context, index) => buildPaymentItem(_payments[index]),
              ),
    );
  }
}
