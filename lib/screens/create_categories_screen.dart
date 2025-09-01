import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/category_field_templates.dart';
import 'package:delloniweb/providers/category_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/field_template_management_screen.dart' hide AppColors, CategoryFieldTemplates;
import 'package:delloniweb/screens/widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import 'dart:typed_data'; // Added for Uint8List
// Simplified CreateCategoryScreen without template selection
class CreateCategoryScreen extends StatefulWidget {
  final Map<String, dynamic>? parentCategory;
  final Map<String, dynamic>? editingCategory;

  const CreateCategoryScreen({
    Key? key,
    this.parentCategory,
    this.editingCategory,
  }) : super(key: key);

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _nameController = TextEditingController();
  // final _descriptionController = TextEditingController();
  final _orderController = TextEditingController();
  
  // Form data
  String? _selectedParentCategory;
  bool _isActive = true;
  bool _showInMenu = true;
  bool _featuredCategory = false;
  String? _uploadedIconUrl;
  bool _isUploading = false;
  int _currentLevel = 0;
  List<Map<String, dynamic>> _availableParentCategories = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadData();
  }

  void _initializeForm() {
    if (widget.editingCategory != null) {
      // Edit mode
      final category = widget.editingCategory!;
      _nameController.text = category['name'] ?? '';
      // _descriptionController.text = category['description'] ?? '';
      _orderController.text = category['order']?.toString() ?? '0';
      _selectedParentCategory = category['parentId'];
      _isActive = category['isActive'] ?? true;
      _showInMenu = category['showInMenu'] ?? true;
      _featuredCategory = category['isFeatured'] ?? false;
      _uploadedIconUrl = category['iconUrl'];
    } else if (widget.parentCategory != null) {
      // Creating subcategory
      _selectedParentCategory = widget.parentCategory!['id'];
    }
  }

  void _loadData() {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    
    // Load categories
    provider.loadAllCategories().then((_) {
      setState(() {
        _availableParentCategories = provider.allCategories;
        _updateCurrentLevel();
      });
    });
  }

  void _updateCurrentLevel() {
    if (_selectedParentCategory == null) {
      _currentLevel = 0;
    } else {
      final parent = _availableParentCategories.firstWhere(
        (cat) => cat['id'] == _selectedParentCategory,
        orElse: () => {'level': -1},
      );
      _currentLevel = (parent['level'] ?? -1) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.editingCategory != null
              ? 'Edit Category'
              : 'Create Category',
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        actions: [
          _buildActionButtons(),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
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
                      // const SizedBox(height: 32),
                      // _buildHierarchySection(),
                      // const SizedBox(height: 32),
                      // _buildDisplaySettingsSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          Consumer<CategoryProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: provider.isLoading ? null : _saveCategory,
                child: provider.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.editingCategory != null ? 'Update' : 'Create'),
              );
            },
          ),
        ],
      ),
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

        // Category Icon Picker
        Row(
          children: [
            _uploadedIconUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.network(
                        _uploadedIconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image, 
                          color: AppColors.error,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.image, color: AppColors.textMedium),
                  ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickIconImage,
              icon: _isUploading 
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload, size: 18),
              label: Text(_uploadedIconUrl == null ? 'Upload Icon' : 'Change Icon'),
            ),
            if (_uploadedIconUrl != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                tooltip: 'Remove Icon',
                onPressed: () => setState(() => _uploadedIconUrl = null),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter category name',
            prefixIcon: Icon(Icons.category),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Category name is required';
            }
            if (value.length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // TextFormField(
        //   controller: _descriptionController,
        //   maxLines: 3,
        //   decoration: const InputDecoration(
        //     labelText: 'Description',
        //     hintText: 'Provide a brief description...',
        //     prefixIcon: Icon(Icons.description),
        //     alignLabelWithHint: true,
        //   ),
        // ),
        // const SizedBox(height: 16),
        
        TextFormField(
          controller: _orderController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Display Order',
            hintText: '0',
            helperText: 'Lower numbers appear first',
            prefixIcon: Icon(Icons.sort),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final order = int.tryParse(value);
              if (order == null) {
                return 'Please enter a valid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

 

  void _saveCategory() async {
    // if (!_formKey.currentState!.validate()) {
    //   return;
    // }

    try {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      
      final categoryData = {
        'name': _nameController.text.trim(),
        'description':'',
        'parentId': _selectedParentCategory,
        'order': int.tryParse(_orderController.text) ?? 0,
        'level': _currentLevel,
        'isActive': true,
        'showInMenu': true,
        'isFeatured': _featuredCategory,
        'iconUrl': _uploadedIconUrl,
      };

      if (widget.editingCategory != null) {
        await provider.updateCategory(widget.editingCategory!['id'], categoryData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await provider.createCategory(categoryData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving category: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Image picker for web using dart:html
  void _pickIconImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();
      
      uploadInput.onChange.listen((event) async {
        final file = uploadInput.files?.first;
        if (file != null) {
          // Validate file size (max 5MB)
          if (file.size > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image size must be less than 5MB'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            setState(() {
              _isUploading = false;
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
              _isUploading = false;
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
              final fileName = 'category_icon_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
              final url = await provider.uploadImage(bytes, fileName);
              
              if (mounted) {
                setState(() {
                  _uploadedIconUrl = url.contains('?')
                      ? '$url&cb=${DateTime.now().millisecondsSinceEpoch}'
                      : '$url?cb=${DateTime.now().millisecondsSinceEpoch}';
                  _isUploading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Icon uploaded successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              print('Upload error: ${e.toString()}');
              if (mounted) {
                setState(() {
                  _isUploading = false;
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
                _isUploading = false;
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
            _isUploading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
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

  @override
  void dispose() {
    _nameController.dispose();
    // _descriptionController.dispose();
    _orderController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
