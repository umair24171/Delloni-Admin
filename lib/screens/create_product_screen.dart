import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/controllers/debug_helper.dart';
import 'package:delloniweb/providers/category_field_templates.dart';
import 'package:delloniweb/providers/category_provider.dart' hide DebugHelper;
import 'package:delloniweb/providers/product_provider.dart';
import 'package:delloniweb/providers/user_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/dashboard_overview.dart';
import 'package:delloniweb/screens/widgets/custom_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({Key? key}) : super(key: key);

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _colorController = TextEditingController();

  // Add these loading state variables
  bool _isLoadingSubCategories = false;
  bool _isLoadingSubSubCategories = false;
  bool _isLoadingCategoryFields = false;
  bool _isLoadingCities = false;
  bool _isLoadingDistricts = false;
  
  // Form data
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  String? _selectedCondition;
  String? _selectedShippingOption;
  bool _allowPriceNegotiation = true;
  bool _isFeatured = false;
  bool _isPromoted = false;
  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;

  Timer? _subCategoryLoadTimer;
  Timer? _subSubCategoryLoadTimer;
  
  // Category data
  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  List<Map<String, dynamic>> _subSubCategories = [];
  bool _categoriesLoading = true;

  // Dynamic category fields (NEW APPROACH - from category's configuredFields)
  List<Map<String, dynamic>> _categorySpecificFields = [];
  Map<String, dynamic> _categoryFieldValues = {};

  // Location data from Firestore
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _filteredDistricts = [];
  String? _selectedCityId;
  String? _selectedDistrictId;

  // Enhanced Conditions with descriptions
  final List<Map<String, dynamic>> _conditions = [
    {
      'value': 'Brand New',
      'label': 'Brand New',
      'description': 'Never used, in original packaging',
      'color': Colors.green,
      'icon': Icons.new_releases,
    },
    {
      'value': 'Like New',
      'label': 'Like New', 
      'description': 'Barely used, excellent condition',
      'color': Colors.lightGreen,
      'icon': Icons.star,
    },
    {
      'value': 'Good',
      'label': 'Good Condition',
      'description': 'Used but well maintained',
      'color': Colors.orange,
      'icon': Icons.thumb_up,
    },
    {
      'value': 'Fair',
      'label': 'Fair Condition',
      'description': 'Shows wear but functional',
      'color': Colors.deepOrange,
      'icon': Icons.warning,
    },
    {
      'value': 'Poor',
      'label': 'Poor/Bad Condition',
      'description': 'Significant wear, may need repair',
      'color': Colors.red,
      'icon': Icons.error,
    },
    {
      'value': 'Used',
      'label': 'Used',
      'description': 'Previously owned, general condition',
      'color': Colors.grey,
      'icon': Icons.history,
    },
  ];

  // Shipping Options
  final List<String> _shippingOptions = [
    'Pickup Only',
    'Delivery Only',
    'Both',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _loadLocationData();
    
    });
  }

  @override
  void dispose() {
    _subCategoryLoadTimer?.cancel();
    _subSubCategoryLoadTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _dimensionsController.dispose();
    _colorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // LOCATION DATA LOADING
  Future<void> _loadLocationData() async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      // Load cities
      final citiesSnapshot = await FirebaseFirestore.instance
          .collection('cities')
          .orderBy('name')
          .get();

      _cities = citiesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load districts
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .orderBy('name')
          .get();

      _districts = districtsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      DebugHelper.logInfo('Loaded ${_cities.length} cities and ${_districts.length} districts');
    } catch (e) {
      DebugHelper.logError('Error loading location data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading location data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() {
      _isLoadingCities = false;
    });
  }

  // Load category-specific fields with inheritance from parent categories
  Future<void> _loadCategoryFields(String categoryId) async {
    if (categoryId.isEmpty) {
      setState(() {
        _categorySpecificFields = [];
        _categoryFieldValues = {};
      });
      return;
    }

    setState(() {
      _isLoadingCategoryFields = true;
    });

    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final allFields = <Map<String, dynamic>>[];
      final fieldSources = <String, String>{}; // Track which category each field comes from
      
      // Build category hierarchy for inheritance
      final categoryHierarchy = _buildCategoryHierarchy();
      
      DebugHelper.logInfo('Category hierarchy: ${categoryHierarchy.map((c) => c['name']).join(' → ')}');
      
      // Load fields from each level in hierarchy (parent to child)
      for (final category in categoryHierarchy) {
        final categoryDetails = categoryProvider.getCategoryDetails(category['id']);
        
        if (categoryDetails != null && categoryDetails['configuredFields'] != null) {
          final configuredFields = List<Map<String, dynamic>>.from(
            categoryDetails['configuredFields']
          );
          
          for (final field in configuredFields) {
            final fieldName = field['name'] ?? field['fieldName'];
            if (fieldName != null && fieldName.isNotEmpty) {
              // Check if field already exists (child categories override parent fields)
              final existingFieldIndex = allFields.indexWhere(
                (existingField) => (existingField['name'] ?? existingField['fieldName']) == fieldName
              );
              
              if (existingFieldIndex != -1) {
                // Override parent field with child field
                allFields[existingFieldIndex] = {
                  ...field,
                  'sourceCategory': category['name'],
                  'sourceCategoryId': category['id'],
                  'isInherited': category['id'] != categoryId,
                };
                fieldSources[fieldName] = category['name'];
                DebugHelper.logInfo('Overriding field "$fieldName" from ${fieldSources[fieldName]} with ${category['name']}');
              } else {
                // Add new field
                allFields.add({
                  ...field,
                  'sourceCategory': category['name'],
                  'sourceCategoryId': category['id'],
                  'isInherited': category['id'] != categoryId,
                });
                fieldSources[fieldName] = category['name'];
                DebugHelper.logInfo('Adding field "$fieldName" from ${category['name']}');
              }
            }
          }
        }
      }
      
      // Sort fields: inherited fields first, then current category fields
      allFields.sort((a, b) {
        final aInherited = a['isInherited'] ?? false;
        final bInherited = b['isInherited'] ?? false;
        
        if (aInherited && !bInherited) return -1;
        if (!aInherited && bInherited) return 1;
        
        // Within same inheritance level, sort by name
        final aName = a['label'] ?? a['name'] ?? '';
        final bName = b['label'] ?? b['name'] ?? '';
        return aName.compareTo(bName);
      });
      
      setState(() {
        _categorySpecificFields = allFields;
        
        // Initialize field values (preserve existing values)
        final newFieldValues = <String, dynamic>{};
        for (final field in _categorySpecificFields) {
          final fieldName = field['name'] ?? field['fieldName'];
          if (fieldName != null) {
            // Preserve existing value or set to null
            newFieldValues[fieldName] = _categoryFieldValues[fieldName];
          }
        }
        _categoryFieldValues = newFieldValues;
      });
      
      final inheritedCount = allFields.where((f) => f['isInherited'] == true).length;
      final currentCount = allFields.length - inheritedCount;
      
      DebugHelper.logInfo('Loaded ${allFields.length} total fields: $inheritedCount inherited + $currentCount from current category');
      
    } catch (e) {
      DebugHelper.logError('Error loading category fields: $e');
      setState(() {
        _categorySpecificFields = [];
        _categoryFieldValues = {};
      });
    }

    setState(() {
      _isLoadingCategoryFields = false;
    });
  }

  // Build category hierarchy from main category to currently selected category
  List<Map<String, dynamic>> _buildCategoryHierarchy() {
    final hierarchy = <Map<String, dynamic>>[];
    
    // Add main category
    if (_selectedCategoryId != null) {
      final mainCategory = _mainCategories.firstWhere(
        (cat) => cat['id'] == _selectedCategoryId,
        orElse: () => <String, dynamic>{},
      );
      if (mainCategory.isNotEmpty) {
        hierarchy.add(mainCategory);
      }
    }
    
    // Add subcategory
    if (_selectedSubCategoryId != null) {
      final subCategory = _subCategories.firstWhere(
        (cat) => cat['id'] == _selectedSubCategoryId,
        orElse: () => <String, dynamic>{},
      );
      if (subCategory.isNotEmpty) {
        hierarchy.add(subCategory);
      }
    }
    
    // Add sub-subcategory
    if (_selectedSubSubCategoryId != null) {
      final subSubCategory = _subSubCategories.firstWhere(
        (cat) => cat['id'] == _selectedSubSubCategoryId,
        orElse: () => <String, dynamic>{},
      );
      if (subSubCategory.isNotEmpty) {
        hierarchy.add(subSubCategory);
      }
    }
    
    return hierarchy;
  }

  // Update subcategory loading methods to also load fields
  void _loadSubCategoriesAsync(String parentId) {
    _subCategoryLoadTimer?.cancel();
    
    if (parentId.isEmpty) {
      setState(() {
        _subCategories = [];
        _isLoadingSubCategories = false;
      });
      return;
    }
    
    setState(() {
      _isLoadingSubCategories = true;
      _subCategories = [];
    });
    
    _subCategoryLoadTimer = Timer(const Duration(milliseconds: 300), () {
      _performSubCategoryLoad(parentId);
    });
  }
  
  Future<void> _performSubCategoryLoad(String parentId) async {
    if (!mounted) return;
    
    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final completer = Completer<List<Map<String, dynamic>>>();
      
      Future.microtask(() {
        try {
          final result = categoryProvider.getSubCategories(parentId);
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });
      
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.completeError('Timeout loading subcategories');
        }
      });
      
      final subCats = await completer.future;
      
      if (mounted && _selectedCategoryId == parentId) {
        setState(() {
          _subCategories = subCats;
          _isLoadingSubCategories = false;
        });
        
        // Load fields for the current main category (inheritance will handle parent fields)
        _loadCategoryFields(parentId);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _subCategories = [];
          _isLoadingSubCategories = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subcategories: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _loadSubSubCategoriesAsync(String parentId) {
    _subSubCategoryLoadTimer?.cancel();
    
    if (parentId.isEmpty) {
      setState(() {
        _subSubCategories = [];
        _isLoadingSubSubCategories = false;
      });
      return;
    }
    
    setState(() {
      _isLoadingSubSubCategories = true;
      _subSubCategories = [];
    });
    
    _subSubCategoryLoadTimer = Timer(const Duration(milliseconds: 300), () {
      _performSubSubCategoryLoad(parentId);
    });
  }
  
  Future<void> _performSubSubCategoryLoad(String parentId) async {
    if (!mounted) return;
    
    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final completer = Completer<List<Map<String, dynamic>>>();
      
      Future.microtask(() {
        try {
          final result = categoryProvider.getSubCategories(parentId);
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });
      
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.completeError('Timeout loading sub-subcategories');
        }
      });
      
      final subSubCats = await completer.future;
      
      if (mounted && _selectedSubCategoryId == parentId) {
        setState(() {
          _subSubCategories = subSubCats;
          _isLoadingSubSubCategories = false;
        });
        
        // Load fields for the current subcategory (will inherit from main category)
        _loadCategoryFields(parentId);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _subSubCategories = [];
          _isLoadingSubSubCategories = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sub-subcategories: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Enhanced category loading
  Future<void> _loadCategories() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _categoriesLoading = true;
        _mainCategories = [];
      });
      
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final completer = Completer<void>();
      
      Future.microtask(() async {
        try {
          await categoryProvider.loadAllCategories();
          if (!completer.isCompleted) {
            completer.complete();
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });
      
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.completeError('Timeout loading categories');
        }
      });
      
      await completer.future;
      
      if (!mounted) return;
      
      final loadedCategories = categoryProvider.getMainCategories();
      
      setState(() {
        _mainCategories = loadedCategories;
        _categoriesLoading = false;
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesLoading = false;
          _mainCategories = [];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadCategories,
            ),
          ),
        );
      }
    }
  }

  // Get the final selected category for saving
  String? get _finalSelectedCategory {
    if (_selectedSubSubCategoryId != null) {
      return _selectedSubSubCategoryId;
    } else if (_selectedSubCategoryId != null) {
      return _selectedSubCategoryId;
    } else if (_selectedCategoryId != null) {
      return _selectedCategoryId;
    }
    return null;
  }

  // Get category display name for validation
  String? get _categoryDisplayName {
    if (_selectedSubSubCategoryId != null) {
      try {
        final category = _subSubCategories.firstWhere(
          (cat) => cat['id'] == _selectedSubSubCategoryId,
          orElse: () => <String, dynamic>{},
        );
        return category['name']?.toString();
      } catch (e) {
        print('Error getting sub-subcategory name: $e');
      }
    } else if (_selectedSubCategoryId != null) {
      try {
        final category = _subCategories.firstWhere(
          (cat) => cat['id'] == _selectedSubCategoryId,
          orElse: () => <String, dynamic>{},
        );
        return category['name']?.toString();
      } catch (e) {
        print('Error getting subcategory name: $e');
      }
    } else if (_selectedCategoryId != null) {
      try {
        final category = _mainCategories.firstWhere(
          (cat) => cat['id'] == _selectedCategoryId,
          orElse: () => <String, dynamic>{},
        );
        return category['name']?.toString();
      } catch (e) {
        print('Error getting main category name: $e');
      }
    }
    return null;
  }

  // Filter districts based on selected city
  void _filterDistrictsByCity(String cityId) {
    setState(() {
      _isLoadingDistricts = true;
      _selectedDistrictId = null;
    });

    try {
      final selectedCity = _cities.firstWhere(
        (city) => city['id'] == cityId,
        orElse: () => <String, dynamic>{},
      );

      if (selectedCity.isNotEmpty) {
        final cityName = selectedCity['name']?.toString() ?? '';
        
        _filteredDistricts = _districts.where((district) {
          final districtCity = district['cityName']?.toString() ?? '';
          final districtCityId = district['cityId']?.toString() ?? '';
          
          return districtCity.toLowerCase() == cityName.toLowerCase() ||
                 districtCityId == cityId;
        }).toList();
        
        // Sort districts by name
        _filteredDistricts.sort((a, b) {
          final nameA = a['name']?.toString() ?? '';
          final nameB = b['name']?.toString() ?? '';
          return nameA.compareTo(nameB);
        });
      } else {
        _filteredDistricts = [];
      }
    } catch (e) {
      DebugHelper.logError('Error filtering districts: $e');
      _filteredDistricts = [];
    }

    setState(() {
      _isLoadingDistricts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Main Form
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.add_box_outlined,
                        size: 28,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Create New Product',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      _buildActionButtons(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Category fields indicator with inheritance info
                  if (_categorySpecificFields.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.dynamic_form,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _buildFieldSummaryText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Form
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Scrollbar(
                            controller: _scrollController,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildBasicInfoSection(),
                                  const SizedBox(height: 32),
                                  _buildDetailsSection(),
                                  const SizedBox(height: 32),
                                  // Dynamic category-specific fields
                                  if (_categorySpecificFields.isNotEmpty) ...[
                                    _buildCategorySpecificFieldsSection(),
                                    const SizedBox(height: 32),
                                  ],
                                  _buildPricingSection(),
                                  const SizedBox(height: 32),
                                  _buildLocationSection(),
                                  const SizedBox(height: 32),
                                  _buildPromotionSection(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Image Upload Panel
          Container(
            width: 400,
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                left: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: _buildImageUploadPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _clearForm,
          icon: const Icon(Icons.clear_outlined, size: 18),
          label: const Text('Clear'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textMedium,
          ),
        ),
        const SizedBox(width: 12),
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return ElevatedButton.icon(
              onPressed: provider.isLoading ? null : _publishProduct,
              icon: provider.isLoading 
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_outlined, size: 18),
              label: Text(provider.isLoading ? 'Publishing...' : 'Publish'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        // Title
        CustomTextField(
          controller: _titleController,
          label: 'Product Title',
          hint: 'Enter a descriptive title for your product',
          required: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Product title is required';
            }
            if (value.length < 10) {
              return 'Title must be at least 10 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Dynamic Category Selection
        _buildCategorySection(),
        
        const SizedBox(height: 16),
        
        // Enhanced Condition Selection
        _buildConditionSection(),
        
        const SizedBox(height: 16),
        
        // Description
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Provide detailed description of your product...',
            prefixIcon: Icon(Icons.description_outlined),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Description is required';
            }
            if (value.trim().split(' ').length < 10) {
              return 'Description must contain at least 10 words';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Condition *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _conditions.map((condition) {
              final isSelected = _selectedCondition == condition['value'];
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? condition['color'].withOpacity(0.1) : null,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                ),
                child: RadioListTile<String>(
                  value: condition['value'],
                  groupValue: _selectedCondition,
                  onChanged: (value) {
                    setState(() {
                      _selectedCondition = value;
                    });
                  },
                  title: Row(
                    children: [
                      Icon(
                        condition['icon'],
                        color: condition['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        condition['label'],
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? condition['color'] : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    condition['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? condition['color'] : AppColors.textMedium,
                    ),
                  ),
                  activeColor: condition['color'],
                ),
              );
            }).toList(),
          ),
        ),
        if (_selectedCondition == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select the condition of your item',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySpecificFieldsSection() {
    if (_isLoadingCategoryFields) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 12),
              Text('Loading category fields...'),
            ],
          ),
        ),
      );
    }

    // Group fields by source for better organization
    final inheritedFields = _categorySpecificFields.where((f) => f['isInherited'] == true).toList();
    final currentFields = _categorySpecificFields.where((f) => f['isInherited'] != true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.dynamic_form,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Category-Specific Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Field summary
        Row(
          children: [
            Text(
              'Total: ${_categorySpecificFields.length} fields',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
            if (inheritedFields.isNotEmpty) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${inheritedFields.length} inherited',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (currentFields.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${currentFields.length} specific',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        
        // Inherited fields section
        if (inheritedFields.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Inherited Fields',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'These fields are inherited from parent categories',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...inheritedFields.map((field) => Column(
            children: [
              _buildDynamicField(field),
              const SizedBox(height: 16),
            ],
          )),
          
          const SizedBox(height: 8),
        ],
        
        // Current category fields section
        if (currentFields.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${_categoryDisplayName ?? 'Category'} Specific Fields',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...currentFields.map((field) => Column(
            children: [
              _buildDynamicField(field),
              const SizedBox(height: 16),
            ],
          )),
        ],
        
        // Help text if no fields
        if (_categorySpecificFields.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.textMedium,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No custom fields configured',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This category and its parent categories don\'t have custom fields configured',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDynamicField(Map<String, dynamic> field) {
    final fieldName = field['name'] ?? field['fieldName'];
    final fieldType = field['type'] ?? field['fieldType']; // category format uses 'type'
    final isRequired = field['required'] == true || field['isRequired'] == true;
    final isInherited = field['isInherited'] == true;
    final sourceCategory = field['sourceCategory'];
    
    Widget fieldWidget;
    
    switch (fieldType) {
      case 'dropdown':
        fieldWidget = _buildDropdownField(field);
        break;
      case 'number':
        fieldWidget = _buildNumberField(field);
        break;
      case 'boolean':
        fieldWidget = _buildBooleanField(field);
        break;
      case 'color_picker':
        fieldWidget = _buildColorField(field);
        break;
      case 'date':
        fieldWidget = _buildDateField(field);
        break;
      case 'textarea':
        fieldWidget = _buildTextAreaField(field);
        break;
      case 'text':
      default:
        fieldWidget = _buildTextField(field);
        break;
    }
    
    // Wrap field with inheritance indicator
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field source indicator
        if (isInherited && sourceCategory != null) ...[
          Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 14,
                color: AppColors.info,
              ),
              const SizedBox(width: 4),
              Text(
                'From: $sourceCategory',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'INHERITED',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        
        // The actual field widget
        Container(
          decoration: isInherited 
              ? BoxDecoration(
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.info.withOpacity(0.02),
                )
              : null,
          child: Padding(
            padding: isInherited 
                ? const EdgeInsets.all(8)
                : EdgeInsets.zero,
            child: fieldWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(Map<String, dynamic> field) {
    final fieldName = field['name'] ?? field['fieldName'];
    final options = List<String>.from(field['options'] ?? []);
    final isRequired = field['required'] == true || field['isRequired'] == true;
    
    return DropdownButtonFormField<String>(
      value: _categoryFieldValues[fieldName],
      decoration: InputDecoration(
        labelText: '${field['label']}${isRequired ? ' *' : ''}',
        hintText: field['placeholder'] ?? field['hint'],
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _categoryFieldValues[fieldName] = value;
        });
      },
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return '${field['label']} is required';
        }
        return null;
      } : null,
    );
  }

  Widget _buildNumberField(Map<String, dynamic> field) {
    final fieldName = field['name'] ?? field['fieldName'];
    final isRequired = field['required'] == true || field['isRequired'] == true;
    final validation = field['validation'] as Map<String, dynamic>?;
    
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '${field['label']}${isRequired ? ' *' : ''}',
        hintText: field['placeholder'] ?? field['hint'],
        suffixText: field['suffix'],
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        final numValue = double.tryParse(value);
        setState(() {
          _categoryFieldValues[fieldName] = numValue;
        });
      },
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '${field['label']} is required';
        }
        
        if (value != null && value.isNotEmpty) {
          final numValue = double.tryParse(value);
          if (numValue == null) {
            return 'Please enter a valid number';
          }
          
          if (validation != null) {
            final min = validation['min'];
            final max = validation['max'];
            
            if (min != null && numValue < min) {
              return 'Value must be at least $min';
            }
            if (max != null && numValue > max) {
              return 'Value must be at most $max';
            }
          }
        }
        
        return null;
      },
    );
  }

  Widget _buildTextField(Map<String, dynamic> field) {
    final fieldName = field['name'] ?? field['fieldName'];
    final isRequired = field['required'] == true || field['isRequired'] == true;
    
    return TextFormField(
      decoration: InputDecoration(
        labelText: '${field['label']}${isRequired ? ' *' : ''}',
        hintText: field['placeholder'] ?? field['hint'],
        suffixText: field['suffix'],
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _categoryFieldValues[fieldName] = value;
        });
      },
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return '${field['label']} is required';
        }
        return null;
      } : null,
    );
  }

  Widget _buildTextAreaField(Map<String, dynamic> field) {
    final fieldName = field['name'] ?? field['fieldName'];
    final isRequired = field['required'] == true || field['isRequired'] == true;
    
    return TextFormField(
      maxLines: 3,
      decoration: InputDecoration(
        labelText: '${field['label']}${isRequired ? ' *' : ''}',
        hintText: field['placeholder'] ?? field['hint'],
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      onChanged: (value) {
        setState(() {
          _categoryFieldValues[fieldName] = value;
        });
      },
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return '${field['label']} is required';
        }
        return null;
      } : null,
    );
  }

  Widget _buildBooleanField(Map<String, dynamic> field) {
    final fieldName = field['name'] ?? field['fieldName'];
    final value = _categoryFieldValues[fieldName] as bool? ?? false;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(field['label']),
        subtitle: (field['placeholder'] ?? field['hint']) != null 
            ? Text(field['placeholder'] ?? field['hint']) 
            : null,
        value: value,
        onChanged: (newValue) {
          setState(() {
            _categoryFieldValues[fieldName] = newValue;
          });
        },
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildColorField(Map<String, dynamic> field) {
    final fieldName = field['name'] ?? field['fieldName'];
    final options = List<String>.from(field['options'] ?? ['Red', 'Blue', 'Green', 'Yellow', 'Black', 'White']);
    final isRequired = field['required'] == true || field['isRequired'] == true;
    final selectedColor = _categoryFieldValues[fieldName];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field['label']}${isRequired ? ' *' : ''}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((color) {
            final isSelected = selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _categoryFieldValues[fieldName] = color;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  color,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (isRequired && selectedColor == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${field['label']} is required',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField(Map<String, dynamic> field) {
    final fieldName = field['name'] ?? field['fieldName'];
    final isRequired = field['required'] == true || field['isRequired'] == true;
    final selectedDate = _categoryFieldValues[fieldName] as DateTime?;
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        
        if (date != null) {
          setState(() {
            _categoryFieldValues[fieldName] = date;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '${field['label']}${isRequired ? ' *' : ''}',
          hintText: field['placeholder'] ?? field['hint'] ?? 'Select date',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null 
              ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
              : '',
          style: TextStyle(
            color: selectedDate != null ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    if (_categoriesLoading) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading categories...'),
            ],
          ),
        ),
      );
    }

    if (_mainCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No categories available. Please add categories first.',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: _loadCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainCategoryDropdown(),
        const SizedBox(height: 16),
        _buildSubCategorySection(),
        const SizedBox(height: 16),
        _buildSubSubCategorySection(),
        if (_selectedCategoryId != null) ...[
          const SizedBox(height: 12),
          _buildCategoryPathDisplay(),
        ],
      ],
    );
  }

  Widget _buildMainCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Main Category *',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: _mainCategories.map<DropdownMenuItem<String>>((category) {
        final categoryId = category['id']?.toString() ?? '';
        final categoryName = category['name']?.toString() ?? 'Unknown';
        
        return DropdownMenuItem<String>(
          value: categoryId,
          child: Text(
            categoryName,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
          _selectedSubCategoryId = null;
          _selectedSubSubCategoryId = null;
          _subCategories = [];
          _subSubCategories = [];
          // Don't clear fields here - let _loadCategoryFields handle it
        });
        
        if (value != null && value.isNotEmpty) {
          _loadSubCategoriesAsync(value);
          // Load main category fields immediately
          _loadCategoryFields(value);
        } else {
          // Clear fields if no category selected
          setState(() {
            _categorySpecificFields = [];
            _categoryFieldValues = {};
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a main category';
        }
        return null;
      },
    );
  }

  Widget _buildSubCategorySection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      child: _buildSubCategoryContent(),
    );
  }

  Widget _buildSubCategoryContent() {
    if (_isLoadingSubCategories) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Loading subcategories...', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }
    
    if (_subCategories.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: _selectedSubCategoryId,
        decoration: const InputDecoration(
          labelText: 'Sub Category',
          prefixIcon: Icon(Icons.subdirectory_arrow_right),
          border: OutlineInputBorder(),
        ),
        isExpanded: true,
        items: _subCategories.map<DropdownMenuItem<String>>((category) {
          final categoryId = category['id']?.toString() ?? '';
          final categoryName = category['name']?.toString() ?? 'Unknown';
          
          return DropdownMenuItem<String>(
            value: categoryId,
            child: Text(categoryName, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSubCategoryId = value;
            _selectedSubSubCategoryId = null;
            _subSubCategories = [];
          });
          
          if (value != null && value.isNotEmpty) {
            _loadSubSubCategoriesAsync(value);
            // Also load fields for this subcategory (with inheritance from main category)
            _loadCategoryFields(value);
          } else {
            // If no subcategory selected, load main category fields
            if (_selectedCategoryId != null) {
              _loadCategoryFields(_selectedCategoryId!);
            }
          }
        },
      );
    }
    
    if (_selectedCategoryId != null && _subCategories.isEmpty) {
      return Container(
        height: 56,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.info.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.info, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No subcategories available for this category.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          'Select a main category first',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSubSubCategorySection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      child: _buildSubSubCategoryContent(),
    );
  }

  Widget _buildSubSubCategoryContent() {
    if (_isLoadingSubSubCategories) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Loading sub-subcategories...', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }
    
    if (_subSubCategories.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: _selectedSubSubCategoryId,
        decoration: const InputDecoration(
          labelText: 'Sub-Sub Category',
          prefixIcon: Icon(Icons.double_arrow),
          border: OutlineInputBorder(),
        ),
        isExpanded: true,
        items: _subSubCategories.map<DropdownMenuItem<String>>((category) {
          final categoryId = category['id']?.toString() ?? '';
          final categoryName = category['name']?.toString() ?? 'Unknown';
          
          return DropdownMenuItem<String>(
            value: categoryId,
            child: Text(categoryName, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSubSubCategoryId = value;
          });
          
          if (value != null && value.isNotEmpty) {
            // Load fields for sub-subcategory (with inheritance from parent categories)
            _loadCategoryFields(value);
          } else {
            // If no sub-subcategory selected, load subcategory fields
            if (_selectedSubCategoryId != null) {
              _loadCategoryFields(_selectedSubCategoryId!);
            } else if (_selectedCategoryId != null) {
              _loadCategoryFields(_selectedCategoryId!);
            }
          }
        },
      );
    }
    
    if (_selectedSubCategoryId != null && 
        _subSubCategories.isEmpty && 
        _subCategories.isNotEmpty) {
      return Container(
        height: 56,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.info.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.info, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No sub-subcategories available for this subcategory.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          _selectedCategoryId == null 
              ? 'Select a main category first'
              : 'Select a subcategory first',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPathDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildCategoryPath(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildCategoryPath() {
    final path = <String>[];
    
    if (_selectedCategoryId != null && _mainCategories.isNotEmpty) {
      try {
        final mainCat = _mainCategories.firstWhere(
          (cat) => cat['id'] == _selectedCategoryId,
          orElse: () => <String, dynamic>{},
        );
        if (mainCat.isNotEmpty && mainCat['name'] != null) {
          path.add(mainCat['name'].toString());
        }
      } catch (e) {
        print('Error getting main category: $e');
      }
    }
    
    if (_selectedSubCategoryId != null && _subCategories.isNotEmpty) {
      try {
        final subCat = _subCategories.firstWhere(
          (cat) => cat['id'] == _selectedSubCategoryId,
          orElse: () => <String, dynamic>{},
        );
        if (subCat.isNotEmpty && subCat['name'] != null) {
          path.add(subCat['name'].toString());
        }
      } catch (e) {
        print('Error getting subcategory: $e');
      }
    }
    
    if (_selectedSubSubCategoryId != null && _subSubCategories.isNotEmpty) {
      try {
        final subSubCat = _subSubCategories.firstWhere(
          (cat) => cat['id'] == _selectedSubSubCategoryId,
          orElse: () => <String, dynamic>{},
        );
        if (subSubCat.isNotEmpty && subSubCat['name'] != null) {
          path.add(subSubCat['name'].toString());
        }
      } catch (e) {
        print('Error getting sub-subcategory: $e');
      }
    }
    
    return path.isEmpty ? 'Select a category' : path.join(' → ');
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _brandController,
                label: 'Brand',
                hint: 'Enter product brand',
                prefixIcon: Icons.branding_watermark_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _colorController,
                label: 'Color',
                hint: 'Enter product color',
                prefixIcon: Icons.palette_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _dimensionsController,
          label: 'Dimensions',
          hint: 'Enter dimensions (e.g., 10 x 5 x 2 cm)',
          prefixIcon: Icons.straighten_outlined,
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing & Shipping',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                  suffixText: 'AED',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Enter valid price';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedShippingOption,
                decoration: const InputDecoration(
                  labelText: 'Shipping Option',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                isExpanded: true,
                items: _shippingOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedShippingOption = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select shipping option';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        SwitchListTile(
          title: const Text('Allow Price Negotiation'),
          subtitle: const Text('Allow buyers to make offers on this product'),
          value: _allowPriceNegotiation,
          onChanged: (value) {
            setState(() {
              _allowPriceNegotiation = value;
            });
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        // City Selection
        Row(
          children: [
            Expanded(
              child: _isLoadingCities
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading cities...', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedCityId,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _cities.map<DropdownMenuItem<String>>((city) {
                        final cityId = city['id']?.toString() ?? '';
                        final cityName = city['name']?.toString() ?? 'Unknown City';
                        final country = city['country']?.toString() ?? '';
                        final state = city['state']?.toString() ?? '';
                        
                        return DropdownMenuItem<String>(
                          value: cityId,
                          child: Text(
                            '$cityName${state.isNotEmpty ? ', $state' : ''}${country.isNotEmpty ? ', $country' : ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCityId = value;
                          _selectedDistrictId = null;
                          _filteredDistricts = [];
                        });
                        
                        if (value != null && value.isNotEmpty) {
                          _filterDistrictsByCity(value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a city';
                        }
                        return null;
                      },
                    ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location_outlined, size: 18),
              label: const Text('Current'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // District Selection
        _isLoadingDistricts
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading districts...', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              )
            : DropdownButtonFormField<String>(
                value: _selectedDistrictId,
                decoration: const InputDecoration(
                  labelText: 'District',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _filteredDistricts.map<DropdownMenuItem<String>>((district) {
                  final districtId = district['id']?.toString() ?? '';
                  final districtName = district['name']?.toString() ?? 'Unknown District';
                  
                  return DropdownMenuItem<String>(
                    value: districtId,
                    child: Text(
                      districtName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDistrictId = value;
                  });
                },
                hint: _selectedCityId == null 
                    ? const Text('Select a city first')
                    : _filteredDistricts.isEmpty
                        ? const Text('No districts available')
                        : const Text('Select district (optional)'),
              ),
        
        if (_selectedCityId != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getLocationDisplayText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _buildFieldSummaryText() {
    final inheritedCount = _categorySpecificFields.where((f) => f['isInherited'] == true).length;
    final currentCount = _categorySpecificFields.length - inheritedCount;
    
    if (inheritedCount > 0 && currentCount > 0) {
      return '${_categorySpecificFields.length} fields: $currentCount specific + $inheritedCount inherited';
    } else if (inheritedCount > 0) {
      return '${_categorySpecificFields.length} inherited fields from parent categories';
    } else {
      return '${_categorySpecificFields.length} category-specific fields';
    }
  }

  String _getLocationDisplayText() {
    final selectedCity = _cities.firstWhere(
      (city) => city['id'] == _selectedCityId,
      orElse: () => <String, dynamic>{},
    );
    
    if (selectedCity.isEmpty) return 'Location: Not selected';
    
    String locationText = 'Location: ${selectedCity['name']}';
    
    if (_selectedDistrictId != null) {
      final selectedDistrict = _filteredDistricts.firstWhere(
        (district) => district['id'] == _selectedDistrictId,
        orElse: () => <String, dynamic>{},
      );
      
      if (selectedDistrict.isNotEmpty) {
        locationText += ', ${selectedDistrict['name']}';
      }
    }
    
    final country = selectedCity['country']?.toString();
    if (country != null && country.isNotEmpty) {
      locationText += ', $country';
    }
    
    return locationText;
  }

  Widget _buildPromotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Promotion Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Featured Product'),
                  subtitle: const Text('Show this product in featured section'),
                  value: _isFeatured,
                  onChanged: (value) {
                    setState(() {
                      _isFeatured = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Promoted Product'),
                  subtitle: const Text('Promote this product for better visibility'),
                  value: _isPromoted,
                  onChanged: (value) {
                    setState(() {
                      _isPromoted = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Product Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${_uploadedImageUrls.length}/10',
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.background,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _uploadedImageUrls.length < 10 ? _pickImages : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: _uploadedImageUrls.length < 10 
                                ? AppColors.primary 
                                : AppColors.textLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _uploadedImageUrls.length < 10 
                                ? 'Upload Images'
                                : 'Maximum Reached',
                            style: TextStyle(
                              color: _uploadedImageUrls.length < 10 
                                  ? AppColors.primary 
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Min 2, Max 10 images',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (_uploadedImageUrls.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Uploaded Images',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _uploadedImageUrls.length,
                      itemBuilder: (context, index) {
                        return _buildImageTile(index);
                      },
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image Guidelines',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Upload at least 2 images\n• Max file size: 5MB\n• Supported: JPG, PNG, WebP',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SafeNetworkImage(
              imageUrl: _uploadedImageUrls[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: AppColors.background,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          ),
          
          if (index == 0)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRIMARY',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Form Actions
  void _clearForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Form'),
        content: const Text('Are you sure you want to clear all form data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _subCategoryLoadTimer?.cancel();
    _subSubCategoryLoadTimer?.cancel();
    
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _brandController.clear();
    _dimensionsController.clear();
    _colorController.clear();
    
    setState(() {
      _selectedCategoryId = null;
      _selectedSubCategoryId = null;
      _selectedSubSubCategoryId = null;
      _selectedCondition = null;
      _selectedShippingOption = null;
      _selectedCityId = null;
      _selectedDistrictId = null;
      _allowPriceNegotiation = true;
      _isFeatured = false;
      _isPromoted = false;
      _uploadedImageUrls.clear();
      _subCategories = [];
      _subSubCategories = [];
      _categorySpecificFields = [];
      _categoryFieldValues = {};
      _filteredDistricts = [];
      _isLoadingSubCategories = false;
      _isLoadingSubSubCategories = false;
      _isLoadingCategoryFields = false;
      _isLoadingCities = false;
      _isLoadingDistricts = false;
    });
  }

  void _publishProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the condition of your item'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_uploadedImageUrls.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least 2 images'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_finalSelectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a city'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate required category-specific fields
    for (final field in _categorySpecificFields) {
      final isRequired = field['required'] == true || field['isRequired'] == true;
      if (isRequired) {
        final fieldName = field['name'] ?? field['fieldName'];
        final value = _categoryFieldValues[fieldName];
        
        if (value == null || 
            (value is String && value.isEmpty) ||
            (value is List && value.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${field['label']} is required'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
    }

    try {
      // Get location details
      final selectedCity = _cities.firstWhere(
        (city) => city['id'] == _selectedCityId,
        orElse: () => <String, dynamic>{},
      );
      
      String locationAddress = selectedCity['name'] ?? '';
      
      if (_selectedDistrictId != null) {
        final selectedDistrict = _filteredDistricts.firstWhere(
          (district) => district['id'] == _selectedDistrictId,
          orElse: () => <String, dynamic>{},
        );
        
        if (selectedDistrict.isNotEmpty) {
          locationAddress += ', ${selectedDistrict['name']}';
        }
      }
      
      final country = selectedCity['country']?.toString();
      if (country != null && country.isNotEmpty) {
        locationAddress += ', $country';
      }


      final productData = {
        'itemTitle': _titleController.text.trim(),
        'category': _finalSelectedCategory,
        'categoryName': _categoryDisplayName,
        'condition': _selectedCondition,
        'description': _descriptionController.text.trim(),
        'brand': _brandController.text.trim(),
        'dimensions': _dimensionsController.text.trim(),
        'color': _colorController.text.trim(),
        'price': double.parse(_priceController.text),
        'allowPriceNegotiation': _allowPriceNegotiation,
        'shippingOption': _selectedShippingOption,
        'locationAddress': locationAddress,
        'cityId': _selectedCityId,
        'districtId': _selectedDistrictId,
        'imageUrls': _uploadedImageUrls,
        'isFeatured': _isFeatured,
        'isPromoted': _isPromoted,
        'sellerId': Provider.of<UserProvider>(context, listen: false).currentSeller?.id ?? FirebaseAuth.instance.currentUser?.uid ?? '',
        'sellerName': Provider.of<UserProvider>(context, listen: false).currentSeller?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? '',
        'sellerType': Provider.of<UserProvider>(context, listen: false).currentSeller?.type ?? 'individual',
        'status': 'active',
        'views': 0,
        'likes': 0,
        'viewCount': 0,
        'favoriteCount': 0,
        
        // Add category-specific field values
        'categorySpecificFields': _categoryFieldValues,
        'hasCategoryFields': _categorySpecificFields.isNotEmpty,

      };

      await productProvider.createProduct(productData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product published successfully with category fields!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing product: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      DebugHelper.logError('Error publishing product: $e');
    }
  }

  void _pickImages() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = true;
    uploadInput.accept = 'image/*';
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null) {
        for (final file in files) {
          if (_uploadedImageUrls.length >= 10) break;
          
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((e) {
            setState(() {
              _uploadedImageUrls.add(reader.result as String);
            });
          });
        }
      }
    });
    
    uploadInput.click();
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
  }

  void _getCurrentLocation() {
    // Find Dubai in the cities list
    final dubaiCity = _cities.firstWhere(
      (city) => city['name']?.toString().toLowerCase() == 'dubai',
      orElse: () => <String, dynamic>{},
    );
    
    if (dubaiCity.isNotEmpty) {
      setState(() {
        _selectedCityId = dubaiCity['id'];
        _selectedDistrictId = null;
        _filteredDistricts = [];
      });
      
      _filterDistrictsByCity(dubaiCity['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location set to Dubai'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a city manually'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }
}




class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final bool required;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.required = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? errorWidget;

  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? const Icon(Icons.error),
    );
  }
}

// AppColors class
class AppColors {
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color border = Color(0xFFE0E0E0);
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF00BCD4);
  static const Color error = Color(0xFFE53E3E);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFED8936);
  static const Color info = Color(0xFF3182CE);
}