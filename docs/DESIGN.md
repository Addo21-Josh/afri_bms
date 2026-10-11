# DESIGN.md — Afri_BMS UI/UX Design System

> Material Design 3 (Material You) with an African-inspired premium theme.

---

## 1. Design Philosophy

| Principle          | Description                                                                         |
| ------------------ | ----------------------------------------------------------------------------------- |
| **Africa-First**   | Warm earth tones, vibrant accents inspired by West African textiles (Ankara, Kente) |
| **Business-Ready** | Clean, professional layouts that build trust with business owners                   |
| **Offline-Aware**  | Clear visual indicators for sync status and offline mode                            |
| **Speed-First**    | Fast interactions, minimal loading states, instant feedback                         |
| **Accessible**     | WCAG 2.1 AA compliant, large touch targets (48dp min), readable fonts               |

---

## 2. Color System

### 2.1 Brand Colors

```dart
// Primary — Deep Indigo (trust, professionalism)
static const primarySeed = Color(0xFF1B3A5C);

// Secondary — Warm Gold (prosperity, Africa-inspired)
static const secondarySeed = Color(0xFFD4A843);

// Tertiary — Terracotta (warmth, earth, heritage)
static const tertiarySeed = Color(0xFFBF6340);
```

### 2.2 Material 3 Dynamic Color Scheme

```dart
final lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primarySeed,
  secondary: AppColors.secondarySeed,
  tertiary: AppColors.tertiarySeed,
  brightness: Brightness.light,
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primarySeed,
  secondary: AppColors.secondarySeed,
  tertiary: AppColors.tertiarySeed,
  brightness: Brightness.dark,
);
```

### 2.3 Semantic Colors

| Purpose       | Light Mode | Dark Mode | Usage                           |
| ------------- | ---------- | --------- | ------------------------------- |
| **Success**   | `#2E7D32`  | `#66BB6A` | Completed sales, synced, profit |
| **Warning**   | `#F57F17`  | `#FFD54F` | Low stock, pending sync         |
| **Error**     | `#C62828`  | `#EF5350` | Failed operations, overdue debt |
| **Info**      | `#1565C0`  | `#42A5F5` | Notifications, hints            |
| **Offline**   | `#616161`  | `#9E9E9E` | Offline mode indicator          |
| **Money In**  | `#2E7D32`  | `#66BB6A` | Income, payments received       |
| **Money Out** | `#C62828`  | `#EF5350` | Expenses, payments made         |

### 2.4 Status Badges

```
┌──────────┬──────────┬──────────┬──────────┐
│  ● Paid  │● Partial │● Unpaid  │● Overdue │
│  Green   │  Amber   │  Orange  │   Red    │
└──────────┴──────────┴──────────┴──────────┘

┌──────────┬──────────┬──────────┐
│● Synced  │● Pending │● Failed  │
│  Green   │  Amber   │   Red    │
└──────────┴──────────┴──────────┘

┌──────────┬──────────┬──────────┐
│● In Stock│● Low     │● Out     │
│  Green   │  Amber   │   Red    │
└──────────┴──────────┴──────────┘
```

---

## 3. Typography

### 3.1 Font Family

| Usage                         | Font              | Fallback           |
| ----------------------------- | ----------------- | ------------------ |
| **Headlines & Display**       | Plus Jakarta Sans | Inter, sans-serif  |
| **Body & UI**                 | Inter             | Roboto, sans-serif |
| **Monospace (numbers/codes)** | JetBrains Mono    | monospace          |

### 3.2 Type Scale (Material 3)

| Style           | Font              | Size | Weight | Line Height | Usage            |
| --------------- | ----------------- | ---- | ------ | ----------- | ---------------- |
| Display Large   | Plus Jakarta Sans | 57sp | 400    | 64sp        | —                |
| Display Medium  | Plus Jakarta Sans | 45sp | 400    | 52sp        | —                |
| Display Small   | Plus Jakarta Sans | 36sp | 400    | 44sp        | Dashboard totals |
| Headline Large  | Plus Jakarta Sans | 32sp | 600    | 40sp        | Screen titles    |
| Headline Medium | Plus Jakarta Sans | 28sp | 600    | 36sp        | Section headers  |
| Headline Small  | Plus Jakarta Sans | 24sp | 600    | 32sp        | Card titles      |
| Title Large     | Inter             | 22sp | 500    | 28sp        | App bar titles   |
| Title Medium    | Inter             | 16sp | 500    | 24sp        | List tile titles |
| Title Small     | Inter             | 14sp | 500    | 20sp        | Subtitles        |
| Body Large      | Inter             | 16sp | 400    | 24sp        | Main body text   |
| Body Medium     | Inter             | 14sp | 400    | 20sp        | Secondary text   |
| Body Small      | Inter             | 12sp | 400    | 16sp        | Captions         |
| Label Large     | Inter             | 14sp | 500    | 20sp        | Buttons          |
| Label Medium    | Inter             | 12sp | 500    | 16sp        | Chips, badges    |
| Label Small     | Inter             | 11sp | 500    | 16sp        | Tiny labels      |

### 3.3 Number Formatting

```dart
// Currency display — always use monospace for alignment
Text(
  '₦1,250,000.00',
  style: TextStyle(
    fontFamily: 'JetBrains Mono',
    fontFeatures: [FontFeature.tabularFigures()],
  ),
)
```

---

## 4. Spacing & Layout

### 4.1 Spacing Scale (4dp base)

| Token        | Value | Usage             |
| ------------ | ----- | ----------------- |
| `space_xxs`  | 2dp   | Inline spacing    |
| `space_xs`   | 4dp   | Icon-text gap     |
| `space_sm`   | 8dp   | Compact padding   |
| `space_md`   | 12dp  | List item padding |
| `space_base` | 16dp  | Standard padding  |
| `space_lg`   | 20dp  | Section spacing   |
| `space_xl`   | 24dp  | Card padding      |
| `space_2xl`  | 32dp  | Screen padding    |
| `space_3xl`  | 40dp  | Large spacing     |
| `space_4xl`  | 48dp  | Hero sections     |
| `space_5xl`  | 64dp  | Major separations |

### 4.2 Border Radius

| Token         | Value | Usage            |
| ------------- | ----- | ---------------- |
| `radius_xs`   | 4dp   | Small badges     |
| `radius_sm`   | 8dp   | Buttons, chips   |
| `radius_md`   | 12dp  | Cards, dialogs   |
| `radius_lg`   | 16dp  | Bottom sheets    |
| `radius_xl`   | 24dp  | FABs             |
| `radius_full` | 999dp | Circular avatars |

### 4.3 Elevation (Material 3 Tonal)

| Level   | Elevation | Usage                |
| ------- | --------- | -------------------- |
| Level 0 | 0dp       | Flat surfaces        |
| Level 1 | 1dp       | Cards at rest        |
| Level 2 | 3dp       | Cards on hover/press |
| Level 3 | 6dp       | Navigation bar       |
| Level 4 | 8dp       | FABs                 |
| Level 5 | 12dp      | Dialogs, modals      |

---

## 5. Components

### 5.1 Navigation

#### Bottom Navigation Bar (Primary)

```
┌─────────────────────────────────────────┐
│                                         │
│              [Screen Content]           │
│                                         │
├─────────────────────────────────────────┤
│  🏠        📦        🛒       📊    ⚙️  │
│ Home    Inventory   Sales   Reports  More│
└─────────────────────────────────────────┘
```

- **Admin/Branch Manager**: Home, Inventory, Sales, Reports, More
- **Salesperson**: Home, Sales, Customers, More
- **Cashier**: Sales (POS), Receipts

#### Side Navigation (Tablet landscape, if supported)

```
┌──────┬──────────────────────────────────┐
│ Logo │                                  │
│──────│                                  │
│ 🏠   │        [Screen Content]          │
│ 📦   │                                  │
│ 🛒   │                                  │
│ 💰   │                                  │
│ 👥   │                                  │
│ 📊   │                                  │
│ ⚙️   │                                  │
└──────┴──────────────────────────────────┘
```

### 5.2 Dashboard Cards

```
┌─────────────────────────────────────────┐
│  Today's Sales                    ▲ 12% │
│  ₦ 1,250,000                           │
│  ████████████████████░░░░  83% of target │
│  48 transactions                         │
└─────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐
│  💰 Revenue      │  │  📦 Products     │
│  ₦ 3.2M          │  │  1,247 items     │
│  This month      │  │  23 low stock    │
└──────────────────┘  └──────────────────┘
```

### 5.3 Product Card

```
┌─────────────────────────────────────────┐
│ ┌──────┐                                │
│ │ IMG  │  Product Name                  │
│ │      │  Category • SKU-12345          │
│ └──────┘  ₦ 2,500.00                   │
│           Stock: 45 pcs   ● In Stock    │
│  [Edit]  [Barcode]  [View Details →]    │
└─────────────────────────────────────────┘
```

### 5.4 Sale/POS Screen

```
┌─────────────────────────────────────────┐
│  🔍 Search or scan barcode...    [📷]   │
├─────────────────────────────────────────┤
│  ┌──────────────────────────────────┐   │
│  │ Item 1               ₦2,500 × 2 │   │
│  │ Item 2               ₦1,000 × 1 │   │
│  │ Item 3               ₦3,750 × 3 │   │
│  └──────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  Subtotal                    ₦17,250.00 │
│  Discount (10%)              -₦1,725.00 │
│  Tax (7.5%)                  +₦1,164.38 │
│  ─────────────────────────────────────  │
│  TOTAL                       ₦16,689.38 │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │  💵     │ │  📱     │ │  💳      │  │
│  │  Cash   │ │  MoMo   │ │  Card    │  │
│  └─────────┘ └─────────┘ └──────────┘  │
│                                         │
│  [      Complete Sale ₦16,689.38      ] │
└─────────────────────────────────────────┘
```

### 5.5 Sync Status Indicator

```
// Top of screen — persistent indicator
┌─────────────────────────────────────────┐
│ ☁️ All synced                      │  │ ← Online, all synced
├─────────────────────────────────────────┤

│ 🔄 Syncing 3 items...              │  │ ← Actively syncing
├─────────────────────────────────────────┤

│ 📴 Offline • 12 pending changes    │  │ ← Offline mode
├─────────────────────────────────────────┤

│ ⚠️ Sync failed • Tap to retry      │  │ ← Sync error
└─────────────────────────────────────────┘
```

### 5.6 Receipt Preview

```
┌─────────────────────────────────────────┐
│           BUSINESS NAME                 │
│         Branch: Main Branch             │
│        123 Market Street, Lagos         │
│         Tel: +234 800 1234              │
│  ─────────────────────────────────────  │
│  Receipt #: INV-2026-0042               │
│  Date: 09 Oct 2026  14:23              │
│  Cashier: John Doe                      │
│  ─────────────────────────────────────  │
│  Item            Qty    Price    Total   │
│  Widget A          2   2,500    5,000   │
│  Widget B          1   1,000    1,000   │
│  Widget C          3   3,750   11,250   │
│  ─────────────────────────────────────  │
│  Subtotal                      17,250   │
│  Discount (10%)                -1,725   │
│  VAT (7.5%)                    +1,164   │
│  ═════════════════════════════════════  │
│  TOTAL                     ₦16,689.38   │
│  ═════════════════════════════════════  │
│  Payment: Cash                          │
│  ─────────────────────────────────────  │
│  Customer: Ade Okonkwo                  │
│  ─────────────────────────────────────  │
│         Thank you for your              │
│           business! 🙏                  │
│                                         │
│          [BARCODE/QR CODE]              │
│                                         │
│  [🖨 Print]  [📤 Share]  [💬 WhatsApp]  │
└─────────────────────────────────────────┘
```

---

## 6. Micro-Animations

| Element            | Animation                          | Duration               | Curve          |
| ------------------ | ---------------------------------- | ---------------------- | -------------- |
| Screen transitions | Shared axis (horizontal)           | 300ms                  | easeInOutCubic |
| Bottom sheet       | Slide up with fade                 | 250ms                  | easeOutCubic   |
| Card press         | Scale down 0.98 + elevation change | 100ms                  | easeOut        |
| List items         | Staggered slide up + fade          | 200ms each, 50ms delay | easeOutCubic   |
| Sale complete      | Checkmark lottie + confetti        | 1500ms                 | spring         |
| Sync indicator     | Rotating arrows                    | continuous             | linear         |
| Number counters    | Count up/down animation            | 500ms                  | easeOutCubic   |
| Status badge       | Color morph                        | 200ms                  | easeInOut      |
| FAB                | Scale + rotation on scroll         | 200ms                  | easeInOutCubic |
| Delete swipe       | Slide + shrink + fade              | 300ms                  | easeInOutCubic |
| Pull to refresh    | Custom African pattern spinner     | continuous             | —              |
| Empty state        | Bounce illustration                | 800ms                  | elasticOut     |

---

## 7. Iconography

| Category   | Icon Style                         | Examples                         |
| ---------- | ---------------------------------- | -------------------------------- |
| Navigation | Material Symbols Rounded, filled   | home, inventory_2, point_of_sale |
| Actions    | Material Symbols Rounded, outlined | add, edit, delete, share         |
| Status     | Custom colored dots                | ● synced, ● pending, ● failed    |
| Currency   | Text-based                         | ₦, GH₵, $                        |
| Business   | Custom illustrated                 | shop, warehouse, chart           |

---

## 8. Responsive Breakpoints

| Breakpoint       | Width      | Layout                        |
| ---------------- | ---------- | ----------------------------- |
| Mobile small     | < 360dp    | Single column, compact        |
| Mobile           | 360-599dp  | Single column, standard       |
| Tablet portrait  | 600-839dp  | Two columns where appropriate |
| Tablet landscape | 840-1199dp | Side nav + content            |
| Desktop          | 1200dp+    | Full dashboard layout         |

---

## 9. Dark Mode

- Follows Material 3 dark theme guidelines
- Surface colors use tonal elevation (surface → surfaceContainerLowest → surfaceContainerHighest)
- Gold accent slightly adjusted for contrast on dark surfaces
- Charts and graphs adapt colors for dark backgrounds
- User preference stored locally; system default as fallback

---

## 10. Accessibility

| Feature          | Implementation                                   |
| ---------------- | ------------------------------------------------ |
| Touch targets    | Minimum 48×48dp                                  |
| Color contrast   | 4.5:1 for normal text, 3:1 for large text        |
| Screen reader    | All interactive elements have semantic labels    |
| Font scaling     | Supports system font size (up to 200%)           |
| Focus indicators | Visible focus rings on all interactive elements  |
| Haptic feedback  | On successful sale, barcode scan, delete actions |

---

## 11. Loading & Empty States

### Loading States

```dart
// Skeleton loading for lists
ShimmerLoading(
  child: Column(
    children: List.generate(5, (_) => ProductCardSkeleton()),
  ),
)

// Inline loading for buttons
ElevatedButton(
  onPressed: isLoading ? null : onPressed,
  child: isLoading
    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
    : Text('Save'),
)
```

### Empty States

Each feature has a custom empty state with:

1. Illustrated icon/image (Africa-themed)
2. Descriptive title
3. Helpful subtitle
4. Primary action button

```
┌─────────────────────────────────────────┐
│                                         │
│          📦                             │
│     (illustration)                      │
│                                         │
│     No products yet                     │
│                                         │
│  Add your first product to start        │
│  managing your inventory                │
│                                         │
│  [  + Add Product  ]                    │
│                                         │
└─────────────────────────────────────────┘
```

---

## 12. Onboarding Flow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Onboarding
 images
 with texts
 and
 Welcome  │ →  │ Create   │ →  │ Set Up   │ →  │ Add Your │
│ to       │    │ Your     │    │ Your     │    │ First    │
│Afri_BMS │    │ Account  │    │ Business │    │ Product  │
│          │    │          │    │          │    │          │
│ [Start]  │    │ Name     │    │ Biz Name │    │ [Scan]   │
│          │    │ Email    │    │ Currency │    │ [Manual] │
│          │    │ Password │    │ Branch   │    │ [Skip]   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```
