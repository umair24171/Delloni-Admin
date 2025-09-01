import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CitiesManagementPage extends StatefulWidget {
  const CitiesManagementPage({Key? key}) : super(key: key);

  @override
  State<CitiesManagementPage> createState() => _CitiesManagementPageState();
}

class _CitiesManagementPageState extends State<CitiesManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for forms
  final _cityNameController = TextEditingController();
  final _cityDescriptionController = TextEditingController();
  final _districtNameController = TextEditingController();
  final _districtDescriptionController = TextEditingController();

  // State variables
  bool _isLoading = false;
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  String? _selectedCityForDistrict;
  Map<String, dynamic>? _editingCity;
  Map<String, dynamic>? _editingDistrict;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCities();
    _loadDistricts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cityNameController.dispose();
    _cityDescriptionController.dispose();
    _districtNameController.dispose();
    _districtDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      setState(() => _isLoading = true);
      
      final snapshot = await _firestore
          .collection('cities')
          .orderBy('name')
          .get();

      _cities = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading cities: $e');
    }
  }

  Future<void> _loadDistricts() async {
    try {
      final snapshot = await _firestore
          .collection('districts')
          .orderBy('name')
          .get();

      _districts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Error loading districts: $e');
    }
  }

  Future<void> _addOrUpdateCity() async {
    if (_cityNameController.text.trim().isEmpty) {
      _showErrorSnackBar('City name is required');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final cityData = {
        'name': _cityNameController.text.trim(),
        'description': _cityDescriptionController.text.trim(),
        'isActive': true,
        'createdAt': _editingCity == null ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove null values
      cityData.removeWhere((key, value) => value == null);

      if (_editingCity == null) {
        // Add new city
        await _firestore.collection('cities').add(cityData);
        _showSuccessSnackBar('City added successfully');
      } else {
        // Update existing city
        await _firestore
            .collection('cities')
            .doc(_editingCity!['id'])
            .update(cityData);
        _showSuccessSnackBar('City updated successfully');
      }

      _clearCityForm();
      _loadCities();
    } catch (e) {
      _showErrorSnackBar('Error saving city: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addOrUpdateDistrict() async {
    if (_districtNameController.text.trim().isEmpty) {
      _showErrorSnackBar('District name is required');
      return;
    }

    if (_selectedCityForDistrict == null) {
      _showErrorSnackBar('Please select a city');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final districtData = {
        'name': _districtNameController.text.trim(),
        'description': _districtDescriptionController.text.trim(),
        'cityId': _selectedCityForDistrict!,
        'isActive': true,
        'createdAt': _editingDistrict == null ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove null values
      districtData.removeWhere((key, value) => value == null);

      if (_editingDistrict == null) {
        // Add new district
        await _firestore.collection('districts').add(districtData);
        _showSuccessSnackBar('District added successfully');
      } else {
        // Update existing district
        await _firestore
            .collection('districts')
            .doc(_editingDistrict!['id'])
            .update(districtData);
        _showSuccessSnackBar('District updated successfully');
      }

      _clearDistrictForm();
      _loadDistricts();
    } catch (e) {
      _showErrorSnackBar('Error saving district: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCity(String cityId, String cityName) async {
    final confirmed = await _showConfirmationDialog(
      'Delete City',
      'Are you sure you want to delete "$cityName"? This will also delete all districts in this city.',
    );

    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);

      // Delete all districts in this city first
      final districtsSnapshot = await _firestore
          .collection('districts')
          .where('cityId', isEqualTo: cityId)
          .get();

      final batch = _firestore.batch();
      
      for (var doc in districtsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the city
      batch.delete(_firestore.collection('cities').doc(cityId));

      await batch.commit();

      _showSuccessSnackBar('City and its districts deleted successfully');
      _loadCities();
      _loadDistricts();
    } catch (e) {
      _showErrorSnackBar('Error deleting city: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDistrict(String districtId, String districtName) async {
    final confirmed = await _showConfirmationDialog(
      'Delete District',
      'Are you sure you want to delete "$districtName"?',
    );

    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);

      await _firestore.collection('districts').doc(districtId).delete();

      _showSuccessSnackBar('District deleted successfully');
      _loadDistricts();
    } catch (e) {
      _showErrorSnackBar('Error deleting district: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCityStatus(String cityId, bool currentStatus) async {
    try {
      await _firestore.collection('cities').doc(cityId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar(
        !currentStatus ? 'City activated' : 'City deactivated',
      );
      _loadCities();
    } catch (e) {
      _showErrorSnackBar('Error updating city status: $e');
    }
  }

  Future<void> _toggleDistrictStatus(String districtId, bool currentStatus) async {
    try {
      await _firestore.collection('districts').doc(districtId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar(
        !currentStatus ? 'District activated' : 'District deactivated',
      );
      _loadDistricts();
    } catch (e) {
      _showErrorSnackBar('Error updating district status: $e');
    }
  }

  void _editCity(Map<String, dynamic> city) {
    setState(() {
      _editingCity = city;
      _cityNameController.text = city['name'] ?? '';
      _cityDescriptionController.text = city['description'] ?? '';
    });
  }

  void _editDistrict(Map<String, dynamic> district) {
    setState(() {
      _editingDistrict = district;
      _districtNameController.text = district['name'] ?? '';
      _districtDescriptionController.text = district['description'] ?? '';
      _selectedCityForDistrict = district['cityId'];
    });
  }

  void _clearCityForm() {
    _cityNameController.clear();
    _cityDescriptionController.clear();
    setState(() => _editingCity = null);
  }

  void _clearDistrictForm() {
    _districtNameController.clear();
    _districtDescriptionController.clear();
    setState(() {
      _editingDistrict = null;
      _selectedCityForDistrict = null;
    });
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getCityNameById(String cityId) {
    final city = _cities.firstWhere(
      (city) => city['id'] == cityId,
      orElse: () => {'name': 'Unknown City'},
    );
    return city['name'] ?? 'Unknown City';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Cities & Districts Management',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Cities (${_cities.length})',
              icon: Icon(Icons.location_city),
            ),
            Tab(
              text: 'Districts (${_districts.length})',
              icon: Icon(Icons.location_on),
            ),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCitiesTab(),
                _buildDistrictsTab(),
              ],
            ),
    );
  }

  Widget _buildCitiesTab() {
    return Row(
      children: [
        // Cities List
        Expanded(
          flex: 2,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_city, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Cities List',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: _cities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_city, 
                                  size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'No cities added yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _cities.length,
                          itemBuilder: (context, index) {
                            final city = _cities[index];
                            return _buildCityListItem(city);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // City Form
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.add_location, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        _editingCity == null ? 'Add New City' : 'Edit City',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_editingCity != null) ...[
                        Spacer(),
                        IconButton(
                          onPressed: _clearCityForm,
                          icon: Icon(Icons.close, color: Colors.red),
                          tooltip: 'Cancel Edit',
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _cityNameController,
                          decoration: InputDecoration(
                            labelText: 'City Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _cityDescriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addOrUpdateCity,
                          icon: Icon(_editingCity == null ? Icons.add : Icons.update),
                          label: Text(_editingCity == null ? 'Add City' : 'Update City'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictsTab() {
    return Row(
      children: [
        // Districts List
        Expanded(
          flex: 2,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Districts List',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: _districts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, 
                                  size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'No districts added yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _districts.length,
                          itemBuilder: (context, index) {
                            final district = _districts[index];
                            return _buildDistrictListItem(district);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // District Form
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.add_location_alt, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        _editingDistrict == null ? 'Add New District' : 'Edit District',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_editingDistrict != null) ...[
                        Spacer(),
                        IconButton(
                          onPressed: _clearDistrictForm,
                          icon: Icon(Icons.close, color: Colors.red),
                          tooltip: 'Cancel Edit',
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCityForDistrict,
                          decoration: InputDecoration(
                            labelText: 'Select City *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          items: _cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city['id'],
                              child: Text(city['name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCityForDistrict = value);
                          },
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _districtNameController,
                          decoration: InputDecoration(
                            labelText: 'District Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _districtDescriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addOrUpdateDistrict,
                          icon: Icon(_editingDistrict == null ? Icons.add : Icons.update),
                          label: Text(_editingDistrict == null ? 'Add District' : 'Update District'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityListItem(Map<String, dynamic> city) {
    final isActive = city['isActive'] ?? true;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? Colors.white : Colors.grey[100],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue[100] : Colors.grey[400],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_city,
            color: isActive ? Colors.blue : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          city['name'] ?? 'Unknown City',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: city['description'] != null && city['description'].isNotEmpty
            ? Text(
                city['description'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
            SizedBox(width: 8),
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editCity(city);
                    break;
                  case 'toggle':
                    _toggleCityStatus(city['id'], isActive);
                    break;
                  case 'delete':
                    _deleteCity(city['id'], city['name'] ?? 'Unknown');
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text(isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictListItem(Map<String, dynamic> district) {
    final isActive = district['isActive'] ?? true;
    final cityName = _getCityNameById(district['cityId'] ?? '');
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? Colors.white : Colors.grey[100],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.orange[100] : Colors.grey[400],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on,
            color: isActive ? Colors.orange : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          district['name'] ?? 'Unknown District',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'City: $cityName',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (district['description'] != null && district['description'].isNotEmpty)
              Text(
                district['description'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
            SizedBox(width: 8),
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editDistrict(district);
                    break;
                  case 'toggle':
                    _toggleDistrictStatus(district['id'], isActive);
                    break;
                  case 'delete':
                    _deleteDistrict(district['id'], district['name'] ?? 'Unknown');
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text(isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}