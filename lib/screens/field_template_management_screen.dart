import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/category_field_templates.dart';
import 'package:delloniweb/providers/category_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/create_field_template_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// field_template_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_field_template_screen.dart';
class CategoryFieldManagementScreen extends StatefulWidget {
  const CategoryFieldManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryFieldManagementScreen> createState() => _CategoryFieldManagementScreenState();
}

class _CategoryFieldManagementScreenState extends State<CategoryFieldManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    provider.loadAllCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Category Field Management'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        actions: [
          Consumer<CategoryProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : _loadCategories,
              );
            },
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 16),
                    SizedBox(width: 8),
                    Text('Field Statistics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 16),
                    SizedBox(width: 8),
                    Text('Export All Configs'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'statistics':
                  _showGlobalStatistics();
                  break;
                case 'export_all':
                  _exportAllConfigurations();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with search and create button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateFieldTemplateScreen(),
                      ),
                    ).then((_) => _loadCategories()); // Refresh after return
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Fields to Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Categories list
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading categories...'),
                      ],
                    ),
                  );
                }
                
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Error: ${provider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            _loadCategories();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                // Apply search filter
                final categories = _searchQuery.isEmpty 
                    ? provider.allCategories
                    : provider.searchCategories(_searchQuery);
                
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category, size: 48, color: AppColors.textMedium),
                        const SizedBox(height: 16),
                        Text(_searchQuery.isEmpty 
                            ? 'No categories found'
                            : 'No categories match your search'),
                        const SizedBox(height: 16),
                        if (_searchQuery.isEmpty) ...[
                          const Text(
                            'Create categories first in the Category Management section',
                            style: TextStyle(color: AppColors.textMedium),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(category, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, CategoryProvider provider) {
    final configuredFields = List<Map<String, dynamic>>.from(
      category['configuredFields'] ?? []
    );
    final hasCustomFields = category['hasCustomFields'] ?? false;
    final isActive = category['isActive'] ?? true;
    final fieldStats = provider.getCategoryFieldStatistics(category['id']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: category['iconUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            category['iconUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.category,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.category,
                          size: 24,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category['name'] ?? 'Unknown Category',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: isActive ? AppColors.success : AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (category['levelType'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category['levelType'],
                                style: const TextStyle(
                                  color: AppColors.info,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasCustomFields 
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.border.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              hasCustomFields 
                                  ? '${configuredFields.length} fields'
                                  : 'No fields',
                              style: TextStyle(
                                color: hasCustomFields 
                                    ? AppColors.primary 
                                    : AppColors.textMedium,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (hasCustomFields && configuredFields.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Configured Fields:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              
              // Field statistics row
              Row(
                children: [
                  _buildStatChip('Total', fieldStats['totalFields'].toString(), AppColors.primary),
                  const SizedBox(width: 8),
                  _buildStatChip('Required', fieldStats['requiredFields'].toString(), AppColors.error),
                  const SizedBox(width: 8),
                  _buildStatChip('Optional', fieldStats['optionalFields'].toString(), AppColors.success),
                ],
              ),
              const SizedBox(height: 8),
              
              // Fields preview
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: configuredFields.take(5).map((field) {
                  final isRequired = field['required'] == true;
                  final fieldType = field['type'] ?? 'text';
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRequired 
                          ? AppColors.error.withOpacity(0.1) 
                          : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isRequired 
                            ? AppColors.error.withOpacity(0.3) 
                            : AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForFieldType(fieldType),
                          size: 12,
                          color: isRequired ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          field['label'] ?? field['name'] ?? 'Unknown Field',
                          style: TextStyle(
                            fontSize: 11,
                            color: isRequired ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (configuredFields.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${configuredFields.length - 5} more fields',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMedium,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textMedium, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'No custom fields configured for this category',
                      style: TextStyle(color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateFieldTemplateScreen(
                          selectedCategoryId: category['id'],
                        ),
                      ),
                    ).then((_) => _loadCategories());
                  },
                  icon: Icon(
                    hasCustomFields ? Icons.edit : Icons.add,
                    size: 16,
                  ),
                  label: Text(hasCustomFields ? 'Edit Fields' : 'Add Fields'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasCustomFields) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showFieldList(category),
                    icon: const Icon(Icons.list, size: 16),
                    label: const Text('View All'),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16),
                            SizedBox(width: 8),
                            Text('Copy Fields'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 16),
                            SizedBox(width: 8),
                            Text('Export Config'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(Icons.upload, size: 16),
                            SizedBox(width: 8),
                            Text('Import Config'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Clear Fields', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'copy':
                          _showCopyFieldsDialog(category, provider);
                          break;
                        case 'export':
                          _exportCategoryConfig(category, provider);
                          break;
                        case 'import':
                          _importCategoryConfig(category, provider);
                          break;
                        case 'clear':
                          _showClearFieldsDialog(category, provider);
                          break;
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFieldType(String fieldType) {
    switch (fieldType) {
      case 'text': return Icons.text_fields;
      case 'textarea': return Icons.notes;
      case 'number': return Icons.numbers;
      case 'dropdown': return Icons.arrow_drop_down;
      case 'boolean': return Icons.toggle_on;
      case 'radio': return Icons.radio_button_checked;
      case 'date': return Icons.calendar_today;
      case 'time': return Icons.access_time;
      case 'datetime': return Icons.date_range;
      case 'file': return Icons.attach_file;
      case 'image': return Icons.image;
      case 'color': return Icons.palette;
      case 'color_picker': return Icons.color_lens;
      default: return Icons.input;
    }
  }

  void _showFieldList(Map<String, dynamic> category) {
    final configuredFields = List<Map<String, dynamic>>.from(
      category['configuredFields'] ?? []
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Fields in ${category['name']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: configuredFields.length,
                  itemBuilder: (context, index) {
                    final field = configuredFields[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(_getIconForFieldType(field['type'] ?? 'text')),
                        title: Text(field['label'] ?? field['name'] ?? 'Unknown'),
                        subtitle: Text('Type: ${field['type']} • ${field['required'] == true ? 'Required' : 'Optional'}'),
                        trailing: field['required'] == true
                            ? const Icon(Icons.star, color: AppColors.error, size: 16)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCopyFieldsDialog(Map<String, dynamic> sourceCategory, CategoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy Fields from ${sourceCategory['name']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select target category:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: provider.allCategories
                    .where((cat) => cat['id'] != sourceCategory['id'] && cat['isActive'] == true)
                    .map((category) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: category,
                    child: Text(category['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (targetCategory) async {
                  if (targetCategory != null) {
                    Navigator.pop(context);
                    try {
                      await provider.copyFieldsBetweenCategories(
                        sourceCategory['id'],
                        targetCategory['id'],
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fields copied to ${targetCategory['name']}'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error copying fields: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearFieldsDialog(Map<String, dynamic> category, CategoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Fields'),
        content: Text('Are you sure you want to remove all fields from "${category['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.updateCategoryWithFields(category['id'], {
                  ...category,
                  'configuredFields': [],
                  'hasCustomFields': false,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All fields cleared successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing fields: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _exportCategoryConfig(Map<String, dynamic> category, CategoryProvider provider) {
    try {
      final config = provider.exportCategoryFieldConfig(category['id']);
      // In a real app, you would save this to a file or clipboard
      // For demo purposes, we'll just show it in a dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: 600,
            height: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      config.toString(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting configuration: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _importCategoryConfig(Map<String, dynamic> category, CategoryProvider provider) {
    // In a real app, you would allow file upload or JSON input
    // For demo purposes, show a simple text input dialog
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Paste configuration JSON',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Parse and import the configuration
                        // This is a simplified version - in a real app you'd have proper JSON parsing
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Import functionality would be implemented here'),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error importing configuration: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    child: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGlobalStatistics() {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    final stats = provider.getGlobalFieldUsageStatistics();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Global Field Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildStatRow('Total Categories', stats['totalCategories'].toString()),
              _buildStatRow('Categories with Fields', stats['categoriesWithFields'].toString()),
              _buildStatRow('Categories without Fields', stats['categoriesWithoutFields'].toString()),
              _buildStatRow('Total Fields', stats['totalFields'].toString()),
              _buildStatRow('Required Fields', stats['totalRequiredFields'].toString()),
              _buildStatRow('Optional Fields', stats['totalOptionalFields'].toString()),
              _buildStatRow('Average Fields per Category', stats['averageFieldsPerCategory'].toString()),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _exportAllConfigurations() {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    final categoriesWithFields = provider.getCategoriesWithCustomFields();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Would export ${categoriesWithFields.length} category configurations'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}