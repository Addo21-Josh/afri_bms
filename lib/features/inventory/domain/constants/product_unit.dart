import 'package:flutter/material.dart';

/// Categories of business units available in Afri_BMS
enum ProductUnitCategory {
  all('All Units', Icons.apps_outlined),
  pharmacy('Pharmacy & Health', Icons.medical_services_outlined),
  clothing('Clothing & Fashion', Icons.checkroom_outlined),
  general('General & Bulk', Icons.inventory_2_outlined),
  weight('Weight & Mass', Icons.scale_outlined),
  volume('Volume & Liquids', Icons.local_drink_outlined),
  food('Food & Groceries', Icons.restaurant_outlined);

  const ProductUnitCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Represents a standardized product measurement unit
class ProductUnit {
  const ProductUnit({
    required this.code,
    required this.name,
    required this.description,
    required this.category,
  });

  final String code;
  final String name;
  final String description;
  final ProductUnitCategory category;

  String get displayName => '$name ($code)';
}

/// Comprehensive registry of units across pharmacies, fashion, retail, groceries, and bulk trade
class ProductUnits {
  ProductUnits._();

  static const List<ProductUnit> all = [
    // ─── Pharmacy & Healthcare ───
    ProductUnit(
      code: 'tab',
      name: 'Tablets',
      description: 'Pills, tablets, chewables, and lozenges',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'cap',
      name: 'Capsules',
      description: 'Gelatin capsules and softgels',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'strip',
      name: 'Strips / Blisters',
      description: 'Blister packs of tablets or capsules',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'bottle',
      name: 'Bottles',
      description: 'Syrups, suspensions, drops, and liquid medicines',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'tube',
      name: 'Tubes',
      description: 'Ointments, topical creams, and gels',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'vial',
      name: 'Vials',
      description: 'Sterile injection vials and serums',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'ampoule',
      name: 'Ampoules',
      description: 'Hermetically sealed glass injection ampoules',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'sachet',
      name: 'Sachets',
      description: 'Powders, ORS, effervescent granules',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'dose',
      name: 'Doses',
      description: 'Single doses, vaccines, or treatment courses',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'syringe',
      name: 'Syringes',
      description: 'Disposable and pre-filled syringes',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'drop',
      name: 'Drops',
      description: 'Eye, ear, and pediatric drop formulations',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'inhaler',
      name: 'Inhalers',
      description: 'Metered-dose inhalers and puffers',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'supp',
      name: 'Suppositories',
      description: 'Rectal suppositories and vaginal pessaries',
      category: ProductUnitCategory.pharmacy,
    ),
    ProductUnit(
      code: 'patch',
      name: 'Patches',
      description: 'Transdermal medication patches',
      category: ProductUnitCategory.pharmacy,
    ),

    // ─── Clothing, Fashion & Textiles ───
    ProductUnit(
      code: 'pair',
      name: 'Pairs',
      description: 'Footwear, socks, sandals, gloves, and earrings',
      category: ProductUnitCategory.clothing,
    ),
    ProductUnit(
      code: 'yard',
      name: 'Yards',
      description: 'African wax prints, lace, kente, and fabrics',
      category: ProductUnitCategory.clothing,
    ),
    ProductUnit(
      code: 'm',
      name: 'Metres',
      description: 'Textile fabric, elastic, ribbon, and trimmings',
      category: ProductUnitCategory.clothing,
    ),
    ProductUnit(
      code: 'set',
      name: 'Sets',
      description: 'Suits, matching 2-piece outfits, and pyjamas',
      category: ProductUnitCategory.clothing,
    ),
    ProductUnit(
      code: 'bale',
      name: 'Bales',
      description: 'Second-hand clothes bales, bulk denim/linens',
      category: ProductUnitCategory.clothing,
    ),
    ProductUnit(
      code: 'roll',
      name: 'Rolls',
      description: 'Cloth rolls, bandages, interfacing, and linings',
      category: ProductUnitCategory.clothing,
    ),
    ProductUnit(
      code: 'bundle',
      name: 'Bundles',
      description: 'Hair extensions, wigs, knitting yarn, and threads',
      category: ProductUnitCategory.clothing,
    ),
    ProductUnit(
      code: 'doz',
      name: 'Dozen',
      description: 'Pack of 12 items (singlets, socks, underwear)',
      category: ProductUnitCategory.clothing,
    ),

    // ─── General Retail & Packaging ───
    ProductUnit(
      code: 'pcs',
      name: 'Pieces',
      description: 'Single piece / individual discrete item',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'pack',
      name: 'Packs',
      description: 'Pre-packaged multi-item packs',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'box',
      name: 'Boxes',
      description: 'Boxed merchandise, electronics, shoes',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'carton',
      name: 'Cartons',
      description: 'Wholesale master cartons / cases',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'crate',
      name: 'Crates',
      description: 'Beverage bottles crates, egg crates',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'bag',
      name: 'Bags',
      description: 'Bags of rice, sugar, cement, flour, fertilizer',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'sack',
      name: 'Sacks',
      description: 'Jute and woven poly sacks for produce',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'can',
      name: 'Cans',
      description: 'Canned drinks, spray cans, tinned fish',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'tin',
      name: 'Tins',
      description: 'Powdered milk tins, tomato paste, paint tins',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'bucket',
      name: 'Buckets',
      description: 'Paint buckets, cooking oil buckets',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'basket',
      name: 'Baskets',
      description: 'Fresh market produce, tomatoes, onions',
      category: ProductUnitCategory.general,
    ),
    ProductUnit(
      code: 'unit',
      name: 'Units',
      description: 'General equipment, appliances, accessories',
      category: ProductUnitCategory.general,
    ),

    // ─── Volume & Liquids ───
    ProductUnit(
      code: 'litre',
      name: 'Litres',
      description: 'Cooking oil, fuel, kerosene, detergents',
      category: ProductUnitCategory.volume,
    ),
    ProductUnit(
      code: 'ml',
      name: 'Millilitres',
      description: 'Perfumes, small cosmetics, cough syrups',
      category: ProductUnitCategory.volume,
    ),
    ProductUnit(
      code: 'cl',
      name: 'Centilitres',
      description: 'Soft drinks, beer, spirits',
      category: ProductUnitCategory.volume,
    ),
    ProductUnit(
      code: 'gallon',
      name: 'Gallons',
      description: 'Paint gallons, bulk palm oil gallons',
      category: ProductUnitCategory.volume,
    ),
    ProductUnit(
      code: 'jar',
      name: 'Jars',
      description: 'Peanut butter, jam, honey, hair pomade jars',
      category: ProductUnitCategory.volume,
    ),
    ProductUnit(
      code: 'tub',
      name: 'Tubs',
      description: 'Margarine, shea butter, ice cream tubs',
      category: ProductUnitCategory.volume,
    ),

    // ─── Weight & Mass ───
    ProductUnit(
      code: 'kg',
      name: 'Kilograms',
      description: 'Meat, fresh fish, bulk grains, vegetables',
      category: ProductUnitCategory.weight,
    ),
    ProductUnit(
      code: 'g',
      name: 'Grams',
      description: 'Spices, baking ingredients, gold, tea leaves',
      category: ProductUnitCategory.weight,
    ),
    ProductUnit(
      code: 'mg',
      name: 'Milligrams',
      description: 'Chemical formulations, pharmaceutical actives',
      category: ProductUnitCategory.weight,
    ),
    ProductUnit(
      code: 'ton',
      name: 'Tonnes',
      description: 'Heavy construction materials, bulk produce',
      category: ProductUnitCategory.weight,
    ),
    ProductUnit(
      code: 'lb',
      name: 'Pounds',
      description: 'Imported groceries and meats',
      category: ProductUnitCategory.weight,
    ),

    // ─── Food, Bakery & Agriculture ───
    ProductUnit(
      code: 'loaf',
      name: 'Loaves',
      description: 'Bread and cake loaves',
      category: ProductUnitCategory.food,
    ),
    ProductUnit(
      code: 'bar',
      name: 'Bars',
      description: 'Soap bars, chocolate bars, energy bars',
      category: ProductUnitCategory.food,
    ),
    ProductUnit(
      code: 'bunch',
      name: 'Bunches',
      description: 'Bananas, plantains, carrots, greens',
      category: ProductUnitCategory.food,
    ),
    ProductUnit(
      code: 'tray',
      name: 'Trays',
      description: 'Egg trays (30 eggs), meat trays, pastry trays',
      category: ProductUnitCategory.food,
    ),
  ];

  /// Find a unit by code (case-insensitive)
  static ProductUnit? find(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final clean = code.trim().toLowerCase();
    for (final u in all) {
      if (u.code.toLowerCase() == clean || u.name.toLowerCase() == clean) {
        return u;
      }
    }
    return null;
  }

  /// Formats a unit code into a user-friendly label (e.g. 'tab' -> 'Tablets (tab)', 'custom' -> 'custom')
  static String format(String? code) {
    if (code == null || code.trim().isEmpty) return 'Pieces (pcs)';
    final found = find(code);
    if (found != null) {
      return found.displayName;
    }
    return code;
  }

  /// Returns a concise unit code for compact spaces (e.g. POS receipt or product card)
  static String formatShort(String? code) {
    if (code == null || code.trim().isEmpty) return 'pcs';
    return code.trim();
  }
}
