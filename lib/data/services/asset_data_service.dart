import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/recipe.dart';

/// Loads bundled static JSON datasets without requiring network or cloud storage.
class AssetDataService {
  static const String _recipesAssetPath = 'assets/data/recipes_mm.json';
  List<Recipe>? _cachedRecipes;

  Future<List<Recipe>> loadRecipes() async {
    if (_cachedRecipes != null) return _cachedRecipes!;
    final raw = await rootBundle.loadString(_recipesAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    _cachedRecipes = decoded
        .whereType<Map<String, dynamic>>()
        .map(Recipe.fromJson)
        .toList();
    return _cachedRecipes!;
  }
}
