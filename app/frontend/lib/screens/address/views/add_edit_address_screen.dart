import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/address/views/addresses_screen.dart';
import 'package:shop/route/api_service.dart'; // Import ApiService

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;
  final String? userAddressId;   // ID of row in user_addresses table (for edit)
  final String? addressId;       // ID of row in addresses table (for edit)

  const AddEditAddressScreen({
    super.key,
    this.address,
    this.userAddressId,
    this.addressId,
  });

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name ?? '');
    _streetController = TextEditingController(text: widget.address?.street ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _postalCodeController = TextEditingController(text: widget.address?.postalCode ?? '');
    _countryController = TextEditingController(text: widget.address?.country ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    try {
      final bool isEditing = widget.addressId != null && widget.userAddressId != null;

      final Map<String, dynamic> body = {
        'name': _nameController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
         'country': _countryController.text.trim(),
        'is_default': _isDefault,
      };

      if (isEditing) {
        // EDIT MODE
        // Pass addressId as well, assuming backend needs it to update the addresses table entry
        if (isEditing) {
          await ApiService.put('/users/addresses/${widget.userAddressId}', body: body);
        }

        await ApiService.put('/users/addresses/${widget.userAddressId}', body: body);
      } else {
        // ADD NEW MODE
        await ApiService.post('/users/addresses', body: body);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? "Address updated!" : "Address added!")),
      );
      Navigator.pop(context, true); // success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Address" : "Add New Address"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name (Home, Work, etc.)'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: defaultPadding),
              TextFormField(controller: _streetController, decoration: const InputDecoration(labelText: 'Street Address'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: defaultPadding),
              TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: defaultPadding),
              TextFormField(controller: _postalCodeController, decoration: const InputDecoration(labelText: 'Postal Code'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: defaultPadding),
              TextFormField(controller: _countryController, decoration: const InputDecoration(labelText: 'Country'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: defaultPadding),
              CheckboxListTile(
                title: const Text("Set as default address"),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val!),
              ),
              const SizedBox(height: defaultPadding * 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  child: Text(isEditing ? "Update Address" : "Save Address"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
