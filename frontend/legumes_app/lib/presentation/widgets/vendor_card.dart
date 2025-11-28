// presentation/widgets/vendor_card.dart
import 'package:flutter/material.dart';
import 'package:legumes_app/data/models/auth_model.dart';

class VendorCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const VendorCard({
    super.key,
    required this.vendor,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: vendor.photoUrl != null
                  ? NetworkImage(vendor.photoUrl!)
                  : null,
              child: vendor.photoUrl == null
                  ? const Icon(Icons.store, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.shopName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(vendor.name ?? 'Sans nom'),
                  // Text(vendor.email ?? 'Sans email'),
                  if (vendor.phone != null) Text(vendor.phone!),
                  if (vendor.location != null) Text(vendor.location!),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
