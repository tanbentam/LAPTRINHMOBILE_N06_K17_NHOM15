import 'package:flutter/material.dart';

class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // nền trắng
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          "Tổng quan về tài khoản",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.visibility_outlined, color: Colors.black54),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Tổng giá trị dự kiến
              const Text(
                "Tổng giá trị dự kiến",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    "0.00 ",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      "BTC",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nút nạp tiền
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400), // vàng nhẹ
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Nạp tiền",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Danh sách coin
              const AssetCard(
                icon: Icons.attach_money_rounded,
                iconColor: Colors.teal,
                name: "USDT",
                subtitle: "Stablecoin",
                price: "1 \$",
                percent: "",
              ),
              const AssetCard(
                icon: Icons.currency_bitcoin_rounded,
                iconColor: Colors.orange,
                name: "BTC",
                subtitle: "Giá gần nhất 112,810.63 \$",
                price: "+480.79% trong 3 năm qua",
                percent: "Mua ngay",
              ),
              const AssetCard(
                icon: Icons.token_rounded,
                iconColor: Colors.amber,
                name: "BNB",
                subtitle: "Giá gần nhất 1,009.76 \$",
                price: "+254.55% trong 3 năm qua",
                percent: "Mua ngay",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssetCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String subtitle;
  final String price;
  final String percent;

  const AssetCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Thông tin coin
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 22,
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Giá và nút mua
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (price.isNotEmpty)
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              if (percent.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Mua ngay",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
