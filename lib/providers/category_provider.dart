// category_provider.dart
import 'package:delloniweb/providers/category_field_templates.dart';
import 'package:delloniweb/screens/create_categories_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'base_admin_provider.dart';
// category_provider.dart - FIXED VERSION
import 'package:delloniweb/providers/category_field_templates.dart';
import 'package:delloniweb/screens/create_categories_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'base_admin_provider.dart';

// category_provider.dart - DYNAMIC TEMPLATES ONLY VERSION
import 'package:delloniweb/providers/category_field_templates.dart';
import 'package:delloniweb/screens/create_categories_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'base_admin_provider.dart';

class CategoryProvider extends BaseAdminProvider {
  // Category data
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _allTemplates = [];

  // Caching system
  final Map<String, List<Map<String, dynamic>>> _categoryCache = {};
  static const Duration _cacheTimeout = Duration(minutes: 10);
  DateTime? _lastCacheUpdate;

  // Getters
  List<Map<String, dynamic>> get allCategories => _allCategories;
  List<Map<String, dynamic>> get allTemplates => _allTemplates;

  // CATEGORY MANAGEMENT

  Future<void> loadAllCategories() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      final categoriesSnapshot = await firestore
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .get();

      _allCategories = categoriesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort categories by order and creation date
      _allCategories.sort((a, b) {
        final orderA = a['order'] ?? 0;
        final orderB = b['order'] ?? 0;
        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        
        final dateA = a['createdAt'] as Timestamp?;
        final dateB = b['createdAt'] as Timestamp?;
        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA); // Newest first
        }
        return 0;
      });
      
      DebugHelper.logInfo('Loaded ${_allCategories.length} categories from Firestore');
      if (_allCategories.isNotEmpty) {
        DebugHelper.logInfo('First category: ${_allCategories.first}');
      }
      
      // Clear cache when categories are reloaded
      _categoryCache.clear();
      updateLastUpdated();
      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error loading categories: $e');
      setError('Failed to load categories: $e');
    }
    setLoading(false);
  }

  Future<void> loadMoreCategories() async {
    if (isLoading || _allCategories.isEmpty) return;
    
    try {
      final lastDoc = await firestore
          .collection('categories')
          .doc(_allCategories.last['id'])
          .get();

      final nextCategoriesSnapshot = await firestore
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDoc)
          .limit(20)
          .get();

      if (nextCategoriesSnapshot.docs.isNotEmpty) {
        final newCategories = nextCategoriesSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        _allCategories.addAll(newCategories);
        
        _categoryCache.clear();
        updateLastUpdated();
        notifyListeners();
      }
    } catch (e) {
      DebugHelper.logError('Error loading more categories: $e');
      setError('Failed to load more categories: $e');
    }
  }

  List<Map<String, dynamic>> getSubCategories(String parentId) {
    if (parentId.isEmpty || _allCategories.isEmpty) {
      return [];
    }

    // Check cache first
    if (_categoryCache.containsKey(parentId)) {
      return _categoryCache[parentId]!;
    }

    try {
      final subCategories = _allCategories.where((category) {
        final categoryParentId = category['parentId']?.toString();
        final categoryIsActive = category['isActive'];
        
        return categoryParentId == parentId && categoryIsActive == true;
      }).toList();
      
      subCategories.sort((a, b) {
        final orderA = (a['order'] as num?)?.toInt() ?? 0;
        final orderB = (b['order'] as num?)?.toInt() ?? 0;
        
        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        
        final nameA = a['name']?.toString() ?? '';
        final nameB = b['name']?.toString() ?? '';
        return nameA.compareTo(nameB);
      });
      
      // Cache the result
      _categoryCache[parentId] = subCategories;
      
      return subCategories;
    } catch (e) {
      DebugHelper.logError('Error in getSubCategories: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> getMainCategories() {
    DebugHelper.logInfo('getMainCategories called. Total categories: ${_allCategories.length}');
    if (_allCategories.isEmpty) {
      DebugHelper.logInfo('No categories available');
      return [];
    }

    // Check cache first
    const cacheKey = 'main_categories';
    if (_categoryCache.containsKey(cacheKey)) {
      return _categoryCache[cacheKey]!;
    }
    
    try {
      final mainCategories = _allCategories.where((category) {
        final parentId = category['parentId'];
        final level = category['level'];
        final isActive = category['isActive'];
        
        final isMainCategory = (level != null && level == 0) || 
                              (parentId == null || parentId.toString().isEmpty);
        
        return isMainCategory && isActive == true;
      }).toList();
      
      DebugHelper.logInfo('Found ${mainCategories.length} main categories');

      mainCategories.sort((a, b) {
        final orderA = (a['order'] as num?)?.toInt() ?? 0;
        final orderB = (b['order'] as num?)?.toInt() ?? 0;
        
        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        
        final dateA = a['createdAt'] as Timestamp?;
        final dateB = b['createdAt'] as Timestamp?;
        
        if (dateA != null && dateB != null) {
          return dateA.compareTo(dateB);
        }
        
        return 0;
      });
      
      // Cache the result
      _categoryCache[cacheKey] = mainCategories;
      
      return mainCategories;
    } catch (e) {
      DebugHelper.logError('Error in getMainCategories: $e');
      return [];
    }
  }

  Future<void> createCategory(Map<String, dynamic> categoryData) async {
    setLoading(true);
    try {
      final docRef = await firestore.collection('categories').add({
        ...categoryData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Fetch the document to get the real timestamps
      final doc = await docRef.get();
      final data = doc.data();
      data?['id'] = doc.id;

      _allCategories.insert(0, data ?? {});

      _categoryCache.clear();
      updateLastUpdated();
      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error creating category: $e');
      setError('Failed to create category: $e');
      rethrow;
    }
    setLoading(false);
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> categoryData) async {
    setLoading(true);
    try {
      await firestore.collection('categories').doc(categoryId).update({
        ...categoryData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Fetch the updated document to get the real timestamp
      final doc = await firestore.collection('categories').doc(categoryId).get();
      final data = doc.data();
      data?['id'] = categoryId;

      final categoryIndex = _allCategories.indexWhere((category) => category['id'] == categoryId);
      if (categoryIndex != -1) {
        _allCategories[categoryIndex] = data ?? {};
        _categoryCache.clear();
        updateLastUpdated();
        notifyListeners();
      }
    } catch (e) {
      DebugHelper.logError('Error updating category: $e');
      setError('Failed to update category: $e');
      rethrow;
    }
    setLoading(false);
  }

  Future<void> updateCategoryStatus(String categoryId, bool isActive) async {
    try {
      await firestore.collection('categories').doc(categoryId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final categoryIndex = _allCategories.indexWhere((category) => category['id'] == categoryId);
      if (categoryIndex != -1) {
        _allCategories[categoryIndex]['isActive'] = isActive;
        _categoryCache.clear();
        updateLastUpdated();
        notifyListeners();
      }
    } catch (e) {
      DebugHelper.logError('Error updating category status: $e');
      setError('Failed to update category status: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      final hasChildren = _allCategories.any((cat) => cat['parentId'] == categoryId);
      if (hasChildren) {
        throw Exception('Cannot delete category that has subcategories. Please delete subcategories first.');
      }

      final productsSnapshot = await firestore
          .collection('items')
          .where('category', isEqualTo: categoryId)
          .limit(1)
          .get();
      
      if (productsSnapshot.docs.isNotEmpty) {
        throw Exception('Cannot delete category that has products. Please move or delete products first.');
      }

      await firestore.collection('categories').doc(categoryId).delete();
      
      _allCategories.removeWhere((category) => category['id'] == categoryId);
      _categoryCache.clear();
      updateLastUpdated();
      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error deleting category: $e');
      setError('Failed to delete category: $e');
      rethrow;
    }
  }

  // UTILITY METHODS

  bool categoryExists(String categoryId) {
    if (categoryId.isEmpty || _allCategories.isEmpty) {
      return false;
    }
    return _allCategories.any((cat) => cat['id'] == categoryId);
  }

  Map<String, dynamic>? getCategoryDetails(String categoryId) {
    if (categoryId.isEmpty || _allCategories.isEmpty) {
      return null;
    }
    
    try {
      return _allCategories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      DebugHelper.logError('Error getting category details for $categoryId: $e');
      return null;
    }
  }

  bool hasSubCategories(String parentId) {
    return getSubCategories(parentId).isNotEmpty;
  }

  int getCategoryLevel(String categoryId) {
    final category = getCategoryDetails(categoryId);
    if (category == null) return -1;
    
    if (category['level'] != null) {
      return (category['level'] as num).toInt();
    }
    
    int level = 0;
    String? currentParentId = category['parentId']?.toString();
    
    while (currentParentId != null && currentParentId.isNotEmpty && level < 5) {
      level++;
      final parent = getCategoryDetails(currentParentId);
      if (parent == null) break;
      currentParentId = parent['parentId']?.toString();
    }
    
    return level;
  }

  Map<String, dynamic> getCategoryHierarchy(String categoryId) {
    final category = _allCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => <String, dynamic>{},
    );
    
    if (category.isEmpty) return {};
    
    return {
      'category': category,
      'parent': category['parentId'] != null 
          ? _allCategories.firstWhere(
              (cat) => cat['id'] == category['parentId'],
              orElse: () => <String, dynamic>{},
            )
          : null,
      'children': getSubCategories(categoryId),
    };
  }

  List<Map<String, dynamic>> searchCategories(String query) {
    if (query.isEmpty) return _allCategories;
    
    final lowercaseQuery = query.toLowerCase();
    return _allCategories.where((category) {
      final name = (category['name'] as String? ?? '').toLowerCase();
      final description = (category['description'] as String? ?? '').toLowerCase();
      
      return name.contains(lowercaseQuery) ||
             description.contains(lowercaseQuery);
    }).toList();
  }

  Map<String, dynamic> getCategoryStatistics() {
    final mainCategories = getMainCategories();
    int totalSubCategories = 0;

    for (final category in mainCategories) {
      final subCats = getSubCategories(category['id']);
      totalSubCategories += subCats.length;
    }

    return {
      'mainCategories': mainCategories.length,
      'totalSubCategories': totalSubCategories,
      'totalCategories': _allCategories.length,
      'activeCategories': _allCategories.where((cat) => cat['isActive'] == true).length,
    };
  }

  // FIELD TEMPLATES MANAGEMENT (Dynamic Templates Only) - FIXED VERSION

  Future<void> loadAllTemplates() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      // Load and normalize templates from Firebase
      _allTemplates = await CategoryFieldTemplates.loadAllTemplatesFromFirestore();
      
      DebugHelper.logInfo('Loaded ${_allTemplates.length} dynamic field templates');
      updateLastUpdated();
      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error loading field templates: $e');
      setError('Failed to load field templates: $e');
    }
    setLoading(false);
  }

  Future<void> createFieldTemplate(Map<String, dynamic> templateData) async {
    setLoading(true);
    try {
      // Clean and validate the template data
      final cleanedTemplateData = _cleanTemplateData(templateData);
      
      DebugHelper.logInfo('Creating temple with cleaned data: $cleanedTemplateData');
      
      // Validate the cleaned template data structure
      if (!_validateTemplateData(cleanedTemplateData)) {
        DebugHelper.logError('Template validation failed for: $cleanedTemplateData');
        throw Exception('Invalid template data structure');
      }

      final templateId = await CategoryFieldTemplates.createDynamicTemplate(cleanedTemplateData);

      // Add to local list with the generated ID
      final newTemplate = {
        ...cleanedTemplateData,
        'id': templateId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isActive': true,
      };
      
      _allTemplates.insert(0, newTemplate);
      
      updateLastUpdated();
      notifyListeners();
      
      DebugHelper.logInfo('Created field template: ${cleanedTemplateData['name']}');
    } catch (e) {
      DebugHelper.logError('Error creating field template: $e');
      setError('Failed to create field template: $e');
      rethrow;
    }
    setLoading(false);
  }

  Future<void> updateFieldTemplate(String templateId, Map<String, dynamic> templateData) async {
    setLoading(true);
    try {
      // Clean and validate the template data
      final cleanedTemplateData = _cleanTemplateData(templateData);
      
      DebugHelper.logInfo('Updating template $templateId with cleaned data: $cleanedTemplateData');
      
      if (!_validateTemplateData(cleanedTemplateData)) {
        DebugHelper.logError('Template validation failed for update: $cleanedTemplateData');
        throw Exception('Invalid template data structure');
      }

      await CategoryFieldTemplates.updateDynamicTemplate(templateId, cleanedTemplateData);

      final templateIndex = _allTemplates.indexWhere((template) => template['id'] == templateId);
      if (templateIndex != -1) {
        _allTemplates[templateIndex] = {
          ..._allTemplates[templateIndex],
          ...cleanedTemplateData,
          'id': templateId,
          'updatedAt': Timestamp.now(),
        };
        
        updateLastUpdated();
        notifyListeners();
      }
      
      DebugHelper.logInfo('Updated field template: $templateId');
    } catch (e) {
      DebugHelper.logError('Error updating field template: $e');
      setError('Failed to update field template: $e');
      rethrow;
    }
    setLoading(false);
  }

  Future<void> deleteFieldTemplate(String templateId) async {
    try {
      await CategoryFieldTemplates.deleteDynamicTemplate(templateId);
      
      _allTemplates.removeWhere((template) => template['id'] == templateId);
      updateLastUpdated();
      notifyListeners();
      
      DebugHelper.logInfo('Deleted field template: $templateId');
    } catch (e) {
      DebugHelper.logError('Error deleting field template: $e');
      setError('Failed to delete field template: $e');
      rethrow;
    }
  }

  // FIXED: Clean template data and handle legacy field structures
  Map<String, dynamic> _cleanTemplateData(Map<String, dynamic> templateData) {
    try {
      final cleaned = Map<String, dynamic>.from(templateData);
      
      // Clean the name field
      if (cleaned['name'] != null) {
        cleaned['name'] = cleaned['name'].toString().trim();
      }
      
      // Clean the description field
      if (cleaned['description'] != null) {
        cleaned['description'] = cleaned['description'].toString().trim();
      }
      
      // Clean the category field
      if (cleaned['category'] != null) {
        cleaned['category'] = cleaned['category'].toString().trim();
      }
      
      // Ensure inheritFrom is a list
      if (cleaned['inheritFrom'] == null) {
        cleaned['inheritFrom'] = <String>[];
      } else if (cleaned['inheritFrom'] is! List) {
        cleaned['inheritFrom'] = <String>[];
      }
      
      // Clean and validate fields array with legacy structure handling
      if (cleaned['fields'] != null && cleaned['fields'] is List) {
        final List<dynamic> fieldsList = cleaned['fields'];
        final List<Map<String, dynamic>> cleanedFields = [];
        
        for (final field in fieldsList) {
          if (field is Map<String, dynamic>) {
            final cleanedField = _cleanFieldData(field);
            if (cleanedField != null) {
              cleanedFields.add(cleanedField);
            }
          }
        }
        
        cleaned['fields'] = cleanedFields;
      } else {
        cleaned['fields'] = <Map<String, dynamic>>[];
      }
      
      return cleaned;
    } catch (e) {
      DebugHelper.logError('Error cleaning template data: $e');
      return templateData;
    }
  }

  // FIXED: Clean individual field data and handle legacy structures
 Map<String, dynamic>? _cleanFieldData(Map<String, dynamic> fieldData) {
  try {
    final cleaned = Map<String, dynamic>.from(fieldData);
    
    // Handle legacy field structures - normalize fieldName
    String fieldName = '';
    if (cleaned['fieldName'] != null && cleaned['fieldName'].toString().trim().isNotEmpty) {
      fieldName = cleaned['fieldName'].toString().trim();
    } else if (cleaned['name'] != null && cleaned['name'].toString().trim().isNotEmpty) {
      fieldName = cleaned['name'].toString().trim();
      // Remove old 'name' field and use 'fieldName'
      cleaned.remove('name');
    }
    
    if (fieldName.isEmpty) {
      DebugHelper.logError('❌ Field missing fieldName: $fieldData');
      return null;
    }
    cleaned['fieldName'] = fieldName;
    
    // Handle legacy field structures - normalize label
    String label = '';
    if (cleaned['label'] != null && cleaned['label'].toString().trim().isNotEmpty) {
      label = cleaned['label'].toString().trim();
    } else {
      // Use fieldName as fallback for label
      label = fieldName;
    }
    cleaned['label'] = label;
    
    // Handle legacy field structures - normalize fieldType
    String fieldType = 'text';
    if (cleaned['fieldType'] != null && cleaned['fieldType'].toString().trim().isNotEmpty) {
      fieldType = cleaned['fieldType'].toString().trim();
    } else if (cleaned['type'] != null && cleaned['type'].toString().trim().isNotEmpty) {
      fieldType = cleaned['type'].toString().trim();
      // Remove old 'type' field and use 'fieldType'
      cleaned.remove('type');
    }
    cleaned['fieldType'] = fieldType;
    
    // Handle legacy field structures - normalize isRequired
    bool isRequired = false;
    if (cleaned['isRequired'] != null) {
      isRequired = cleaned['isRequired'] == true;
    } else if (cleaned['required'] != null) {
      isRequired = cleaned['required'] == true;
      // Remove old 'required' field and use 'isRequired'
      cleaned.remove('required');
    }
    cleaned['isRequired'] = isRequired;
    
    // NEW: Handle icon configuration
    if (cleaned.containsKey('showFieldIcon')) {
      cleaned['showFieldIcon'] = cleaned['showFieldIcon'] == true;
    } else {
      cleaned['showFieldIcon'] = false;
    }
    
    if (cleaned.containsKey('fieldIconUrl') && cleaned['fieldIconUrl'] != null) {
      final iconUrl = cleaned['fieldIconUrl'].toString().trim();
      if (iconUrl.isNotEmpty) {
        cleaned['fieldIconUrl'] = iconUrl;
      } else {
        cleaned.remove('fieldIconUrl');
      }
    }
    
    // Ensure order is an integer
    if (cleaned['order'] != null) {
      if (cleaned['order'] is num) {
        cleaned['order'] = (cleaned['order'] as num).toInt();
      } else if (cleaned['order'] is String) {
        cleaned['order'] = int.tryParse(cleaned['order']) ?? 1;
      } else {
        cleaned['order'] = 1;
      }
    } else {
      cleaned['order'] = 1;
    }
    
    // Clean placeholder
    if (cleaned['placeholder'] != null) {
      final placeholder = cleaned['placeholder'].toString().trim();
      if (placeholder.isNotEmpty) {
        cleaned['placeholder'] = placeholder;
      } else {
        cleaned.remove('placeholder');
      }
    }
    
    // Clean options for dropdown/radio fields
    if (fieldType == 'dropdown' || fieldType == 'radio') {
      if (cleaned['options'] != null && cleaned['options'] is List) {
        final List<dynamic> optionsList = cleaned['options'];
        final List<String> cleanedOptions = [];
        
        for (final option in optionsList) {
          if (option != null && option.toString().trim().isNotEmpty) {
            cleanedOptions.add(option.toString().trim());
          }
        }
        
        cleaned['options'] = cleanedOptions;
      } else {
        // Set empty options list - will be caught by validation if required
        cleaned['options'] = <String>[];
      }
    }
    
    // Clean validation rules
    if (cleaned['validation'] != null && cleaned['validation'] is Map) {
      final validation = Map<String, dynamic>.from(cleaned['validation'] as Map);
      
      // Clean numeric validation values
      if (validation['min'] != null && validation['min'] is String) {
        validation['min'] = double.tryParse(validation['min']);
      }
      if (validation['max'] != null && validation['max'] is String) {
        validation['max'] = double.tryParse(validation['max']);
      }
      if (validation['minLength'] != null && validation['minLength'] is String) {
        validation['minLength'] = int.tryParse(validation['minLength']);
      }
      if (validation['maxLength'] != null && validation['maxLength'] is String) {
        validation['maxLength'] = int.tryParse(validation['maxLength']);
      }
      if (validation['maxSize'] != null && validation['maxSize'] is String) {
        validation['maxSize'] = int.tryParse(validation['maxSize']);
      }
      
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
      
      // Remove empty validation rules
      validation.removeWhere((key, value) => 
          value == null || 
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty));
      
      if (validation.isNotEmpty) {
        cleaned['validation'] = validation;
      } else {
        cleaned.remove('validation');
      }
    }
    
    // Remove legacy fields and any other unwanted fields
    cleaned.remove('id'); // Don't include field ID in template
    cleaned.remove('category'); // Don't include field category in template
    
    return cleaned;
  } catch (e) {
    DebugHelper.logError('❌ Error cleaning field data: $e');
    return null;
  }
}
  // FIXED: Validate template data structure
  bool _validateTemplateData(Map<String, dynamic> templateData) {
    try {
      DebugHelper.logInfo('ℹ️ Validating template data: $templateData');
      
      // Check required fields
      if (!templateData.containsKey('name') || 
          !templateData.containsKey('fields') ||
          templateData['name'] == null ||
          templateData['name'].toString().trim().isEmpty) {
        DebugHelper.logError('❌ Template validation failed: Missing or empty name or fields');
        return false;
      }

      // Validate fields array
      final fields = templateData['fields'];
      if (fields == null || fields is! List) {
        DebugHelper.logError('❌ Template validation failed: Fields is not a valid list');
        return false;
      }

      final fieldsList = fields as List;
      if (fieldsList.isEmpty) {
        DebugHelper.logError('❌ Template validation failed: Fields list is empty');
        return false;
      }

      // Validate each field configuration
      for (int i = 0; i < fieldsList.length; i++) {
        final field = fieldsList[i];
        if (field is! Map<String, dynamic>) {
          DebugHelper.logError('❌ Template validation failed: Field $i is not a valid map');
          return false;
        }
        
        if (!CategoryFieldTemplates.validateFieldConfig(field)) {
          DebugHelper.logError('❌ Template validation failed: Field $i failed validation: $field');
          return false;
        }
      }

      DebugHelper.logInfo('ℹ️ Template validation passed');
      return true;
    } catch (e) {
      DebugHelper.logError('❌ Template validation error: $e');
      return false;
    }
  }

  Future<int> getTemplateUsageCount(String templateId) async {
    try {
      return await CategoryFieldTemplates.getTemplateUsageCount(templateId);
    } catch (e) {
      DebugHelper.logError('Error getting template usage count: $e');
      return 0;
    }
  }

  // Clone an existing template
  Map<String, dynamic> cloneTemplate(String sourceTemplateId, String newName, String newDescription) {
    final sourceTemplate = getTemplateById(sourceTemplateId);
    if (sourceTemplate == null) {
      throw Exception('Source template not found');
    }

    return {
      'name': newName,
      'description': newDescription,
      'category': sourceTemplate['category'] ?? 'cloned',
      'fields': List<Map<String, dynamic>>.from(sourceTemplate['fields'] ?? []),
      'inheritFrom': List<String>.from(sourceTemplate['inheritFrom'] ?? []),
      'isActive': true,
    };
  }

  Map<String, dynamic>? getTemplateById(String templateId) {
    try {
      final template = _allTemplates.firstWhere(
        (template) => template['id'] == templateId,
        orElse: () => <String, dynamic>{},
      );
      return template.isEmpty ? null : template;
    } catch (e) {
      DebugHelper.logError('Error getting template by ID: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> getTemplatesByIds(List<String> templateIds) {
    return _allTemplates.where((template) => templateIds.contains(template['id'])).toList();
  }

  List<Map<String, dynamic>> searchTemplates(String query) {
    if (query.isEmpty) return _allTemplates;
    
    final lowercaseQuery = query.toLowerCase();
    return _allTemplates.where((template) {
      final name = (template['name'] as String? ?? '').toLowerCase();
      final description = (template['description'] as String? ?? '').toLowerCase();
      final category = (template['category'] as String? ?? '').toLowerCase();
      
      return name.contains(lowercaseQuery) ||
             description.contains(lowercaseQuery) ||
             category.contains(lowercaseQuery);
    }).toList();
  }

  // FIELD CONFIGURATION METHODS

  Future<void> createCategoryWithFields(Map<String, dynamic> categoryData) async {
    try {
      setLoading(true);
      
      final docRef = await firestore.collection('categories').add({
        ...categoryData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If this category has field configuration, also create a separate document
      if (categoryData['hasCustomFields'] == true) {
        await firestore
            .collection('category_field_configs')
            .doc(docRef.id)
            .set({
          'categoryId': docRef.id,
          'categoryName': categoryData['name'],
          'fieldTemplate': categoryData['fieldTemplate'],
          'inheritedTemplates': categoryData['inheritedTemplates'],
          'configuredFields': categoryData['configuredFields'],
          'level': categoryData['level'],
          'parentId': categoryData['parentId'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await loadAllCategories(); // Refresh categories
      setLoading(false);
      
    } catch (e) {
      setError('Failed to create category: $e');
      setLoading(false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCategoryFieldConfig(String categoryId) async {
    try {
      final doc = await firestore
          .collection('category_field_configs')
          .doc(categoryId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      
      // Fallback: get from main category document
      final categoryDoc = await firestore
          .collection('categories')
          .doc(categoryId)
          .get();
      
      if (categoryDoc.exists) {
        final data = categoryDoc.data()!;
        if (data['hasCustomFields'] == true) {
          return {
            'categoryId': categoryId,
            'categoryName': data['name'],
            'fieldTemplate': data['fieldTemplate'],
            'inheritedTemplates': data['inheritedTemplates'],
            'configuredFields': data['configuredFields'],
            'level': data['level'],
            'parentId': data['parentId'],
          };
        }
      }
      
      return null;
    } catch (e) {
      log('Error getting category field config: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllFieldsForCategory(String categoryId) async {
    try {
      final config = await getCategoryFieldConfig(categoryId);
      if (config == null) return [];
      
      final fieldTemplate = config['fieldTemplate'] as String?;
      final inheritedTemplates = List<String>.from(config['inheritedTemplates'] ?? []);
      
      if (fieldTemplate != null) {
        return CategoryFieldTemplates.getFieldsForCategory(
          fieldTemplate,
          parentTemplateIds: inheritedTemplates,
          allTemplates: _allTemplates,
        );
      }
      
      return [];
    } catch (e) {
      DebugHelper.logError('Error getting all fields for category: $e');
      return [];
    }
  }

  // CACHE MANAGEMENT

  void clearCache() {
    _categoryCache.clear();
    _lastCacheUpdate = null;
  }

  void clearAllData() {
    _allCategories.clear();
    _allTemplates.clear();
    clearCache();
    notifyListeners();
  }

  // Add these methods to your existing CategoryProvider class

// CATEGORY FIELD MANAGEMENT (NEW APPROACH)

/// Update category with configured fields
Future<void> updateCategoryWithFields(String categoryId, Map<String, dynamic> categoryData) async {
  setLoading(true);
  try {
    // Ensure the category has the necessary field configuration properties
    final updatedData = {
      ...categoryData,
      'hasCustomFields': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await firestore.collection('categories').doc(categoryId).update(updatedData);

    // Update local category data
    final categoryIndex = _allCategories.indexWhere((category) => category['id'] == categoryId);
    if (categoryIndex != -1) {
      _allCategories[categoryIndex] = {
        ..._allCategories[categoryIndex],
        ...updatedData,
        'id': categoryId,
      };
      
      _categoryCache.clear();
      updateLastUpdated();
      notifyListeners();
    }

    DebugHelper.logInfo('Updated category $categoryId with custom fields');
  } catch (e) {
    DebugHelper.logError('Error updating category with fields: $e');
    setError('Failed to update category fields: $e');
    rethrow;
  }
  setLoading(false);
}

/// Get configured fields for a specific category
List<Map<String, dynamic>> getCategoryConfiguredFields(String categoryId) {
  try {
    final category = getCategoryDetails(categoryId);
    if (category == null || category['configuredFields'] == null) {
      return [];
    }

    final configuredFields = List<Map<String, dynamic>>.from(
      category['configuredFields']
    );

    // Sort fields by ID or creation order
    configuredFields.sort((a, b) {
      final idA = a['id'] ?? 0;
      final idB = b['id'] ?? 0;
      return idA.compareTo(idB);
    });

    return configuredFields;
  } catch (e) {
    DebugHelper.logError('Error getting category configured fields: $e');
    return [];
  }
}

/// Add a single field to a category
Future<void> addFieldToCategory(String categoryId, Map<String, dynamic> fieldData) async {
  try {
    final category = getCategoryDetails(categoryId);
    if (category == null) {
      throw Exception('Category not found');
    }

    final existingFields = List<Map<String, dynamic>>.from(
      category['configuredFields'] ?? []
    );

    // Add unique ID if not present
    if (fieldData['id'] == null) {
      fieldData['id'] = DateTime.now().millisecondsSinceEpoch;
    }

    existingFields.add(fieldData);

    await updateCategoryWithFields(categoryId, {
      ...category,
      'configuredFields': existingFields,
    });

    DebugHelper.logInfo('Added field to category $categoryId');
  } catch (e) {
    DebugHelper.logError('Error adding field to category: $e');
    rethrow;
  }
}

/// Remove a field from a category
Future<void> removeFieldFromCategory(String categoryId, dynamic fieldId) async {
  try {
    final category = getCategoryDetails(categoryId);
    if (category == null) {
      throw Exception('Category not found');
    }

    final existingFields = List<Map<String, dynamic>>.from(
      category['configuredFields'] ?? []
    );

    existingFields.removeWhere((field) => field['id'] == fieldId);

    await updateCategoryWithFields(categoryId, {
      ...category,
      'configuredFields': existingFields,
    });

    DebugHelper.logInfo('Removed field $fieldId from category $categoryId');
  } catch (e) {
    DebugHelper.logError('Error removing field from category: $e');
    rethrow;
  }
}

/// Update a specific field in a category
Future<void> updateCategoryField(String categoryId, dynamic fieldId, Map<String, dynamic> updatedFieldData) async {
  try {
    final category = getCategoryDetails(categoryId);
    if (category == null) {
      throw Exception('Category not found');
    }

    final existingFields = List<Map<String, dynamic>>.from(
      category['configuredFields'] ?? []
    );

    final fieldIndex = existingFields.indexWhere((field) => field['id'] == fieldId);
    if (fieldIndex == -1) {
      throw Exception('Field not found in category');
    }

    existingFields[fieldIndex] = {
      ...existingFields[fieldIndex],
      ...updatedFieldData,
    };

    await updateCategoryWithFields(categoryId, {
      ...category,
      'configuredFields': existingFields,
    });

    DebugHelper.logInfo('Updated field $fieldId in category $categoryId');
  } catch (e) {
    DebugHelper.logError('Error updating category field: $e');
    rethrow;
  }
}

/// Get categories that have custom fields configured
List<Map<String, dynamic>> getCategoriesWithCustomFields() {
  return _allCategories.where((category) {
    return category['hasCustomFields'] == true && 
           category['configuredFields'] != null &&
           (category['configuredFields'] as List).isNotEmpty;
  }).toList();
}

/// Get field statistics for a category
Map<String, dynamic> getCategoryFieldStatistics(String categoryId) {
  try {
    final configuredFields = getCategoryConfiguredFields(categoryId);
    
    final fieldTypeCount = <String, int>{};
    int requiredFieldsCount = 0;
    int optionalFieldsCount = 0;

    for (final field in configuredFields) {
      final fieldType = field['type'] ?? 'unknown';
      fieldTypeCount[fieldType] = (fieldTypeCount[fieldType] ?? 0) + 1;
      
      if (field['required'] == true) {
        requiredFieldsCount++;
      } else {
        optionalFieldsCount++;
      }
    }

    return {
      'totalFields': configuredFields.length,
      'requiredFields': requiredFieldsCount,
      'optionalFields': optionalFieldsCount,
      'fieldTypeCount': fieldTypeCount,
      'hasCustomFields': configuredFields.isNotEmpty,
    };
  } catch (e) {
    DebugHelper.logError('Error getting category field statistics: $e');
    return {
      'totalFields': 0,
      'requiredFields': 0,
      'optionalFields': 0,
      'fieldTypeCount': <String, int>{},
      'hasCustomFields': false,
    };
  }
}

/// Copy fields from one category to another
Future<void> copyFieldsBetweenCategories(String sourceCategoryId, String targetCategoryId) async {
  try {
    final sourceCategory = getCategoryDetails(sourceCategoryId);
    final targetCategory = getCategoryDetails(targetCategoryId);
    
    if (sourceCategory == null || targetCategory == null) {
      throw Exception('Source or target category not found');
    }

    final sourceFields = List<Map<String, dynamic>>.from(
      sourceCategory['configuredFields'] ?? []
    );

    if (sourceFields.isEmpty) {
      throw Exception('Source category has no fields to copy');
    }

    // Create new field instances with unique IDs
    final copiedFields = sourceFields.map((field) {
      final copiedField = Map<String, dynamic>.from(field);
      copiedField['id'] = DateTime.now().millisecondsSinceEpoch + 
                         sourceFields.indexOf(field); // Ensure unique IDs
      return copiedField;
    }).toList();

    // Get existing fields from target category
    final existingTargetFields = List<Map<String, dynamic>>.from(
      targetCategory['configuredFields'] ?? []
    );

    // Combine existing and copied fields
    final allFields = [...existingTargetFields, ...copiedFields];

    await updateCategoryWithFields(targetCategoryId, {
      ...targetCategory,
      'configuredFields': allFields,
    });

    DebugHelper.logInfo('Copied ${sourceFields.length} fields from $sourceCategoryId to $targetCategoryId');
  } catch (e) {
    DebugHelper.logError('Error copying fields between categories: $e');
    rethrow;
  }
}

/// Validate category field configuration
bool validateCategoryField(Map<String, dynamic> fieldData) {
  try {
    // Check required properties
    if (fieldData['name'] == null || fieldData['name'].toString().trim().isEmpty) {
      DebugHelper.logError('Field validation failed: Missing field name');
      return false;
    }

    if (fieldData['label'] == null || fieldData['label'].toString().trim().isEmpty) {
      DebugHelper.logError('Field validation failed: Missing field label');
      return false;
    }

    if (fieldData['type'] == null || fieldData['type'].toString().trim().isEmpty) {
      DebugHelper.logError('Field validation failed: Missing field type');
      return false;
    }

    // Validate field type
    final validFieldTypes = [
      'text', 'number', 'dropdown', 'boolean', 'radio', 
      'textarea', 'date', 'time', 'datetime', 'file', 'image', 
      'color', 'color_picker'
    ];
    
    final fieldType = fieldData['type'].toString();
    if (!validFieldTypes.contains(fieldType)) {
      DebugHelper.logError('Field validation failed: Invalid field type: $fieldType');
      return false;
    }

    // Validate dropdown/radio options
    if (fieldType == 'dropdown' || fieldType == 'radio') {
      final options = fieldData['options'];
      if (options != null && options is List) {
        final optionsList = options as List;
        if (optionsList.isNotEmpty) {
          for (final option in optionsList) {
            if (option == null || option.toString().trim().isEmpty) {
              DebugHelper.logError('Field validation failed: Empty option found in $fieldType');
              return false;
            }
          }
        }
      }
    }

    // Validate required field
    if (fieldData['required'] != null && fieldData['required'] is! bool) {
      DebugHelper.logError('Field validation failed: Required must be boolean');
      return false;
    }

    // Validate category
    if (fieldData['category'] != null && fieldData['category'].toString().trim().isEmpty) {
      DebugHelper.logError('Field validation failed: Category cannot be empty string');
      return false;
    }

    return true;
  } catch (e) {
    DebugHelper.logError('Field validation error: $e');
    return false;
  }
}

/// Get all unique field categories used across all categories
Set<String> getAllFieldCategories() {
  final categories = <String>{};
  
  for (final category in _allCategories) {
    if (category['configuredFields'] != null) {
      final fields = List<Map<String, dynamic>>.from(category['configuredFields']);
      for (final field in fields) {
        final fieldCategory = field['category']?.toString();
        if (fieldCategory != null && fieldCategory.isNotEmpty) {
          categories.add(fieldCategory);
        }
      }
    }
  }
  
  return categories;
}

/// Search categories by field configuration
List<Map<String, dynamic>> searchCategoriesByField(String fieldName) {
  if (fieldName.isEmpty) return [];
  
  final lowercaseFieldName = fieldName.toLowerCase();
  return _allCategories.where((category) {
    if (category['configuredFields'] == null) return false;
    
    final fields = List<Map<String, dynamic>>.from(category['configuredFields']);
    return fields.any((field) {
      final name = (field['name'] as String? ?? '').toLowerCase();
      final label = (field['label'] as String? ?? '').toLowerCase();
      
      return name.contains(lowercaseFieldName) ||
             label.contains(lowercaseFieldName);
    });
  }).toList();
}

/// Export category field configuration
Map<String, dynamic> exportCategoryFieldConfig(String categoryId) {
  try {
    final category = getCategoryDetails(categoryId);
    if (category == null) {
      throw Exception('Category not found');
    }

    return {
      'categoryId': categoryId,
      'categoryName': category['name'],
      'levelType': category['levelType'],
      'hasCustomFields': category['hasCustomFields'] ?? false,
      'configuredFields': category['configuredFields'] ?? [],
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  } catch (e) {
    DebugHelper.logError('Error exporting category field config: $e');
    rethrow;
  }
}

/// Import category field configuration
Future<void> importCategoryFieldConfig(String categoryId, Map<String, dynamic> configData) async {
  try {
    if (!configData.containsKey('configuredFields')) {
      throw Exception('Invalid config data: missing configuredFields');
    }

    final category = getCategoryDetails(categoryId);
    if (category == null) {
      throw Exception('Target category not found');
    }

    final importedFields = List<Map<String, dynamic>>.from(
      configData['configuredFields']
    );

    // Validate each field before importing
    for (final field in importedFields) {
      if (!validateCategoryField(field)) {
        throw Exception('Invalid field configuration in import data');
      }
      
      // Assign new IDs to avoid conflicts
      field['id'] = DateTime.now().millisecondsSinceEpoch + 
                   importedFields.indexOf(field);
    }

    await updateCategoryWithFields(categoryId, {
      ...category,
      'configuredFields': importedFields,
      'hasCustomFields': true,
    });

    DebugHelper.logInfo('Imported ${importedFields.length} fields to category $categoryId');
  } catch (e) {
    DebugHelper.logError('Error importing category field config: $e');
    rethrow;
  }
}

/// Get category field usage statistics across all categories
Map<String, dynamic> getGlobalFieldUsageStatistics() {
  try {
    final totalCategories = _allCategories.length;
    final categoriesWithFields = getCategoriesWithCustomFields().length;
    final allFieldTypes = <String, int>{};
    final allFieldCategories = <String, int>{};
    int totalFields = 0;
    int totalRequiredFields = 0;

    for (final category in _allCategories) {
      if (category['configuredFields'] != null) {
        final fields = List<Map<String, dynamic>>.from(category['configuredFields']);
        totalFields += fields.length;

        for (final field in fields) {
          // Count field types
          final fieldType = field['type']?.toString() ?? 'unknown';
          allFieldTypes[fieldType] = (allFieldTypes[fieldType] ?? 0) + 1;

          // Count field categories
          final fieldCategory = field['category']?.toString() ?? 'uncategorized';
          allFieldCategories[fieldCategory] = (allFieldCategories[fieldCategory] ?? 0) + 1;

          // Count required fields
          if (field['required'] == true) {
            totalRequiredFields++;
          }
        }
      }
    }

    return {
      'totalCategories': totalCategories,
      'categoriesWithFields': categoriesWithFields,
      'categoriesWithoutFields': totalCategories - categoriesWithFields,
      'totalFields': totalFields,
      'totalRequiredFields': totalRequiredFields,
      'totalOptionalFields': totalFields - totalRequiredFields,
      'fieldTypeDistribution': allFieldTypes,
      'fieldCategoryDistribution': allFieldCategories,
      'averageFieldsPerCategory': categoriesWithFields > 0 
          ? (totalFields / categoriesWithFields).toStringAsFixed(1)
          : '0',
    };
  } catch (e) {
    DebugHelper.logError('Error getting global field usage statistics: $e');
    return {};
  }
}
}
