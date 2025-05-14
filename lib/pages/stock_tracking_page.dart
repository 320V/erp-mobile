import 'package:flutter/material.dart';

class StockTrackingPage extends StatefulWidget {
  @override
  _StockTrackingPageState createState() => _StockTrackingPageState();
}

class _StockTrackingPageState extends State<StockTrackingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchCriteria = 'Ürün Adı';
  String _selectedFilter = 'Tüm Ürünler';
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Sample data - will be replaced with API data
  final List<Map<String, dynamic>> _sampleProducts = List.generate(
    100,
    (index) => {
      'name': 'Ürün ${index + 1}',
      'code': 'KOD${index + 1}',
      'accountingCode': 'MHS${index + 1}',
      'supplierCode': 'TDR${index + 1}',
      'brand': 'Marka ${(index % 5) + 1}',
      'shelf': 'Raf ${(index % 10) + 1}',
      'stockLevel': (index % 3) == 0 ? 'Kritik' : (index % 3) == 1 ? 'Öncü' : 'Normal',
    },
  );

  List<String> _searchCriteria = [
    'Ürün Adı',
    'Ürün Kodu',
    'Muhasebe Kodu',
    'Tedarikçi Kodu',
    'Marka',
    'Raf'
  ];

  List<String> _filters = [
    'Tüm Ürünler',
    'Öncü Uyarılar',
    'Kritik Seviye'
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _sampleProducts;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) {
        final searchTerm = _searchController.text.toLowerCase();
        switch (_selectedSearchCriteria) {
          case 'Ürün Adı':
            return product['name'].toString().toLowerCase().contains(searchTerm);
          case 'Ürün Kodu':
            return product['code'].toString().toLowerCase().contains(searchTerm);
          case 'Muhasebe Kodu':
            return product['accountingCode'].toString().toLowerCase().contains(searchTerm);
          case 'Tedarikçi Kodu':
            return product['supplierCode'].toString().toLowerCase().contains(searchTerm);
          case 'Marka':
            return product['brand'].toString().toLowerCase().contains(searchTerm);
          case 'Raf':
            return product['shelf'].toString().toLowerCase().contains(searchTerm);
          default:
            return true;
        }
      }).toList();
    }

    // Apply stock level filter
    switch (_selectedFilter) {
      case 'Öncü Uyarılar':
        filtered = filtered.where((product) => product['stockLevel'] == 'Öncü').toList();
        break;
      case 'Kritik Seviye':
        filtered = filtered.where((product) => product['stockLevel'] == 'Kritik').toList();
        break;
    }

    return filtered;
  }

  List<Map<String, dynamic>> get _paginatedProducts {
    final startIndex = _currentPage * _itemsPerPage;
    return _filteredProducts.skip(startIndex).take(_itemsPerPage).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stok Takip'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Ara...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedSearchCriteria,
                  items: _searchCriteria.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSearchCriteria = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _currentPage = 0;
                      });
                    },
                    backgroundColor: _selectedFilter == filter
                        ? (filter == 'Öncü Uyarılar'
                            ? Colors.yellow.withOpacity(0.3)
                            : filter == 'Kritik Seviye'
                                ? Colors.red.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.3))
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Ürün Adı')),
                    DataColumn(label: Text('Ürün Kodu')),
                    DataColumn(label: Text('Muhasebe Kodu')),
                    DataColumn(label: Text('Tedarikçi Kodu')),
                    DataColumn(label: Text('Marka')),
                    DataColumn(label: Text('Raf')),
                  ],
                  rows: _paginatedProducts.map((product) {
                    return DataRow(
                      cells: [
                        DataCell(Text(product['name'])),
                        DataCell(Text(product['code'])),
                        DataCell(Text(product['accountingCode'])),
                        DataCell(Text(product['supplierCode'])),
                        DataCell(Text(product['brand'])),
                        DataCell(Text(product['shelf'])),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text('Sayfa ${_currentPage + 1}'),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: (_currentPage + 1) * _itemsPerPage < _filteredProducts.length
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 