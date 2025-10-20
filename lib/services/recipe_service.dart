class RecipeService {
  static Map<String, Map<String, double>> recipes = {
    'Espresso': {
      'Coffee Beans': 8.0,
      'Paper Cups': 1.0,
    },
    'Cappuccino': {
      'Coffee Beans': 8.0,
      'Whole Milk': 60.0,
      'Paper Cups': 1.0,
    },
    'Latte': {
      'Coffee Beans': 8.0,
      'Whole Milk': 200.0,
      'Paper Cups': 1.0,
    },
    'Americano': {
      'Coffee Beans': 8.0,
      'Paper Cups': 1.0,
    },
    'Croissant': {
      'Croissant': 1.0,
    },
  };

  static Map<String, double> getIngredientsForProduct(
      String productName, int quantity) {
    final recipe = recipes[productName];
    if (recipe == null) return {};

    Map<String, double> usage = {};
    recipe.forEach((ingredient, qtyPerItem) {
      usage[ingredient] = qtyPerItem * quantity;
    });
    return usage;
  }
}
