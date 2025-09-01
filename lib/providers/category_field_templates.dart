// category_field_templates.dart
import 'package:cloud_firestore/cloud_firestore.dart';
class CategoryFieldTemplates {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get fields for a specific category template (works with dynamic templates only)
  static List<Map<String, dynamic>> getFieldsForCategory(
    String templateId, {
    List<String>? parentTemplateIds,
    List<Map<String, dynamic>>? allTemplates,
  }) {
    final fields = <Map<String, dynamic>>[];

    // First, add fields from parent templates (inheritance)
    if (parentTemplateIds != null && allTemplates != null) {
      for (final parentId in parentTemplateIds) {
        final parentTemplate = allTemplates.firstWhere(
          (template) => template['id'] == parentId,
          orElse: () => <String, dynamic>{},
        );
        
        if (parentTemplate.isNotEmpty) {
          final parentFields = List<Map<String, dynamic>>.from(
            parentTemplate['fields'] ?? []
          );
          fields.addAll(parentFields);
        }
      }
    }

    // Then, add fields from the current template (dynamic templates only)
    if (allTemplates != null) {
      final currentTemplate = allTemplates.firstWhere(
        (template) => template['id'] == templateId,
        orElse: () => <String, dynamic>{},
      );
      
      if (currentTemplate.isNotEmpty) {
        final currentFields = List<Map<String, dynamic>>.from(
          currentTemplate['fields'] ?? []
        );
        fields.addAll(currentFields);
      }
    }

    // Remove duplicates based on fieldName and sort by order
    final uniqueFields = <String, Map<String, dynamic>>{};
    for (final field in fields) {
      final fieldName = field['fieldName'] as String? ?? field['name'] as String? ?? '';
      if (fieldName.isNotEmpty) {
        uniqueFields[fieldName] = field;
      }
    }

    final sortedFields = uniqueFields.values.toList();
    sortedFields.sort((a, b) {
      final orderA = a['order'] as int? ?? 999;
      final orderB = b['order'] as int? ?? 999;
      return orderA.compareTo(orderB);
    });

    return sortedFields;
  }

  // Load all dynamic templates from Firestore
  static Future<List<Map<String, dynamic>>> loadAllTemplatesFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('field_templates')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        
        // Clean and normalize the fields when loading from Firestore
        if (data['fields'] != null && data['fields'] is List) {
          final List<dynamic> fields = data['fields'];
          final List<Map<String, dynamic>> normalizedFields = [];
          
          for (final field in fields) {
            if (field is Map<String, dynamic>) {
              final normalizedField = _normalizeFieldStructure(field);
              if (normalizedField != null) {
                normalizedFields.add(normalizedField);
              }
            }
          }
          
          data['fields'] = normalizedFields;
        }
        
        return data;
      }).toList();
    } catch (e) {
      print('Error loading templates from Firestore: $e');
      return [];
    }
  }

  // Normalize field structure from different formats to standard format
 static Map<String, dynamic>? _normalizeFieldStructure(Map<String, dynamic> field) {
  try {
    final normalized = <String, dynamic>{};
    
    // Handle fieldName (could be 'name', 'fieldName', or missing)
    final fieldName = field['fieldName']?.toString().trim() ?? 
                     field['name']?.toString().trim() ?? '';
    if (fieldName.isEmpty) {
      print('❌ Field missing fieldName: $field');
      return null;
    }
    normalized['fieldName'] = fieldName;
    
    // Handle label
    final label = field['label']?.toString().trim() ?? fieldName;
    normalized['label'] = label;
    
    // Handle fieldType (could be 'type', 'fieldType', or missing)
    final fieldType = field['fieldType']?.toString().trim() ?? 
                     field['type']?.toString().trim() ?? 'text';
    normalized['fieldType'] = fieldType;
    
    // Handle isRequired (could be 'required', 'isRequired', or missing)
    final isRequired = field['isRequired'] ?? field['required'] ?? false;
    normalized['isRequired'] = isRequired == true;
    
    // Handle order
    final order = field['order'];
    if (order is num) {
      normalized['order'] = order.toInt();
    } else if (order is String) {
      normalized['order'] = int.tryParse(order) ?? 1;
    } else {
      normalized['order'] = 1;
    }
    
    // Handle placeholder
    final placeholder = field['placeholder']?.toString().trim();
    if (placeholder != null && placeholder.isNotEmpty) {
      normalized['placeholder'] = placeholder;
    }
    
    // NEW: Handle icon configuration
    if (field.containsKey('showFieldIcon')) {
      normalized['showFieldIcon'] = field['showFieldIcon'] == true;
    } else {
      normalized['showFieldIcon'] = false;
    }
    
    if (field.containsKey('fieldIconUrl') && field['fieldIconUrl'] != null) {
      final iconUrl = field['fieldIconUrl'].toString().trim();
      if (iconUrl.isNotEmpty) {
        normalized['fieldIconUrl'] = iconUrl;
      }
    }
    
    // Handle options for dropdown/radio fields
    if (fieldType == 'dropdown' || fieldType == 'radio') {
      if (field['options'] != null && field['options'] is List) {
        final List<dynamic> options = field['options'];
        final List<String> cleanOptions = [];
        
        for (final option in options) {
          if (option != null && option.toString().trim().isNotEmpty) {
            cleanOptions.add(option.toString().trim());
          }
        }
        
        normalized['options'] = cleanOptions;
      } else {
        normalized['options'] = <String>[];
      }
    }
    
    // Handle validation rules
    if (field['validation'] != null && field['validation'] is Map) {
      final validation = Map<String, dynamic>.from(field['validation'] as Map);
      
      // Clean numeric validation values
      ['min', 'max', 'minLength', 'maxLength', 'maxSize'].forEach((key) {
        if (validation[key] != null) {
          if (validation[key] is String) {
            final numValue = num.tryParse(validation[key]);
            if (numValue != null) {
              validation[key] = numValue;
            } else {
              validation.remove(key);
            }
          }
        }
      });
      
      // Clean allowedTypes
      if (validation['allowedTypes'] != null) {
        if (validation['allowedTypes'] is String) {
          final typesString = validation['allowedTypes'] as String;
          validation['allowedTypes'] = typesString
              .split(',')
              .map((type) => type.trim().toLowerCase())
              .where((type) => type.isNotEmpty)
              .toList();
        } else if (validation['allowedTypes'] is List) {
          final typesList = validation['allowedTypes'] as List;
          validation['allowedTypes'] = typesList
              .map((type) => type.toString().trim().toLowerCase())
              .where((type) => type.isNotEmpty)
              .toList();
        }
      }
      
      // Only add validation if it has valid rules
      if (validation.isNotEmpty) {
        normalized['validation'] = validation;
      }
    }
    
    return normalized;
  } catch (e) {
    print('❌ Error normalizing field structure: $e, Field: $field');
    return null;
  }
}

  // Create a new dynamic template in Firestore
  static Future<String> createDynamicTemplate(Map<String, dynamic> templateData) async {
    try {
      // Validate template data
      if (!_validateTemplateData(templateData)) {
        throw Exception('Invalid template data');
      }

      final docRef = await _firestore.collection('field_templates').add({
        ...templateData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return docRef.id;
    } catch (e) {
      print('Error creating dynamic template: $e');
      rethrow;
    }
  }

  // Update an existing dynamic template
  static Future<void> updateDynamicTemplate(String templateId, Map<String, dynamic> templateData) async {
    try {
      if (!_validateTemplateData(templateData)) {
        throw Exception('Invalid template data');
      }

      await _firestore.collection('field_templates').doc(templateId).update({
        ...templateData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating dynamic template: $e');
      rethrow;
    }
  }

  // Delete a dynamic template
  static Future<void> deleteDynamicTemplate(String templateId) async {
    try {
      // Check if template is being used by any categories
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .where('fieldTemplate', isEqualTo: templateId)
          .limit(1)
          .get();
      
      if (categoriesSnapshot.docs.isNotEmpty) {
        throw Exception('Cannot delete template that is being used by categories. Please update those categories first.');
      }

      await _firestore.collection('field_templates').doc(templateId).delete();
    } catch (e) {
      print('Error deleting dynamic template: $e');
      rethrow;
    }
  }

  // Get template usage count
  static Future<int> getTemplateUsageCount(String templateId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('fieldTemplate', isEqualTo: templateId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting template usage count: $e');
      return 0;
    }
  }

  // Validate template data structure - FIXED VERSION
  static bool _validateTemplateData(Map<String, dynamic> templateData) {
    try {
      // Check required fields
      if (!templateData.containsKey('name') || 
          !templateData.containsKey('fields') ||
          templateData['name'] == null ||
          templateData['name'].toString().trim().isEmpty) {
        print('❌ Template validation failed: Missing or empty name or fields');
        return false;
      }

      // Validate fields array
      final fields = templateData['fields'];
      if (fields == null || fields is! List) {
        print('❌ Template validation failed: Fields is not a valid list');
        return false;
      }

      final fieldsList = fields as List;
      if (fieldsList.isEmpty) {
        print('❌ Template validation failed: Fields list is empty');
        return false;
      }

      // Validate each field configuration
      for (int i = 0; i < fieldsList.length; i++) {
        final field = fieldsList[i];
        if (field is! Map<String, dynamic>) {
          print('❌ Template validation failed: Field $i is not a valid map');
          return false;
        }
        
        if (!validateFieldConfig(field)) {
          print('❌ Template validation failed: Field $i failed validation: $field');
          return false;
        }
      }

      print('ℹ️ Template validation passed');
      return true;
    } catch (e) {
      print('❌ Template validation error: $e');
      return false;
    }
  }

  // Validate field configuration - FIXED VERSION
  static bool validateFieldConfig(Map<String, dynamic> fieldConfig) {
  try {
    // Check required properties - handle both old and new field structures
    final fieldName = fieldConfig['fieldName']?.toString().trim() ?? 
                     fieldConfig['name']?.toString().trim() ?? '';
    if (fieldName.isEmpty) {
      print('❌ Field validation failed: Missing or empty fieldName/name');
      return false;
    }

    final label = fieldConfig['label']?.toString().trim() ?? '';
    if (label.isEmpty) {
      print('❌ Field validation failed: Missing or empty label');
      return false;
    }

    final fieldType = fieldConfig['fieldType']?.toString().trim() ?? 
                     fieldConfig['type']?.toString().trim() ?? '';
    if (fieldType.isEmpty) {
      print('❌ Field validation failed: Missing or empty fieldType/type');
      return false;
    }

    // Validate field type
    final validFieldTypes = [
      'text', 'number', 'dropdown', 'checkbox', 'radio', 
      'textarea', 'date', 'time', 'datetime', 'file', 'image', 'color'
    ];
    
    if (!validFieldTypes.contains(fieldType)) {
      print('❌ Field validation failed: Invalid field type: $fieldType');
      return false;
    }

    // Validate dropdown/radio options - More flexible validation
    if (fieldType == 'dropdown' || fieldType == 'radio') {
      final options = fieldConfig['options'];
      if (options != null && options is List) {
        final optionsList = options as List;
        // Allow empty options list during editing - will be validated at form level
        if (optionsList.isNotEmpty) {
          // Validate that options are not null/empty
          for (final option in optionsList) {
            if (option == null || option.toString().trim().isEmpty) {
              print('❌ Field validation failed: Empty option found in $fieldType');
              return false;
            }
          }
        }
      }
    }

    // NEW: Validate icon configuration
    if (fieldConfig.containsKey('showFieldIcon')) {
      final showFieldIcon = fieldConfig['showFieldIcon'];
      if (showFieldIcon is! bool) {
        print('❌ Field validation failed: showFieldIcon must be boolean');
        return false;
      }
      
      // If showing field icon, validate icon URL format
      if (showFieldIcon == true && fieldConfig.containsKey('fieldIconUrl')) {
        final fieldIconUrl = fieldConfig['fieldIconUrl'];
        if (fieldIconUrl != null && fieldIconUrl is! String) {
          print('❌ Field validation failed: fieldIconUrl must be string or null');
          return false;
        }
        
        // Optional: Validate URL format
        if (fieldIconUrl != null && fieldIconUrl.toString().isNotEmpty) {
          final urlString = fieldIconUrl.toString();
          if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
            print('❌ Field validation failed: fieldIconUrl must be a valid URL');
            return false;
          }
        }
      }
    }

    // Validate validation rules if present
    if (fieldConfig.containsKey('validation') && fieldConfig['validation'] != null) {
      final validation = fieldConfig['validation'];
      if (validation is! Map) {
        print('❌ Field validation failed: Validation rules are not a valid map');
        return false;
      }
    }

    // Validate order if present
    if (fieldConfig.containsKey('order') && fieldConfig['order'] != null) {
      final order = fieldConfig['order'];
      if (order is! int && order is! num && order is! String) {
        print('❌ Field validation failed: Order is not a valid type');
        return false;
      }
    }

    return true;
  } catch (e) {
    print('❌ Field validation error: $e');
    return false;
  }
}

  // Create a new custom template
  static Map<String, dynamic> createCustomTemplate({
    required String name,
    required String description,
    required List<Map<String, dynamic>> fields,
    String? category,
    List<String>? inheritFrom,
  }) {
    // Validate all fields
    for (final field in fields) {
      if (!validateFieldConfig(field)) {
        throw ArgumentError('Invalid field configuration: ${field['fieldName'] ?? field['name']}');
      }
    }

    return {
      'name': name,
      'description': description,
      'category': category ?? 'custom',
      'fields': fields,
      'inheritFrom': inheritFrom ?? [],
      'createdAt': DateTime.now().toIso8601String(),
      'version': '1.0',
      'isActive': true,
    };
  }

  // Merge multiple templates
  static List<Map<String, dynamic>> mergeTemplates(List<Map<String, dynamic>> templates) {
    final mergedFields = <String, Map<String, dynamic>>{};
    
    for (final template in templates) {
      final fields = List<Map<String, dynamic>>.from(template['fields'] ?? []);
      for (final field in fields) {
        final fieldName = field['fieldName'] as String? ?? field['name'] as String? ?? '';
        if (fieldName.isNotEmpty) {
          mergedFields[fieldName] = field;
        }
      }
    }
    
    final result = mergedFields.values.toList();
    result.sort((a, b) {
      final orderA = a['order'] as int? ?? 999;
      final orderB = b['order'] as int? ?? 999;
      return orderA.compareTo(orderB);
    });
    
    return result;
  }
}