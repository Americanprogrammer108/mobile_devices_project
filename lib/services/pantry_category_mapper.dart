class PantryCategoryMapper {
  static const categories = <String>[
    'Dairy',
    'Produce',
    'Meat & Seafood',
    'Frozen',
    'Beverages',
    'Bakery',
    'Pantry Staples',
    'Other',
  ];

  static String suggest({
    Iterable<String> tags = const [],
    String productName = '',
  }) {
    final normalizedTags = tags.join(' ').toLowerCase();
    final name = productName.toLowerCase();
    // Prefer clear product-name matches over broad category tags.
    if (RegExp(
      r'\b(noodles?|pasta|spaghetti|macaroni|rice)\b',
    ).hasMatch(name)) {
      return 'Pantry Staples';
    }
    bool matches(List<String> keywords) {
      return keywords.any(
        (keyword) => normalizedTags.contains(keyword) || name.contains(keyword),
      );
    }

    if (matches(['frozen', 'ice-cream', 'ice cream'])) {
      return 'Frozen';
    }

    if (matches(['milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'dairy'])) {
      return 'Dairy';
    }

    if (matches(['fruit', 'vegetable', 'produce', 'apple', 'banana'])) {
      return 'Produce';
    }

    if (matches(['meat', 'chicken', 'beef', 'pork', 'fish', 'seafood'])) {
      return 'Meat & Seafood';
    }

    if (matches(['beverage', 'drink', 'juice', 'soda', 'coffee', 'tea'])) {
      return 'Beverages';
    }

    if (matches(['bread', 'bakery', 'pastry', 'bagel'])) {
      return 'Bakery';
    }

    if (matches([
      'pasta',
      'noodle',
      'rice',
      'cereal',
      'flour',
      'grain',
      'sauce',
      'spreads',
    ])) {
      return 'Pantry Staples';
    }

    return 'Other';
  }
}
