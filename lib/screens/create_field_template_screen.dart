
import 'dart:typed_data';

import 'package:delloniweb/providers/category_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
class CreateFieldTemplateScreen extends StatefulWidget {
  final Map<String, dynamic>? editingTemplate;
  final String? selectedCategoryId; // NEW: Pre-selected category

  const CreateFieldTemplateScreen({
    Key? key, 
    this.editingTemplate,
    this.selectedCategoryId,
  }) : super(key: key);

  @override
  State<CreateFieldTemplateScreen> createState() => _CreateFieldTemplateScreenState();
}

class _CreateFieldTemplateScreenState extends State<CreateFieldTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<Map<String, dynamic>> _fields = [];
  List<Map<String, dynamic>> _availableCategories = [];
  Map<String, dynamic>? _selectedCategory;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoadingCategories = true;

  // Available field types with image support
  static const List<Map<String, String>> _fieldTypes = [
    {'value': 'text', 'label': 'Text Field', 'description': 'Single line text input'},
    {'value': 'textarea', 'label': 'Text Area', 'description': 'Multi-line text input'},
    {'value': 'number', 'label': 'Number', 'description': 'Numeric input'},
    {'value': 'dropdown', 'label': 'Dropdown', 'description': 'Select from predefined options'},
    {'value': 'checkbox', 'label': 'Checkbox', 'description': 'True/false selection'},
    {'value': 'radio', 'label': 'Radio Buttons', 'description': 'Single choice from multiple options'},
    {'value': 'date', 'label': 'Date', 'description': 'Date picker'},
    {'value': 'time', 'label': 'Time', 'description': 'Time picker'},
    {'value': 'datetime', 'label': 'Date & Time', 'description': 'Date and time picker'},
    {'value': 'file', 'label': 'File Upload', 'description': 'File attachment'},
    {'value': 'image', 'label': 'Image Upload', 'description': 'Image file upload with preview'},
    {'value': 'color', 'label': 'Color Picker', 'description': 'Color selection'},
    {'value': 'boolean', 'label': 'Boolean', 'description': 'True/false toggle'},
    {'value': 'color_picker', 'label': 'Advanced Color Picker', 'description': 'Color selection with palette'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeForm();
  }

  void _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      await provider.loadAllCategories();
      
      setState(() {
        // Filter out categories with missing essential data to prevent crashes
        _availableCategories = provider.allCategories
            .where((category) => 
                category != null &&
                category['isActive'] == true &&
                category['id'] != null &&
                category['name'] != null &&
                category['name'].toString().trim().isNotEmpty)
            .toList();
        
        // Pre-select category if provided and it exists in available categories
        if (widget.selectedCategoryId != null) {
          _selectedCategory = _availableCategories.firstWhere(
            (cat) => cat['id'] == widget.selectedCategoryId,
            orElse: () => {},
          );
          if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
            _nameController.text = 'Fields for ${_selectedCategory!['name']}';
            
            // Load existing fields safely
            if (_selectedCategory!['configuredFields'] != null) {
              try {
                final existingFields = List<Map<String, dynamic>>.from(
                  _selectedCategory!['configuredFields']
                );
                _fields = existingFields
                    .map((field) => _convertToStandardFormat(field))
                    .where((field) => field != null)
                    .cast<Map<String, dynamic>>()
                    .toList();
              } catch (e) {
                print('Error loading existing fields: $e');
                _fields = [];
              }
            }
          }
        }
        
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _initializeForm() {
    if (widget.editingTemplate != null) {
      final template = widget.editingTemplate!;
      _nameController.text = template['name'] ?? '';
      _descriptionController.text = template['description'] ?? '';
      _isActive = template['isActive'] ?? true;
      
      final fields = template['fields'] as List<dynamic>?;
      if (fields != null) {
        _fields = fields.map((field) => Map<String, dynamic>.from(field)).toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.editingTemplate != null 
            ? 'Edit Category Fields' 
            : 'Add Fields to Category'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        actions: [
          _buildActionButtons(),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading categories...'),
                ],
              ),
            )
          : Row(
              children: [
                // Main form
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCategorySelectionSection(),
                                const SizedBox(height: 32),
                                _buildBasicInfoSection(),
                                const SizedBox(height: 32),
                                _buildFieldsSection(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Field builder panel
                Container(
                  width: 400,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(left: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: _buildFieldBuilderPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving || _selectedCategory == null ? null : _saveFieldsToCategory,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Fields'),
          ),
        ],
      ),
    );
  }

  // NEW: Category selection section
  Widget _buildCategorySelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        // Simplified dropdown to prevent crashes and layout issues
        DropdownButtonFormField<String>(
          value: _selectedCategory?['id'],
          decoration: const InputDecoration(
            labelText: 'Select Category',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          isExpanded: true, // This helps with width constraints
          items: _availableCategories.map((category) {
            final categoryId = category['id'] ?? '';
            final categoryName = category['name'] ?? 'Unknown Category';
            final levelType = category['levelType'] ?? '';
            final fieldCount = category['configuredFields'] != null 
                ? (category['configuredFields'] as List).length 
                : 0;
                
            return DropdownMenuItem<String>(
              value: categoryId,
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Fix for unbounded width
                  children: [
                    // Simple icon without image loading
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.category,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Use Flexible instead of Expanded to fix the error
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (levelType.isNotEmpty) ...[
                            Text(
                              '$levelType${fieldCount > 0 ? ' • $fieldCount fields' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMedium,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (categoryId) {
            if (categoryId != null) {
              final category = _availableCategories.firstWhere(
                (cat) => cat['id'] == categoryId,
                orElse: () => {},
              );
              
              setState(() {
                _selectedCategory = category.isNotEmpty ? category : null;
                if (_selectedCategory != null) {
                  _nameController.text = 'Fields for ${_selectedCategory!['name']}';
                  
                  // Load existing fields if any
                  if (_selectedCategory!['configuredFields'] != null) {
                    final existingFields = List<Map<String, dynamic>>.from(
                      _selectedCategory!['configuredFields']
                    );
                    _fields = existingFields
                        .map((field) => _convertToStandardFormat(field))
                        .where((field) => field != null)
                        .cast<Map<String, dynamic>>()
                        .toList();
                  } else {
                    _fields.clear();
                  }
                }
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
        
        if (_selectedCategory != null) ...[
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${_selectedCategory!['name']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (_selectedCategory!['levelType'] != null) ...[
                            Text(
                              'Type: ${_selectedCategory!['levelType']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (_selectedCategory!['configuredFields'] != null) ...[
                            Text(
                              'Existing Fields: ${(_selectedCategory!['configuredFields'] as List).length}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Field Configuration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Configuration Name',
            hintText: 'e.g., Fields for Electronics',
            prefixIcon: Icon(Icons.label),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Configuration name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe what these fields are for...',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // Convert category field format to standard format with safety checks
  Map<String, dynamic>? _convertToStandardFormat(Map<String, dynamic> categoryField) {
    try {
      // Validate essential fields
      if (categoryField == null) return null;
      
      final name = categoryField['name']?.toString().trim();
      final label = categoryField['label']?.toString().trim();
      final type = categoryField['type']?.toString().trim();
      
      if (name == null || name.isEmpty) return null;
      if (label == null || label.isEmpty) return null;
      if (type == null || type.isEmpty) return null;
      
      return {
        'fieldName': name,
        'label': label,
        'fieldType': _mapCategoryFieldType(type),
        'isRequired': categoryField['required'] == true,
        'order': categoryField['id'] ?? DateTime.now().millisecondsSinceEpoch,
        'category': categoryField['category']?.toString() ?? 'basic_info',
        'id': categoryField['id'] ?? DateTime.now().millisecondsSinceEpoch,
        
        // Optional fields with null checks
        if (categoryField['options'] != null && categoryField['options'] is List)
          'options': List<String>.from(categoryField['options']),
        if (categoryField['validation'] != null && categoryField['validation'] is Map)
          'validation': Map<String, dynamic>.from(categoryField['validation']),
        if (categoryField['placeholder'] != null)
          'placeholder': categoryField['placeholder'].toString(),
        if (categoryField['showFieldIcon'] == true) ...{
          'showFieldIcon': true,
          if (categoryField['fieldIconUrl'] != null)
            'fieldIconUrl': categoryField['fieldIconUrl'].toString(),
        },
      };
    } catch (e) {
      print('Error converting field to standard format: $e');
      return null;
    }
  }

  // Convert standard format back to category field format with safety checks
  Map<String, dynamic>? _convertToCategoryFormat(Map<String, dynamic> standardField) {
    try {
      // Validate essential fields
      if (standardField == null) return null;
      
      final fieldName = standardField['fieldName']?.toString().trim();
      final label = standardField['label']?.toString().trim();
      final fieldType = standardField['fieldType']?.toString().trim();
      
      if (fieldName == null || fieldName.isEmpty) return null;
      if (label == null || label.isEmpty) return null;
      if (fieldType == null || fieldType.isEmpty) return null;
      
      final categoryFormat = {
        'id': standardField['id'] ?? DateTime.now().millisecondsSinceEpoch,
        'name': fieldName,
        'label': label,
        'type': _mapStandardFieldType(fieldType),
        'required': standardField['isRequired'] == true,
        'category': standardField['category']?.toString() ?? 'basic_info',
      };
      
      // Add optional fields safely
      if (standardField['options'] != null && standardField['options'] is List) {
        categoryFormat['options'] = List<String>.from(standardField['options']);
      }
      
      if (standardField['validation'] != null && standardField['validation'] is Map) {
        categoryFormat['validation'] = Map<String, dynamic>.from(standardField['validation']);
      }
      
      if (standardField['placeholder'] != null) {
        categoryFormat['placeholder'] = standardField['placeholder'].toString();
      }
      
      if (standardField['showFieldIcon'] == true) {
        categoryFormat['showFieldIcon'] = true;
        if (standardField['fieldIconUrl'] != null) {
          categoryFormat['fieldIconUrl'] = standardField['fieldIconUrl'].toString();
        }
      }
      
      return categoryFormat;
    } catch (e) {
      print('Error converting field to category format: $e');
      return null;
    }
  }

  String _mapCategoryFieldType(String categoryType) {
    switch (categoryType) {
      case 'boolean': return 'checkbox';
      case 'color_picker': return 'color';
      default: return categoryType;
    }
  }

  String _mapStandardFieldType(String standardType) {
    switch (standardType) {
      case 'checkbox': return 'boolean';
      case 'color': return 'color_picker';
      default: return standardType;
    }
  }

  Widget _buildFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Category Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _selectedCategory != null ? _addNewField : null,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Field'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_selectedCategory == null) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: const Column(
              children: [
                Icon(Icons.category, size: 48, color: AppColors.warning),
                SizedBox(height: 16),
                Text(
                  'Please select a category first',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select a category from the dropdown above to start adding fields',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_fields.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.dynamic_form, size: 48, color: AppColors.textMedium),
                SizedBox(height: 16),
                Text(
                  'No fields added yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add fields to define what information users need to provide for this category',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fields.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _fields.removeAt(oldIndex);
                _fields.insert(newIndex, item);
                // Update order values
                for (int i = 0; i < _fields.length; i++) {
                  _fields[i]['order'] = i + 1;
                }
              });
            },
            itemBuilder: (context, index) {
              final field = _fields[index];
              return _buildFieldCard(field, index);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field, int index) {
    final isRequired = field['isRequired'] == true;
    final fieldType = field['fieldType'] ?? 'text';
    final showFieldIcon = field['showFieldIcon'] == true;
    final fieldIconUrl = field['fieldIconUrl'];
    
    return Card(
      key: ValueKey(field['fieldName'] ?? index),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Field type icon or custom field icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: showFieldIcon && fieldIconUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            fieldIconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              _getIconForFieldType(fieldType),
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Icon(
                          _getIconForFieldType(fieldType),
                          size: 16,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              field['label'] ?? field['fieldName'] ?? 'Unnamed Field',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          // Show field icon indicator
                          if (showFieldIcon) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 10,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'ICON',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRequired ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isRequired ? 'Required' : 'Optional',
                              style: TextStyle(
                                fontSize: 11,
                                color: isRequired ? AppColors.error : AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            fieldType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                          if (field['fieldName'] != null) ...[
                            const Text(' • ', style: TextStyle(color: AppColors.textMedium)),
                            Text(
                              'fieldName: ${field['fieldName']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMedium,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editField(index);
                        break;
                      case 'duplicate':
                        _duplicateField(index);
                        break;
                      case 'delete':
                        _deleteField(index);
                        break;
                    }
                  },
                ),
              ],
            ),
            
            // Field details
            const SizedBox(height: 12),
            
            if (field['placeholder'] != null) ...[
              Text(
                'Placeholder: ${field['placeholder']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
            ],
            
            if (field['options'] != null && field['options'] is List) ...[
              Text(
                'Options: ${(field['options'] as List).take(3).join(', ')}${(field['options'] as List).length > 3 ? '...' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFieldBuilderPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: const Row(
            children: [
              Icon(Icons.build, color: AppColors.white),
              SizedBox(width: 8),
              Text(
                'Field Builder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Field Types',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: _fieldTypes.length,
                    itemBuilder: (context, index) {
                      final fieldType = _fieldTypes[index];
                      return _buildFieldTypeCard(fieldType);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldTypeCard(Map<String, String> fieldType) {
    final isImageType = fieldType['value'] == 'image';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getIconForFieldType(fieldType['value']!),
          color: isImageType ? AppColors.warning : AppColors.primary,
        ),
        title: Text(
          fieldType['label']!,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          fieldType['description']!,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
        trailing: isImageType 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: _selectedCategory != null ? () => _createFieldFromType(fieldType['value']!) : null,
      ),
    );
  }

  void _addNewField() {
    if (_selectedCategory == null) return;
    _showFieldDialog();
  }

  void _editField(int index) {
    _showFieldDialog(editingField: _fields[index], editingIndex: index);
  }

  void _duplicateField(int index) {
    final originalField = Map<String, dynamic>.from(_fields[index]);
    originalField['fieldName'] = '${originalField['fieldName']}_copy';
    originalField['label'] = '${originalField['label']} (Copy)';
    originalField['order'] = _fields.length + 1;
    originalField['id'] = DateTime.now().millisecondsSinceEpoch;
    
    setState(() {
      _fields.add(originalField);
    });
  }

  void _deleteField(int index) {
    setState(() {
      _fields.removeAt(index);
      // Update order values
      for (int i = 0; i < _fields.length; i++) {
        _fields[i]['order'] = i + 1;
      }
    });
  }

  void _createFieldFromType(String fieldType) {
    if (_selectedCategory == null) return;
    
    final newField = {
      'fieldName': '${fieldType}_${DateTime.now().millisecondsSinceEpoch}',
      'label': fieldType == 'image' ? 'Image Upload' : 'New ${fieldType.capitalize()} Field',
      'fieldType': fieldType,
      'isRequired': false,
      'order': _fields.length + 1,
      'id': DateTime.now().millisecondsSinceEpoch,
      'category': 'basic_info',
    };
    
    // Add type-specific defaults
    if (fieldType == 'dropdown' || fieldType == 'radio') {
      newField['options'] = ['Option 1', 'Option 2', 'Option 3'];
    } else if (fieldType == 'image') {
      newField['placeholder'] = 'Click to upload image';
      newField['validation'] = {
        'maxSize': 5, // 5MB
        'allowedTypes': ['jpg', 'jpeg', 'png', 'gif'],
      };
    } else if (fieldType == 'file') {
      newField['validation'] = {
        'maxSize': 10, // 10MB
        'allowedTypes': ['pdf', 'doc', 'docx', 'txt'],
      };
    }
    
    _showFieldDialog(editingField: newField);
  }

  void _showFieldDialog({Map<String, dynamic>? editingField, int? editingIndex}) {
    showDialog(
      context: context,
      builder: (context) => FieldConfigDialog(
        editingField: editingField,
        onSave: (field) {
          setState(() {
            if (editingIndex != null) {
              _fields[editingIndex] = field;
            } else {
              _fields.add(field);
            }
          });
        },
      ),
    );
  }

  IconData _getIconForFieldType(String fieldType) {
    switch (fieldType) {
      case 'text': return Icons.text_fields;
      case 'textarea': return Icons.notes;
      case 'number': return Icons.numbers;
      case 'dropdown': return Icons.arrow_drop_down;
      case 'checkbox': return Icons.check_box;
      case 'radio': return Icons.radio_button_checked;
      case 'date': return Icons.calendar_today;
      case 'time': return Icons.access_time;
      case 'datetime': return Icons.date_range;
      case 'file': return Icons.attach_file;
      case 'image': return Icons.image;
      case 'color': return Icons.palette;
      case 'boolean': return Icons.toggle_on;
      case 'color_picker': return Icons.color_lens;
      default: return Icons.input;
    }
  }

  void _saveFieldsToCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one field'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Convert fields to category format with error handling
      final configuredFields = <Map<String, dynamic>>[];
      
      for (final field in _fields) {
        final convertedField = _convertToCategoryFormat(field);
        if (convertedField != null) {
          configuredFields.add(convertedField);
        } else {
          print('Warning: Failed to convert field: ${field['fieldName']}');
        }
      }
      
      if (configuredFields.isEmpty) {
        throw Exception('No valid fields to save');
      }
      
      // Update category with the new fields
      final updatedCategoryData = {
        'configuredFields': configuredFields,
        'hasCustomFields': true,
      };
      
      await provider.updateCategoryWithFields(_selectedCategory!['id'], updatedCategoryData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${configuredFields.length} fields added to category successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving fields: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
class FieldConfigDialog extends StatefulWidget {
  final Map<String, dynamic>? editingField;
  final Function(Map<String, dynamic>) onSave;

  const FieldConfigDialog({
    Key? key,
    this.editingField,
    required this.onSave,
  }) : super(key: key);

  @override
  State<FieldConfigDialog> createState() => _FieldConfigDialogState();
}

class _FieldConfigDialogState extends State<FieldConfigDialog> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fieldNameController = TextEditingController();
  final _labelController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _optionsController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _minLengthController = TextEditingController();
  final _maxLengthController = TextEditingController();
  final _patternController = TextEditingController();
  final _maxSizeController = TextEditingController();
  final _allowedTypesController = TextEditingController();

  String _selectedType = 'text';
  bool _isRequired = false;
  bool _showFieldIcon = false; // NEW: Option to show icon with field
  String? _fieldIconUrl; // NEW: Store icon URL
  bool _isUploadingIcon = false; // NEW: Upload state
  List<String> _options = [];
  late TabController _tabController;

  // Available field types with image support
  static const List<Map<String, String>> _fieldTypes = [
    {'value': 'text', 'label': 'Text Field'},
    {'value': 'textarea', 'label': 'Text Area'},
    {'value': 'number', 'label': 'Number'},
    {'value': 'dropdown', 'label': 'Dropdown'},
    {'value': 'checkbox', 'label': 'Checkbox'},
    {'value': 'radio', 'label': 'Radio Buttons'},
    {'value': 'date', 'label': 'Date'},
    {'value': 'time', 'label': 'Time'},
    {'value': 'datetime', 'label': 'Date & Time'},
    {'value': 'file', 'label': 'File Upload'},
    {'value': 'image', 'label': 'Image Upload'},
    {'value': 'color', 'label': 'Color Picker'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Updated to 4 tabs
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.editingField != null) {
      final field = widget.editingField!;
      _fieldNameController.text = field['fieldName'] ?? '';
      _labelController.text = field['label'] ?? '';
      _placeholderController.text = field['placeholder'] ?? '';
      _selectedType = field['fieldType'] ?? 'text';
      _isRequired = field['isRequired'] ?? false;
      
      // NEW: Load icon configuration
      _showFieldIcon = field['showFieldIcon'] ?? false;
      _fieldIconUrl = field['fieldIconUrl'];
      
      if (field['options'] != null) {
        _options = List<String>.from(field['options']);
        _optionsController.text = _options.join('\n');
      }
      
      if (field['validation'] != null) {
        final validation = field['validation'];
        _minController.text = validation['min']?.toString() ?? '';
        _maxController.text = validation['max']?.toString() ?? '';
        _minLengthController.text = validation['minLength']?.toString() ?? '';
        _maxLengthController.text = validation['maxLength']?.toString() ?? '';
        _patternController.text = validation['pattern']?.toString() ?? '';
        _maxSizeController.text = validation['maxSize']?.toString() ?? '';
        
        if (validation['allowedTypes'] != null) {
          _allowedTypesController.text = (validation['allowedTypes'] as List).join(', ');
        }
      }
    } else {
      // Set defaults for new fields
      _setDefaultsForFieldType(_selectedType);
    }
  }

  void _setDefaultsForFieldType(String fieldType) {
    switch (fieldType) {
      case 'image':
        _placeholderController.text = 'Click to upload image';
        _maxSizeController.text = '5';
        _allowedTypesController.text = 'jpg, jpeg, png, gif';
        break;
      case 'file':
        _placeholderController.text = 'Click to upload file';
        _maxSizeController.text = '10';
        _allowedTypesController.text = 'pdf, doc, docx, txt';
        break;
      case 'dropdown':
      case 'radio':
        if (_options.isEmpty) {
          _options = ['Option 1', 'Option 2', 'Option 3'];
          _optionsController.text = _options.join('\n');
        }
        break;
      case 'number':
        _placeholderController.text = 'Enter a number';
        break;
      case 'date':
        _placeholderController.text = 'Select date';
        break;
      case 'time':
        _placeholderController.text = 'Select time';
        break;
      case 'color':
        _placeholderController.text = 'Choose color';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800, // Increased width for icon configuration
        height: 700, // Increased height
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForFieldType(_selectedType),
                    color: AppColors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.editingField != null ? 'Edit Field' : 'Add New Field',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.settings), text: 'Basic'),
                Tab(icon: Icon(Icons.image), text: 'Icon'), // NEW TAB
                Tab(icon: Icon(Icons.tune), text: 'Options'),
                Tab(icon: Icon(Icons.verified), text: 'Validation'),
              ],
            ),
            
            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicTab(),
                    _buildIconTab(), // NEW TAB
                    _buildOptionsTab(),
                    _buildValidationTab(),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveField,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Save Field'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _fieldNameController,
                  decoration: const InputDecoration(
                    labelText: 'Field Name *',
                    hintText: 'e.g., year, color, price',
                    helperText: 'Used in code (no spaces, lowercase)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Field name is required';
                    }
                    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(value)) {
                      return 'Invalid field name format';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Auto-generate label if empty
                    if (_labelController.text.isEmpty && value.isNotEmpty) {
                      _labelController.text = value.split('_')
                          .map((word) => word.capitalize())
                          .join(' ');
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Display Label *',
                    hintText: 'e.g., Year, Color, Price',
                    helperText: 'Shown to users',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Display label is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Field Type',
              prefixIcon: Icon(_getIconForFieldType(_selectedType)),
            ),
            items: _fieldTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['value'],
                child: Row(
                  children: [
                    Icon(_getIconForFieldType(type['value']!), size: 16),
                    const SizedBox(width: 8),
                    Text(type['label']!),
                    if (type['value'] == 'image') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
                _setDefaultsForFieldType(_selectedType);
              });
            },
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _placeholderController,
            decoration: const InputDecoration(
              labelText: 'Placeholder Text',
              hintText: 'e.g., Enter year of manufacture',
              helperText: 'Hint text shown in the field',
            ),
          ),
          const SizedBox(height: 24),
          
          SwitchListTile(
            title: const Text('Required Field'),
            subtitle: const Text('Users must fill this field'),
            value: _isRequired,
            onChanged: (value) {
              setState(() {
                _isRequired = value;
              });
            },
            activeColor: AppColors.primary,
          ),
          
          if (_selectedType == 'image') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text(
                        'Image Upload Field',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This field will allow users to upload images with preview functionality. Configure file size limits and allowed formats in the Validation tab.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Icon configuration tab
  Widget _buildIconTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Field Icon Configuration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure an icon that will appear next to this field when displayed in product details.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 24),
          
          // Toggle to show field icon
          SwitchListTile(
            title: const Text('Show Field Icon'),
            subtitle: const Text('Display an icon next to this field in product details'),
            value: _showFieldIcon,
            onChanged: (value) {
              setState(() {
                _showFieldIcon = value;
              });
            },
            activeColor: AppColors.primary,
          ),
          
          if (_showFieldIcon) ...[
            const SizedBox(height: 24),
            
            // Icon preview and upload
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon preview
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _fieldIconUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _fieldIconUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              color: AppColors.error,
                              size: 32,
                            ),
                          ),
                        )
                      : Icon(
                          _getIconForFieldType(_selectedType),
                          color: AppColors.textMedium,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Upload controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Field Icon',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload a small icon (32x32px recommended) that represents this field. This will be shown next to the field value in product details.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isUploadingIcon ? null : _pickFieldIcon,
                            icon: _isUploadingIcon
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload, size: 16),
                            label: Text(_fieldIconUrl == null ? 'Upload Icon' : 'Change Icon'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                          if (_fieldIconUrl != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              tooltip: 'Remove Icon',
                              onPressed: () {
                                setState(() {
                                  _fieldIconUrl = null;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Icon preview example
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.preview, color: AppColors.info, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Preview: How it will appear in product details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Example preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon preview
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _fieldIconUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    _fieldIconUrl!,
                                    fit: BoxFit.cover,
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      _getIconForFieldType(_selectedType),
                                      size: 12,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _getIconForFieldType(_selectedType),
                                  size: 12,
                                  color: AppColors.textMedium,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelController.text.isNotEmpty ? _labelController.text : 'Field Label',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMedium,
                              ),
                            ),
                            const Text(
                              'Sample Value',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textMedium, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Field icon is disabled. Enable "Show Field Icon" to configure an icon for this field.',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedType == 'dropdown' || _selectedType == 'radio') ...[
            const Text(
              'Field Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _optionsController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Options (one per line)',
                hintText: 'Option 1\nOption 2\nOption 3',
                alignLabelWithHint: true,
                helperText: 'Enter each option on a new line',
              ),
              onChanged: (value) {
                _options = value.split('\n')
                    .map((option) => option.trim())
                    .where((option) => option.isNotEmpty)
                    .toList();
              },
              validator: (value) {
                if (_selectedType == 'dropdown' || _selectedType == 'radio') {
                  if (value == null || value.trim().isEmpty) {
                    return 'At least one option is required';
                  }
                  final options = value.split('\n')
                      .map((option) => option.trim())
                      .where((option) => option.isNotEmpty)
                      .toList();
                  if (options.length < 2) {
                    return 'At least two options are required';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Option'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearOptions,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear All'),
                ),
              ],
            ),
            
            if (_options.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Preview:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          if (_selectedType == 'dropdown')
                            const Icon(Icons.arrow_drop_down, size: 16)
                          else
                            const Icon(Icons.radio_button_unchecked, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(option)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => _removeOption(index),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ] else ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: AppColors.textMedium),
                  SizedBox(height: 16),
                  Text(
                    'No options needed for this field type',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Validation Rules',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_selectedType == 'number') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      labelText: 'Minimum Value',
                      hintText: '0',
                      prefixIcon: Icon(Icons.remove),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      labelText: 'Maximum Value',
                      hintText: '100',
                      prefixIcon: Icon(Icons.add),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          if (_selectedType == 'text' || _selectedType == 'textarea') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minLengthController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Min Length',
                      hintText: '0',
                      prefixIcon: Icon(Icons.short_text),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxLengthController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Max Length',
                      hintText: '100',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patternController,
              decoration: const InputDecoration(
                labelText: 'Pattern (RegExp)',
                hintText: '^[a-zA-Z]+\$',
                prefixIcon: Icon(Icons.pattern),
                helperText: 'Regular expression for validation',
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (_selectedType == 'image' || _selectedType == 'file') ...[
            TextFormField(
              controller: _maxSizeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Max File Size (MB)',
                hintText: _selectedType == 'image' ? '5' : '10',
                prefixIcon: const Icon(Icons.storage),
                suffixText: 'MB',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _allowedTypesController,
              decoration: InputDecoration(
                labelText: 'Allowed File Types',
                hintText: _selectedType == 'image' 
                    ? 'jpg, jpeg, png, gif'
                    : 'pdf, doc, docx, txt',
                prefixIcon: const Icon(Icons.extension),
                helperText: 'Comma-separated file extensions',
              ),
            ),
            const SizedBox(height: 16),
            
            if (_selectedType == 'image') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppColors.info, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Image Upload Features',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Automatic image compression\n'
                      '• Image preview before upload\n'
                      '• Drag & drop support\n'
                      '• Multiple image selection (if enabled)\n'
                      '• EXIF data removal for privacy',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
          
          if (_selectedType != 'number' && 
              _selectedType != 'text' && 
              _selectedType != 'textarea' && 
              _selectedType != 'image' && 
              _selectedType != 'file') ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: AppColors.textMedium),
                  SizedBox(height: 16),
                  Text(
                    'No validation rules needed for this field type',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addOption() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Option'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Option Text',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _options.add(controller.text.trim());
                    _optionsController.text = _options.join('\n');
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
      _optionsController.text = _options.join('\n');
    });
  }

  void _clearOptions() {
    setState(() {
      _options.clear();
      _optionsController.text = '';
    });
  }

  // NEW: Pick field icon
  void _pickFieldIcon() async {
    setState(() {
      _isUploadingIcon = true;
    });

    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();
      
      uploadInput.onChange.listen((event) async {
        final file = uploadInput.files?.first;
        if (file != null) {
          // Validate file size (max 1MB for icons)
          if (file.size > 1 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Icon size must be less than 1MB'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            setState(() {
              _isUploadingIcon = false;
            });
            return;
          }

          // Validate file type
          if (!file.type.startsWith('image/')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a valid image file'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            setState(() {
              _isUploadingIcon = false;
            });
            return;
          }

          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((event) async {
            try {
              final result = reader.result;
              Uint8List bytes;
              
              if (result is Uint8List) {
                bytes = result;
              } else if (result is ByteBuffer) {
                bytes = result.asUint8List();
              } else if (result is List<int>) {
                bytes = Uint8List.fromList(result);
              } else {
                throw Exception('Unsupported file result type: ${result.runtimeType}');
              }

              final provider = Provider.of<CategoryProvider>(context, listen: false);
              final fileName = 'field_icon_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
              final url = await provider.uploadImage(bytes, fileName);
              
              if (mounted) {
                setState(() {
                  _fieldIconUrl = url.contains('?')
                      ? '$url&cb=${DateTime.now().millisecondsSinceEpoch}'
                      : '$url?cb=${DateTime.now().millisecondsSinceEpoch}';
                  _isUploadingIcon = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Field icon uploaded successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              print('Upload error: ${e.toString()}');
              if (mounted) {
                setState(() {
                  _isUploadingIcon = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to upload icon: ${e.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          });

          reader.onError.listen((event) {
            if (mounted) {
              setState(() {
                _isUploadingIcon = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to read image file'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          });
        } else {
          setState(() {
            _isUploadingIcon = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingIcon = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getIconForFieldType(String fieldType) {
    switch (fieldType) {
      case 'text': return Icons.text_fields;
      case 'textarea': return Icons.notes;
      case 'number': return Icons.numbers;
      case 'dropdown': return Icons.arrow_drop_down;
      case 'checkbox': return Icons.check_box;
      case 'radio': return Icons.radio_button_checked;
      case 'date': return Icons.calendar_today;
      case 'time': return Icons.access_time;
      case 'datetime': return Icons.date_range;
      case 'file': return Icons.attach_file;
      case 'image': return Icons.image;
      case 'color': return Icons.palette;
      default: return Icons.input;
    }
  }

  void _saveField() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for dropdown/radio fields
    if ((_selectedType == 'dropdown' || _selectedType == 'radio') && _options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType == 'dropdown' ? 'Dropdown' : 'Radio'} fields must have at least one option'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final field = {
      'fieldName': _fieldNameController.text.trim(),
      'label': _labelController.text.trim(),
      'fieldType': _selectedType,
      'isRequired': _isRequired,
      'order': widget.editingField?['order'] ?? 1,
      
      // NEW: Icon configuration
      'showFieldIcon': _showFieldIcon,
      'fieldIconUrl': _fieldIconUrl,
    };

    // Add optional fields only if they have values
    final placeholder = _placeholderController.text.trim();
    if (placeholder.isNotEmpty) {
      field['placeholder'] = placeholder;
    }

    // Add options for dropdown/radio fields
    if (_options.isNotEmpty && (_selectedType == 'dropdown' || _selectedType == 'radio')) {
      field['options'] = List<String>.from(_options);
    }

    // Add validation rules only if they have values
    final validation = <String, dynamic>{};
    
    final minText = _minController.text.trim();
    if (minText.isNotEmpty) {
      final minValue = double.tryParse(minText);
      if (minValue != null) {
        validation['min'] = minValue;
      }
    }
    
    final maxText = _maxController.text.trim();
    if (maxText.isNotEmpty) {
      final maxValue = double.tryParse(maxText);
      if (maxValue != null) {
        validation['max'] = maxValue;
      }
    }
    
    final minLengthText = _minLengthController.text.trim();
    if (minLengthText.isNotEmpty) {
      final minLength = int.tryParse(minLengthText);
      if (minLength != null) {
        validation['minLength'] = minLength;
      }
    }
    
    final maxLengthText = _maxLengthController.text.trim();
    if (maxLengthText.isNotEmpty) {
      final maxLength = int.tryParse(maxLengthText);
      if (maxLength != null) {
        validation['maxLength'] = maxLength;
      }
    }
    
    final patternText = _patternController.text.trim();
    if (patternText.isNotEmpty) {
      validation['pattern'] = patternText;
    }
    
    final maxSizeText = _maxSizeController.text.trim();
    if (maxSizeText.isNotEmpty) {
      final maxSize = int.tryParse(maxSizeText);
      if (maxSize != null) {
        validation['maxSize'] = maxSize;
      }
    }
    
    final allowedTypesText = _allowedTypesController.text.trim();
    if (allowedTypesText.isNotEmpty) {
      final allowedTypes = allowedTypesText
          .split(',')
          .map((type) => type.trim().toLowerCase())
          .where((type) => type.isNotEmpty)
          .toList();
      if (allowedTypes.isNotEmpty) {
        validation['allowedTypes'] = allowedTypes;
      }
    }

    if (validation.isNotEmpty) {
      field['validation'] = validation;
    }

    widget.onSave(field);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fieldNameController.dispose();
    _labelController.dispose();
    _placeholderController.dispose();
    _optionsController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _minLengthController.dispose();
    _maxLengthController.dispose();
    _patternController.dispose();
    _maxSizeController.dispose();
    _allowedTypesController.dispose();
    super.dispose();
  }
}


// Required imports (add these to the top of your file)
// import 'dart:html' as html;
// import 'dart:typed_data';
// import 'package:flutter/services.dart';