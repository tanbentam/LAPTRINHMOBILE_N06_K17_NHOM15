import 'package:flutter/material.dart';

class TradePage extends StatefulWidget {
  const TradePage({super.key});

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isBuy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'BTC/USDT',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Lệnh chờ'),
              Tab(text: 'Tài sản'),
              Tab(text: 'Lưới Spot'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==== BẢNG GIÁ ====
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text(
                          'Giá (USDT) / Số lượng (BTC)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._buildPriceList(isBuy: false), // giá bán (đỏ)
                        const Divider(),
                        ..._buildPriceList(isBuy: true), // giá mua (xanh)
                      ],
                    ),
                  ),
                ),

                // ==== FORM MUA/BÁN ====
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // Nút MUA / BÁN
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isBuy = true),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isBuy ? Colors.green : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Mua',
                                        style: TextStyle(
                                          color: isBuy ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isBuy = false),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: !isBuy ? Colors.red : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Bán',
                                        style: TextStyle(
                                          color: !isBuy ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Kiểu lệnh
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Limit', style: TextStyle(fontWeight: FontWeight.bold)),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _inputField('Giá (USDT)'),
                        const SizedBox(height: 8),
                        _inputField('Số lượng (BTC)'),
                        const SizedBox(height: 8),
                        _inputField('Tổng (USDT)'),

                        const SizedBox(height: 12),

                        // Nút thực hiện
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBuy ? Colors.green : Colors.red,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isBuy ? 'Mua BTC' : 'Bán BTC',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm tạo danh sách giá
  List<Widget> _buildPriceList({required bool isBuy}) {
    final prices = List.generate(6, (i) => 112850 - i * 5.0);
    final amounts = List.generate(6, (i) => (0.001 * (i + 1)).toStringAsFixed(5));
    return prices.asMap().entries.map((e) {
      final color = isBuy ? Colors.green : Colors.red;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              e.value.toStringAsFixed(2),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            Text(amounts[e.key], style: const TextStyle(color: Colors.black)),
          ],
        ),
      );
    }).toList();
  }

  // Ô nhập liệu
  Widget _inputField(String label) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      keyboardType: TextInputType.number,
    );
  }
}
