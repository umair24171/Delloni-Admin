import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/banner_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
class CreateBannerScreen extends StatefulWidget {
  const CreateBannerScreen({Key? key}) : super(key: key);

  @override
  State<CreateBannerScreen> createState() => _CreateBannerScreenState();
}

class _CreateBannerScreenState extends State<CreateBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clickUrlController = TextEditingController();
  final _priorityController = TextEditingController();
  
  // Form data
  String? _selectedType;
  String? _selectedPosition;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  // Banner types
  final List<String> _bannerTypes = [
    'Hero',
    'Promotional',
    'Category',
    'Product',
    'Seasonal',
    'Brand',
  ];

  // Banner positions
  final List<String> _bannerPositions = [
    'Top Header',
    'Hero Section',
    'Middle Content',
    'Sidebar',
    'Footer',
    'Popup',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _clickUrlController.dispose();
    _priorityController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                        Icons.add_photo_alternate_outlined,
                        size: 28,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Create New Banner',
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
                                  _buildDisplaySettingsSection(),
                                  const SizedBox(height: 32),
                                  _buildSchedulingSection(),
                                  const SizedBox(height: 32),
                                  _buildAdvancedSettingsSection(),
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
          
          // Image Upload and Preview Panel
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
        OutlinedButton.icon(
          onPressed: _saveDraft,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save Draft'),
        ),
        const SizedBox(width: 12),
        Consumer<BannerProvider>(
          builder: (context, provider, child) {
            return ElevatedButton.icon(
              onPressed: provider.isLoading ? null : _createBanner,
              icon: provider.isLoading 
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_outlined, size: 18),
              label: Text(provider.isLoading ? 'Creating...' : 'Create Banner'),
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
          label: 'Banner Title',
          hint: 'Enter a descriptive title for your banner',
          required: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Banner title is required';
            }
            if (value.length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Type and Position Row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Banner Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _bannerTypes.map((type) {
                  return DropdownMenuItem(
                    value: type.toLowerCase(),
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a banner type';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                items: _bannerPositions.map((position) {
                  return DropdownMenuItem(
                    value: position.toLowerCase().replaceAll(' ', '_'),
                    child: Text(position),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPosition = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select position';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Description
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Provide a brief description of this banner...',
            prefixIcon: Icon(Icons.description_outlined),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Description is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Click URL
        CustomTextField(
          controller: _clickUrlController,
          label: 'Click URL (Optional)',
          hint: 'https://example.com/landing-page',
          prefixIcon: Icons.link_outlined,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!Uri.tryParse(value)!.hasAbsolutePath == true) {
                return 'Please enter a valid URL';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDisplaySettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Display Settings',
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
                controller: _priorityController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Display Priority',
                  hintText: '1 = Highest Priority',
                  prefixIcon: Icon(Icons.priority_high_outlined),
                  helperText: 'Higher priority banners appear first',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final priority = int.tryParse(value);
                    if (priority == null || priority < 1 || priority > 100) {
                      return 'Priority must be between 1-100';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Banner Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Banner will be visible to users'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSchedulingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scheduling',
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
              child: InkWell(
                onTap: () => _selectDate(true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.event_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Start Date',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _startDate != null 
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Select start date (optional)',
                        style: TextStyle(
                          color: _startDate != null ? AppColors.textDark : AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.event_busy_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'End Date',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _endDate != null 
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Select end date (optional)',
                        style: TextStyle(
                          color: _endDate != null ? AppColors.textDark : AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'End date must be after start date',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advanced Settings',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Display Options',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Show on Mobile'),
                        subtitle: const Text('Display on mobile devices'),
                        value: true,
                        onChanged: (value) {
                          // Handle mobile display toggle
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Show on Desktop'),
                        subtitle: const Text('Display on desktop browsers'),
                        value: true,
                        onChanged: (value) {
                          // Handle desktop display toggle
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Auto-close after click'),
                  subtitle: const Text('Automatically hide banner after user clicks'),
                  value: false,
                  onChanged: (value) {
                    // Handle auto-close toggle
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
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
                Icons.image_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Banner Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (_uploadedImageUrl != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _uploadedImageUrl = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  tooltip: 'Remove Image',
                ),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Upload Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.background,
                      image: _uploadedImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_uploadedImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _uploadedImageUrl == null
                        ? Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isUploading ? null : _pickImage,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isUploading)
                                    const CircularProgressIndicator()
                                  else
                                    const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isUploading ? 'Uploading...' : 'Upload Banner Image',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Click to browse files',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Image Guidelines
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
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Image Guidelines',
                            style: TextStyle(
                              color: AppColors.info,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Recommended size: 1200x400px\n• Max file size: 5MB\n• Supported formats: JPG, PNG, WebP\n• Use high-quality images for best results',
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
        ),
      ],
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
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _clickUrlController.clear();
    _priorityController.clear();
    
    setState(() {
      _selectedType = null;
      _selectedPosition = null;
      _startDate = null;
      _endDate = null;
      _isActive = true;
      _uploadedImageUrl = null;
    });
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Banner saved as draft'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _createBanner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a banner image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_endDate != null && _startDate != null && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final adminDataProvider = Provider.of<BannerProvider>(context, listen: false);
      
      final bannerData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'position': _selectedPosition,
        'imageUrl': _uploadedImageUrl,
        'clickUrl': _clickUrlController.text.trim().isNotEmpty ? _clickUrlController.text.trim() : null,
        'priority': _priorityController.text.isNotEmpty ? int.parse(_priorityController.text) : 0,
        'isActive': _isActive,
        'startDate': _startDate,
        'endDate': _endDate,
        'showOnMobile': true,
        'showOnDesktop': true,
        'autoClose': false,
        'clickCount': 0,
        'impressionCount': 0,
      };

      await adminDataProvider.createBanner(bannerData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating banner: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _pickImage() async {
    setState(() {
      _isUploading = true;
    });

    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    
    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _uploadedImageUrl = reader.result as String;
            _isUploading = false;
          });
        });
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    });
    
    uploadInput.click();
  }

  void _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}