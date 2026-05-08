import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflow_core/sqflow_core.dart' hide Column;
import 'package:sqflow_example/models/user.dart';
import 'package:uuid/uuid.dart';

class ValidationDemoPage extends StatefulWidget {
  const ValidationDemoPage({super.key});

  @override
  State<ValidationDemoPage> createState() => _ValidationDemoPageState();
}

class _ValidationDemoPageState extends State<ValidationDemoPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _gender = 'M';
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  String? _errorType;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _successMessage = null;
      _errorMessage = null;
      _errorType = null;
      _isLoading = true;
    });

    final user = User(
      id: const Uuid().v4(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      birthDate: _birthDateCtrl.text.trim().isEmpty
          ? null
          : _birthDateCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      gender: _gender,
      password: 'demo_password',
    );

    try {
      await Users.insert(user);
      setState(() {
        _successMessage =
            'User "${user.firstName} ${user.lastName}" created successfully!';
        _isLoading = false;
      });
    } on SqflowJSONValidatorException catch (e) {
      setState(() {
        _errorType = 'JSON Validation (Dart-side)';
        _errorMessage = 'Constraint: ${e.constraint}\n${e.message}';
        _isLoading = false;
      });
    } on SqflowCHECKValidatorException catch (e) {
      setState(() {
        _errorType = 'CHECK Constraint (Dart-side)';
        _errorMessage = 'Constraint: ${e.constraint}\n${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorType = 'Database Error';
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _fillValid() {
    _firstNameCtrl.text = 'Alice';
    _lastNameCtrl.text = 'Smith';
    _emailCtrl.text =
        'alice${DateTime.now().millisecondsSinceEpoch}@example.com';
    _phoneCtrl.text = '+359888123456';
    _birthDateCtrl.text = '1990-05-21';
    _cityCtrl.text = 'Sofia';
    _countryCtrl.text = 'Bulgaria';
    _addressCtrl.text = '123 Main Street';
    setState(() => _gender = 'F');
  }

  void _fillInvalidJson() {
    _firstNameCtrl.text = 'Alice';
    _lastNameCtrl.text = 'Smith';
    _emailCtrl.text =
        'NOT-AN-EMAIL'; // EmailValidator → SqflowJSONValidatorException
    _phoneCtrl.text = '+359888123456';
    _birthDateCtrl.text = '1990-05-21';
    _cityCtrl.text = 'Sofia';
    _countryCtrl.text = 'Bulgaria';
    _addressCtrl.text = '123 Main Street';
    setState(() => _gender = 'F');
  }

  void _fillInvalidCheck() {
    _firstNameCtrl.text =
        'A'; // LengthValidator(min:2) → SqflowCHECKValidatorException
    _lastNameCtrl.text = 'Smith';
    _emailCtrl.text = 'alice2@example.com';
    _phoneCtrl.text = '+359888999000';
    _birthDateCtrl.text = '1990-05-21';
    _cityCtrl.text = 'Sofia';
    _countryCtrl.text = 'Bulgaria';
    _addressCtrl.text = '123 Main Street';
    setState(() => _gender = 'M');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoBanner(),
                const SizedBox(height: 20),
                _buildQuickFillRow(),
                const SizedBox(height: 20),
                _buildForm(),
                const SizedBox(height: 20),
                _buildResultPanel(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F1A),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Validation Demo',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white)),
            Text('IJsonValidator · ICheckValidator · Exceptions',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4FACFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.verified_user,
                  size: 64, color: Colors.white.withOpacity(0.15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sqflow validates data on the Dart side before any DB write. '
              'Use the buttons below to trigger different exception types.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFillRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Fill',
            style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white38,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('✅ Valid Data', const Color(0xFF00C896), _fillValid),
            _chip('🔴 Bad Email (JSON)', const Color(0xFF4FACFE),
                _fillInvalidJson),
            _chip('🔴 Short Name (CHECK)', const Color(0xFFFF6B6B),
                _fillInvalidCheck),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Identity'),
          Row(
            children: [
              Expanded(
                  child: _field('First Name', _firstNameCtrl, hint: 'Alice')),
              const SizedBox(width: 12),
              Expanded(
                  child: _field('Last Name', _lastNameCtrl, hint: 'Smith')),
            ],
          ),
          const SizedBox(height: 12),
          _sectionLabel('Contact'),
          _field('Email', _emailCtrl,
              hint: 'alice@example.com',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field('Phone', _phoneCtrl,
              hint: '+359888123456', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _sectionLabel('Profile'),
          _field('Birth Date', _birthDateCtrl, hint: '1990-05-21'),
          const SizedBox(height: 12),
          _buildGenderPicker(),
          const SizedBox(height: 12),
          _sectionLabel('Location'),
          _field('City', _cityCtrl, hint: 'Sofia'),
          const SizedBox(height: 12),
          _field('Country', _countryCtrl, hint: 'Bulgaria'),
          const SizedBox(height: 12),
          _field('Address', _addressCtrl, hint: '123 Main Street'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_alt_rounded),
              label: Text(_isLoading ? 'Creating...' : 'Create User'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildGenderPicker() {
    final genders = ['M', 'F', 'Other'];
    final labels = {'M': 'Male ♂', 'F': 'Female ♀', 'Other': 'Other'};
    return Row(
      children: genders.map((g) {
        final selected = _gender == g;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Container(
              margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.1),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(labels[g]!,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? const Color(0xFF6C63FF)
                            : Colors.white54)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultPanel() {
    if (_errorMessage != null) {
      final isJson = _errorType!.contains('JSON');
      final color = isJson ? const Color(0xFF4FACFE) : const Color(0xFFFF6B6B);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.error_outline, color: color, size: 18),
              const SizedBox(width: 8),
              Text(_errorType!,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMessage!,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, color: Colors.white70, height: 1.6)),
            ),
          ],
        ),
      );
    }

    if (_successMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF00C896).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF00C896).withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF00C896), size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_successMessage!,
                  style: GoogleFonts.inter(
                      color: const Color(0xFF00C896), fontSize: 13))),
        ]),
      );
    }

    return const SizedBox.shrink();
  }
}
