import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as inl;
import '../models/product.dart';
import '../models/price_log.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class PriceHistoryScreen extends StatefulWidget {
  final Product product;

  const PriceHistoryScreen({Key? key, required this.product}) : super(key: key);

  @override
  _PriceHistoryScreenState createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<PriceLog> _priceLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPriceHistory();
  }

  Future<void> _loadPriceHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _databaseService.getPriceLogs(widget.product.id);
      setState(() {
        _priceLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading price history: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.priceHistory)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info card
          _buildProductCard(),

          // Price history list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _priceLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildPriceHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.nameEn,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            // Persian name with RTL
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                widget.product.nameFa,
                style: const TextStyle(
                  fontFamily: AppFonts.persianFont,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.product.brandEn} - ${widget.product.size}',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Current Price: \$${widget.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.product.priceUpdated
                            ? AppColors.priceUpdated
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16.0),
          Text(
            AppStrings.noHistoryAvailable,
            style: TextStyle(fontSize: 18.0, color: Colors.grey),
          ),
          SizedBox(height: 8.0),
          Text(
            'Price changes will be logged here automatically',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHistoryList() {
    return ListView.builder(
      itemCount: _priceLogs.length,
      itemBuilder: (context, index) {
        final log = _priceLogs[index];
        final isLatest = index == 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          color: isLatest ? Colors.blue.shade50 : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            title: Row(
              children: [
                Text(
                  '\$${log.oldPrice.toStringAsFixed(2)} → \$${log.newPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8.0),
                _buildPriceChangeIndicator(log.oldPrice, log.newPrice),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4.0),
                Text(
                  inl.DateFormat('MMM d, yyyy • h:mm a').format(log.changeDate),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (log.notes != null && log.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Note: ${log.notes}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: isLatest ? Colors.blue : Colors.grey.shade200,
              child: Icon(
                Icons.history,
                color: isLatest ? Colors.white : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceChangeIndicator(double oldPrice, double newPrice) {
    final difference = newPrice - oldPrice;
    final percentChange = (difference / oldPrice) * 100;

    final isPositive = difference > 0;
    final color = isPositive ? Colors.red : Colors.green;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: color),
          const SizedBox(width: 2.0),
          Text(
            '${percentChange.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
