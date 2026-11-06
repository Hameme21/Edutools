import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/section_offering.dart';

class SectionCatalogService {
  static Future<List<SectionOffering>>? _sections;
  static Future<List<String>>? _faculty;
  static Future<List<SectionOffering>> sections() => _sections ??= rootBundle
      .loadString('sample_data/fall_2026_sections.json')
      .then((text) => ((jsonDecode(text) as Map)['offerings'] as List)
          .map((row) => SectionOffering(Map<String, dynamic>.from(row)))
          .toList());
  static Future<List<String>> faculty() => _faculty ??= rootBundle
      .loadString('sample_data/faculties.json')
      .then((text) => (jsonDecode(text) as List)
          .map((row) => row['name'] as String)
          .toSet()
          .toList()
        ..sort());
}
