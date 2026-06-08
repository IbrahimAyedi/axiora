import 'package:flutter/foundation.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

// service mte3 ML Kit Entity Extraction
// yestخرج entities men texte kif date, phone, email, address...
class EntityExtractionService {
  // extractor mte3 ML Kit
  EntityExtractor? _extractor;

  // initialisation mte3 entity extractor
  Future<void> initialize() async {
    try {
      // nختارو language french 5ater description ممكن تكون bil francais
      _extractor = EntityExtractor(language: EntityExtractorLanguage.french);
      debugPrint('Entity extractor initialized');
    } catch (e) {
      // ken fama erreur fi initialization
      debugPrint('Error initializing entity extractor: $e');
    }
  }

  // extract entities men text
  Future<List<Map<String, dynamic>>> extractEntities(String text) async {
    // ken text feragh, nرجعou liste fergha
    if (text.trim().isEmpty) {
      return [];
    }

    try {
      // ken extractor mazal ma t3amallouch initialize, nعملouh
      if (_extractor == null) {
        await initialize();
      }

      // ken ba3d initialize mazal null, nوقفou
      if (_extractor == null) {
        debugPrint('Entity extractor not ready');
        return [];
      }

      // ML Kit yanalysi text w yrajja3 annotations
      final annotations = await _extractor!.annotateText(text);

      // liste final mte3 entities
      final entities = <Map<String, dynamic>>[];

      // nعديو 3la kol annotation
      for (final annotation in annotations) {
        // kol annotation tnajem feha akther men entity
        for (final entity in annotation.entities) {
          // n7adhrou entity data bech UI wala constat yesta3melha
          final entityData = <String, dynamic>{
            'type': _entityTypeToString(entity.type),
            'text': annotation.text,
          };

          // nzidou entity lel liste
          entities.add(entityData);
        }
      }

      debugPrint('Extracted ${entities.length} entities from text');
      return entities;
    } catch (e) {
      // ken extraction tfشل, nرجعou liste fergha
      debugPrint('Error extracting entities: $e');
      return [];
    }
  }

  // t7awel EntityType mte3 ML Kit l string understandable
  String _entityTypeToString(EntityType type) {
    switch (type) {
      case EntityType.address:
        return 'Address';
      case EntityType.dateTime:
        return 'Date';
      case EntityType.email:
        return 'Email';
      case EntityType.flightNumber:
        return 'Flight Number';
      case EntityType.iban:
        return 'IBAN';
      case EntityType.isbn:
        return 'ISBN';
      case EntityType.money:
        return 'Money';
      case EntityType.paymentCard:
        return 'Payment Card';
      case EntityType.phone:
        return 'Phone';
      case EntityType.trackingNumber:
        return 'Tracking Number';
      case EntityType.url:
        return 'URL';
      case EntityType.unknown:
        return 'Unknown';
    }
  }

  // nsakrou extractor bech ma يصيرch memory leak
  Future<void> dispose() async {
    await _extractor?.close();
    _extractor = null;
  }
}
