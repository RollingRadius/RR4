import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MsInventoryScreen extends StatefulWidget {
  const MsInventoryScreen({super.key});

  @override
  State<MsInventoryScreen> createState() => _MsInventoryScreenState();
}

class _MsInventoryScreenState extends State<MsInventoryScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  int _selectedCategory = 0;
  final _searchCtrl = TextEditingController();

  static const _categories = ['All', 'Engine', 'Brakes', 'Electrical', 'Tires', 'Fluids'];
  static const _categoryIcons = [
    Icons.category_outlined,
    Icons.settings_input_component_outlined,
    Icons.album_outlined,
    Icons.bolt_outlined,
    Icons.tire_repair_outlined,
    Icons.opacity_outlined,
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                const SizedBox(height: 12),
                _buildItem(
                  name: 'Oil Filter XL-500',
                  id: '#8832',
                  category: 'Engine',
                  location: 'Aisle 4, Shelf B',
                  stock: 4,
                  status: _StockStatus.low,
                ),
                const SizedBox(height: 12),
                _buildItem(
                  name: 'Ceramic Brake Pads',
                  id: '#9241',
                  category: 'Brakes',
                  location: 'Aisle 2, Shelf D',
                  stock: 28,
                  status: _StockStatus.inStock,
                ),
                const SizedBox(height: 12),
                _buildItem(
                  name: 'H7 Headlight Bulb',
                  id: '#4410',
                  category: 'Electrical',
                  location: 'Aisle 12, Shelf A',
                  stock: 0,
                  status: _StockStatus.outOfStock,
                ),
                const SizedBox(height: 12),
                _buildItem(
                  name: 'All-Terrain Tire V2',
                  id: '#2199',
                  category: 'Tires',
                  location: 'Tire Rack 2',
                  stock: 12,
                  status: _StockStatus.inStock,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ms/parts-request'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Request Part', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: _bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: _primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Main Warehouse • South Wing', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by part name or ID...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
                ),
              ),
            ),
            // Category chips
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = _selectedCategory == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? _primary : const Color(0xFFE2E2E2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i != 0) ...[
                            Icon(_categoryIcons[i], size: 15, color: selected ? Colors.white : Colors.grey[600]),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _categories[i],
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required String name,
    required String id,
    required String category,
    required String location,
    required int stock,
    required _StockStatus status,
  }) {
    final Color stripeColor;
    final Color badgeColor;
    final Color badgeBg;
    final String badgeText;

    switch (status) {
      case _StockStatus.low:
        stripeColor = _primary;
        badgeColor = _primary;
        badgeBg = _primary.withOpacity(0.1);
        badgeText = 'Low Stock';
      case _StockStatus.inStock:
        stripeColor = const Color(0xFF22C55E);
        badgeColor = const Color(0xFF16A34A);
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = 'In Stock';
      case _StockStatus.outOfStock:
        stripeColor = const Color(0xFF94A3B8);
        badgeColor = const Color(0xFF64748B);
        badgeBg = const Color(0xFFF1F5F9);
        badgeText = 'Out of Stock';
    }

    return Opacity(
      opacity: status == _StockStatus.outOfStock ? 0.75 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(left: BorderSide(color: Colors.transparent, width: 0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: stripeColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Part image placeholder
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.build_outlined, color: Colors.grey[400], size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                                    child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text('ID: $id • $category', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 3),
                                      Text(location, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 14, color: badgeColor),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$stock in stock',
                                        style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/ms/parts-request'),
                          icon: const Icon(Icons.add_circle_outline, color: _primary, size: 24),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _StockStatus { low, inStock, outOfStock }
