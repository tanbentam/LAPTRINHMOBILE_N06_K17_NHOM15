import '../models/coin.dart';

/// Lớp này đã được loại bỏ hardcode data.
/// Tất cả dữ liệu coin giờ đều lấy từ CoinGecko API thời gian thực.
/// File này được giữ lại chỉ để tương thích backward, nhưng không nên sử dụng.
class FallbackData {
  @Deprecated('Sử dụng CoinGeckoService.fetchCoins() thay vì hardcode data')
  static List<Coin> getBasicCoins() {
    // Trả về list rỗng để ép buộc sử dụng API
    // Nếu có lỗi, xử lý ở tầng UI với error handling
    return [];
  }
}