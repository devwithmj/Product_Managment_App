import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../models/product.dart';
import '../utils/constants.dart';
import '../screens/price_history_screen.dart';

class ProductItem extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final Function(bool) onSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onDuplicate; // New callback for duplicate action

  const ProductItem({
    Key? key,
    required this.product,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
    this.onDuplicate, // Optional parameter for duplicate action
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => onSelected(value ?? false),
        title: Text(
          product.nameEn,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: AppFonts.englishFont,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Persian name with RTL
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                product.nameFa,
                style: const TextStyle(fontFamily: AppFonts.persianFont),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${product.brandEn} - ${product.size}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                // Price with update indicator
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        product.priceUpdated
                            ? AppColors.priceUpdated
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (product.barcode.isNotEmpty)
              Text(
                'Barcode: ${product.barcode}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            // Show last updated timestamp
            Text(
              'Updated: ${intl.DateFormat('MMM d, yyyy').format(product.updatedAt)}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        secondary: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price history button
            IconButton(
              icon: const Icon(Icons.history, color: Colors.blue),
              tooltip: 'Price History',
              onPressed: () => _showPriceHistory(context),
            ),
            _buildStoreIndicator(),
            // Duplicate button (new)
            if (onDuplicate != null)
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.purple),
                tooltip: 'Duplicate Product',
                onPressed: onDuplicate,
              ),
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              tooltip: 'Edit Product',
              onPressed: onEdit,
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Product',
              onPressed: onDelete,
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _showPriceHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PriceHistoryScreen(product: product),
      ),
    );
  }

  Widget _buildStoreIndicator() {
    Color indicatorColor;
    IconData icon;

    switch (product.storeLocation) {
      case StoreLocation.downtown:
        indicatorColor = Colors.blue;
        icon = Icons.location_city;
        break;
      case StoreLocation.uptown:
        indicatorColor = Colors.green;
        icon = Icons.landscape;
        break;
      case StoreLocation.both:
        indicatorColor = Colors.purple;
        icon = Icons.store;
        break;
    }

    return Tooltip(
      message:
          product.storeLocation == StoreLocation.downtown
              ? AppStrings.downtown
              : product.storeLocation == StoreLocation.uptown
              ? AppStrings.uptown
              : AppStrings.both,
      child: Icon(icon, color: indicatorColor, size: 20),
    );
  }
}
