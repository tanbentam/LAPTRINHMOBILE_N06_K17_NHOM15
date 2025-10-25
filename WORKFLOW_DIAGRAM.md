# 📊 Crypto Trading App - Complete Workflow

## 🎯 Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                      │
├─────────────────────────────────────────────────────────────┤
│  LoginPage │ HomePage │ MarketPage │ TradePage │ AssetsPage │
│                      HistoryPage                             │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                      SERVICE LAYER                           │
├─────────────────────────────────────────────────────────────┤
│  AuthService │ FirestoreService │ CoinGeckoService          │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                      DATA LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  Firebase Auth │ Cloud Firestore │ CoinGecko API            │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 User Flow Chi Tiết

### 1️⃣ Authentication Flow

```
┌─────────┐
│  Start  │
└────┬────┘
     │
     ▼
┌─────────────┐
│ LoginPage   │
│ - Email     │
│ - Password  │
└────┬────────┘
     │
     ├─── Login ──────┐
     │                │
     └─── Signup ─────┤
                      │
                      ▼
            ┌─────────────────┐
            │  AuthService    │
            │ .signUp() or    │
            │ .signIn()       │
            └────┬────────────┘
                 │
                 ▼
      ┌──────────────────────┐
      │  Firebase Auth        │
      │  - Hash password      │
      │  - Create user        │
      └────┬─────────────────┘
           │
           ├─── If Signup ────────┐
           │                      │
           │                      ▼
           │          ┌───────────────────────┐
           │          │  FirestoreService     │
           │          │  .createUserDocument()│
           │          │  - uid                │
           │          │  - email              │
           │          │  - balance: 1000 USDT │
           │          │  - holdings: {}       │
           │          │  - favorites: []      │
           │          └───────────────────────┘
           │
           ▼
    ┌────────────┐
    │  HomePage  │
    └────────────┘
```

---

### 2️⃣ Market Discovery Flow

```
┌────────────┐
│ MarketPage │
└─────┬──────┘
      │
      ├──────────────────────────────────┐
      │                                  │
      ▼                                  ▼
┌──────────────────┐          ┌────────────────────┐
│ CoinGeckoService │          │ FirestoreService   │
│ .getCoinMarkets()│          │ .getUserData()     │
│ - Get 100 coins  │          │ - Get favorites    │
│ - Real prices    │          └────────────────────┘
└──────────────────┘
      │
      ▼
┌─────────────────────────────┐
│  Display Coins              │
│  ┌─────────────────────┐    │
│  │ Tabs:               │    │
│  │ - Tất cả            │    │
│  │ - Yêu thích ⭐      │    │
│  │ - Top Gainers 📈    │    │
│  │ - Top Losers 📉     │    │
│  └─────────────────────┘    │
│                             │
│  For each coin:             │
│  - Logo                     │
│  - Name & Symbol            │
│  - Current Price            │
│  - 24h Change %             │
│  - Favorite Button ⭐       │
│  - Trade Button 🛒          │
└─────────────────────────────┘
      │
      ├─── Click Favorite ─────┐
      │                        │
      │                        ▼
      │            ┌────────────────────────┐
      │            │ FirestoreService       │
      │            │ .updateFavorites()     │
      │            │ - Save to Firestore    │
      │            └────────────────────────┘
      │
      └─── Click Trade ───────┐
                              │
                              ▼
                        ┌────────────┐
                        │ TradePage  │
                        └────────────┘
```

---

### 3️⃣ Trading Flow

```
┌────────────┐
│ TradePage  │
│ (coin: BTC)│
└─────┬──────┘
      │
      ▼
┌───────────────────────────────┐
│ Load User Data (StreamBuilder)│
│ - Current balance             │
│ - Current holdings            │
└───────┬───────────────────────┘
        │
        ▼
┌───────────────────────────────┐
│ User Input                    │
│ ┌─────────────────┐           │
│ │ Select: Buy/Sell│           │
│ └─────────────────┘           │
│                               │
│ Price: $67,000 (auto-filled) │
│ Amount: 0.01 BTC              │
│ Total: $670 (auto-calc)       │
│                               │
│ Quick: [25%][50%][75%][100%] │
└───────┬───────────────────────┘
        │
        ▼
┌───────────────────────────────┐
│ Click "Mua BTC" or "Bán BTC"  │
└───────┬───────────────────────┘
        │
        ▼
┌───────────────────────────────┐
│ Validation                    │
│ ┌───────────────────────┐     │
│ │ If BUY:               │     │
│ │ - Balance >= Total?   │     │
│ │                       │     │
│ │ If SELL:              │     │
│ │ - Holdings >= Amount? │     │
│ └───────────────────────┘     │
└───────┬───────────────────────┘
        │
        ├─── ❌ Fail ──→ Show Error
        │
        └─── ✅ Pass ───┐
                        │
                        ▼
            ┌──────────────────────┐
            │ FirestoreService     │
            │ .buyCoin() or        │
            │ .sellCoin()          │
            └──────┬───────────────┘
                   │
                   ▼
        ┌────────────────────────────┐
        │ Firestore Transaction      │
        │ 1. Update balance          │
        │ 2. Update holdings         │
        │ 3. Create transaction doc  │
        └──────┬─────────────────────┘
               │
               ▼
        ┌──────────────────┐
        │ Success! ✅       │
        │ - Show SnackBar  │
        │ - Refresh data   │
        │ - Clear form     │
        └──────────────────┘
```

---

### 4️⃣ Assets View Flow

```
┌────────────┐
│ AssetsPage │
└─────┬──────┘
      │
      ▼
┌───────────────────────────────────┐
│ StreamBuilder<UserModel>          │
│ - Real-time updates từ Firestore  │
└───────┬───────────────────────────┘
        │
        ├──────────────────┐
        │                  │
        ▼                  ▼
┌──────────────┐   ┌──────────────────┐
│ User Balance │   │ User Holdings    │
│ $1,234.56    │   │ BTC: 0.5         │
└──────────────┘   │ ETH: 2.0         │
                   └──────┬───────────┘
                          │
                          ▼
                ┌─────────────────────┐
                │ CoinGeckoService    │
                │ Get current prices  │
                └──────┬──────────────┘
                       │
                       ▼
            ┌────────────────────────────┐
            │ Calculate Total Value      │
            │                            │
            │ Total = Balance +          │
            │   Σ(holding × price)       │
            │                            │
            │ = $1,234.56 +              │
            │   (0.5 BTC × $67,000) +    │
            │   (2.0 ETH × $3,500)       │
            │ = $1,234.56 + $33,500 +    │
            │   $7,000                   │
            │ = $41,734.56               │
            └────────────────────────────┘
                       │
                       ▼
            ┌────────────────────────────┐
            │ Display Assets             │
            │ ┌────────────────────────┐ │
            │ │ Total Value            │ │
            │ │ $41,734.56            │ │
            │ └────────────────────────┘ │
            │                            │
            │ Holdings:                  │
            │ ┌──────────────────────┐   │
            │ │ BTC  0.5 BTC         │   │
            │ │      $33,500  +2.5%  │   │
            │ └──────────────────────┘   │
            │ ┌──────────────────────┐   │
            │ │ ETH  2.0 ETH         │   │
            │ │      $7,000   -1.2%  │   │
            │ └──────────────────────┘   │
            └────────────────────────────┘
```

---

### 5️⃣ Transaction History Flow

```
┌─────────────┐
│ HistoryPage │
└──────┬──────┘
       │
       ▼
┌────────────────────────────────┐
│ StreamBuilder<List<Transaction>>│
│ - Real-time from Firestore     │
└──────┬─────────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│ Query Firestore                │
│ - Where userId = current user  │
│ - Order by timestamp DESC      │
└──────┬─────────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│ Display Transactions           │
│ ┌────────────────────────────┐ │
│ │ ⬇️ MUA BTC                 │ │
│ │ 0.01 BTC @ $67,000        │ │
│ │ Total: $670               │ │
│ │ 25/10/2025 14:30          │ │
│ └────────────────────────────┘ │
│ ┌────────────────────────────┐ │
│ │ ⬆️ BÁN ETH                 │ │
│ │ 1.0 ETH @ $3,500          │ │
│ │ Total: $3,500             │ │
│ │ 24/10/2025 10:15          │ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

---

## 🗄️ Database Schema

### Firestore Collections

#### `users/{userId}`
```javascript
{
  uid: "abc123...",
  email: "user@example.com",
  displayName: null,
  photoURL: null,
  balance: 1000.0,                    // USDT
  holdings: {
    "bitcoin": 0.5,                   // 0.5 BTC
    "ethereum": 2.0                   // 2.0 ETH
  },
  favoriteCoins: ["bitcoin", "ethereum", "cardano"],
  createdAt: "2025-10-25T10:00:00Z",
  updatedAt: "2025-10-25T14:30:00Z"
}
```

#### `transactions/{transactionId}`
```javascript
{
  id: "tx123...",
  userId: "abc123...",
  coinId: "bitcoin",
  coinSymbol: "BTC",
  type: "buy",                        // "buy" or "sell"
  amount: 0.01,                       // 0.01 BTC
  price: 67000.0,                     // $67,000 per BTC
  total: 670.0,                       // $670 total
  timestamp: "2025-10-25T14:30:00Z"
}
```

---

## 🔐 Security Architecture

```
┌──────────────────────────────────────────┐
│           User Registration               │
└──────────────┬───────────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Firebase Auth       │
    │  - Email validation  │
    │  - Password >= 6 char│
    │  - Auto hash password│
    │  - Secure storage    │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Cloud Firestore     │
    │  ✅ ONLY stores:     │
    │  - uid               │
    │  - email             │
    │  - balance           │
    │  - holdings          │
    │  - favorites         │
    │                      │
    │  ❌ NEVER stores:    │
    │  - password          │
    │  - sensitive data    │
    └──────────────────────┘
```

### Security Rules (Recommended)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only read their own transactions
    match /transactions/{transactionId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 📊 Data Flow Summary

```
┌────────────────┐
│   User Action  │
└───────┬────────┘
        │
        ▼
┌────────────────┐      ┌─────────────────┐
│  UI Layer      │◄────►│  State Updates  │
│  (Pages)       │      │  (setState)     │
└───────┬────────┘      └─────────────────┘
        │
        ▼
┌────────────────┐
│ Service Layer  │
│ - AuthService  │
│ - Firestore    │
│ - CoinGecko    │
└───────┬────────┘
        │
        ├──────────────┬──────────────┐
        │              │              │
        ▼              ▼              ▼
┌──────────┐   ┌──────────┐   ┌──────────┐
│ Firebase │   │Firestore │   │CoinGecko │
│   Auth   │   │          │   │   API    │
└──────────┘   └──────────┘   └──────────┘
```

---

## ✅ Key Features

### Real-time Updates
- ✅ User balance (StreamBuilder)
- ✅ Holdings value (StreamBuilder + API)
- ✅ Transaction history (StreamBuilder)
- ✅ Coin prices (CoinGecko API)

### Data Validation
- ✅ Email format check
- ✅ Password min 6 characters
- ✅ Balance check before buy
- ✅ Holdings check before sell
- ✅ Price/amount validation

### User Experience
- ✅ Loading states everywhere
- ✅ Error handling with retry
- ✅ Success notifications
- ✅ Pull-to-refresh
- ✅ Smooth navigation

### Security
- ✅ Password hashed by Firebase
- ✅ No plain text passwords
- ✅ User-specific data access
- ✅ Transaction tracking
- ✅ Audit trail

---

## 🎯 Conclusion

App workflow đã hoàn chỉnh với:
- ✅ Clear separation of concerns
- ✅ Secure authentication
- ✅ Real-time data sync
- ✅ Complete trading functionality
- ✅ Transaction history
- ✅ Favorites management
- ✅ Asset portfolio tracking

**Sẵn sàng để deploy và sử dụng!** 🚀
