import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../auth/state/auth_controller.dart';
import '../../appointments/data/booking_draft.dart'
    show parseAvailableWeekdays, parseSlotMinutes;
import '../../doctors/state/doctor_providers.dart';
import '../state/profile_providers.dart';
import '../../../core/widgets/user_avatar.dart';

const _genderOptions = ['Male', 'Female', 'Other'];
const _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const _maritalStatusOptions = [
  'Single',
  'Married',
  'Divorced',
  'Widowed',
  'Other',
];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _bioController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _feeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _insuranceProviderController = TextEditingController();
  final _insuranceMemberNoController = TextEditingController();
  String _email = '';
  // Doctor-only professional details.
  final _qualificationsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _treatmentsController = TextEditingController();
  String? _specialization;
  Set<int> _workDays = {1, 2, 3, 4, 5};
  TimeOfDay _workStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _workEnd = const TimeOfDay(hour: 17, minute: 0);
  bool _availableToday = false;
  DateTime? _dateOfBirth;
  bool _initialized = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String _role = 'patient';
  String? _imageUrl;
  String? _gender;
  String? _bloodgroup;
  String? _maritalStatus;

  /// Matches a stored value against a fixed dropdown option list, ignoring
  /// case — falls back to null (unselected) for legacy free-text values
  /// that predate these dropdowns, since a DropdownButtonFormField throws
  /// if its value isn't exactly one of its items.
  String? _matchOption(String? stored, List<String> options) {
    if (stored == null) return null;
    for (final option in options) {
      if (option.toLowerCase() == stored.toLowerCase()) return option;
    }
    return null;
  }

  void _initFromUser() {
    if (_initialized) return;
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    _initialized = true;
    _role = user.role;
    _imageUrl = user.image;
    _nameController.text = user.name;
    _gender = _matchOption(user.gender, _genderOptions);
    _bloodgroup = _matchOption(user.bloodgroup, _bloodGroupOptions);
    _maritalStatus = _matchOption(user.maritalStatus, _maritalStatusOptions);
    _ageController.text = user.age ?? '';
    _emergencyNameController.text = user.emergencyContactName ?? '';
    _emergencyPhoneController.text = user.emergencyContactPhone ?? '';
    _emergencyRelationController.text = user.emergencyContactRelation ?? '';
    _bioController.text = user.bio ?? '';
    _hospitalNameController.text = user.hospitalName ?? '';
    _hospitalAddressController.text = user.hospitalAddress ?? '';
    _feeController.text = user.consultationFee?.toString() ?? '';
    _email = user.email;
    _specialization = user.specialization;
    _qualificationsController.text = user.qualifications ?? '';
    _experienceController.text = user.yearsOfExperience?.toString() ?? '';
    _treatmentsController.text = user.treatments ?? '';
    _availableToday = user.availableToday;
    final days = parseAvailableWeekdays(user.availabilityDays);
    if (days != null && days.isNotEmpty) _workDays = days;
    if (user.availabilityHours != null) {
      final slots = parseSlotMinutes(user.availabilityHours);
      if (slots.isNotEmpty) {
        _workStart = TimeOfDay(
          hour: slots.first ~/ 60,
          minute: slots.first % 60,
        );
        final end = slots.last + 30;
        _workEnd = TimeOfDay(hour: end ~/ 60, minute: end % 60);
      }
    }
    _phoneController.text = user.phoneNumber ?? '';
    _addressController.text = user.address ?? '';
    _insuranceProviderController.text = user.insuranceProvider ?? '';
    _insuranceMemberNoController.text = user.insuranceMemberNo ?? '';
    _dateOfBirth = DateTime.tryParse(user.dateOfBirth ?? '');
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked == null) return;
    var age = now.year - picked.year;
    if (now.month < picked.month ||
        (now.month == picked.month && now.day < picked.day)) {
      age--;
    }
    setState(() {
      _dateOfBirth = picked;
      _ageController.text = '$age';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _bioController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _feeController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _treatmentsController.dispose();
    _addressController.dispose();
    _insuranceProviderController.dispose();
    _insuranceMemberNoController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref
          .read(uploadRepositoryProvider)
          .uploadFile(picked.path);
      await ref.read(profileRepositoryProvider).updateMe({'image': url});
      ref.invalidate(authControllerProvider);
      if (mounted) setState(() => _imageUrl = url);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Same text format the booking screen parses (e.g. "Mon, Wed, Fri").
  String _formatDays() => [
    for (var d = 1; d <= 7; d++)
      if (_workDays.contains(d)) _dayNames[d - 1],
  ].join(', ');

  String _formatTime(TimeOfDay t) =>
      DateFormat('h:mm a').format(DateTime(2000, 1, 1, t.hour, t.minute));

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _workStart : _workEnd,
    );
    if (picked == null) return;
    setState(() => start ? _workStart = picked : _workEnd = picked);
  }

  Future<void> _save() async {
    if (_role == 'doctor') {
      final startMin = _workStart.hour * 60 + _workStart.minute;
      final endMin = _workEnd.hour * 60 + _workEnd.minute;
      if (_workDays.isEmpty || endMin - startMin < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pick at least one working day, and working hours that are at least 30 minutes long.',
            ),
          ),
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateMe({
        'name': _nameController.text.trim(),
        'gender': _gender,
        'bloodgroup': _bloodgroup,
        'maritalStatus': _maritalStatus,
        'age': _ageController.text.trim(),
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim(),
        'emergencyContactRelation': _emergencyRelationController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        if (_role != 'doctor') ...{
          'address': _addressController.text.trim(),
          'insuranceProvider': _insuranceProviderController.text.trim(),
          'insuranceMemberNo': _insuranceMemberNoController.text.trim(),
          if (_dateOfBirth != null)
            'dateOfBirth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        },
        if (_role == 'doctor') ...{
          'bio': _bioController.text.trim(),
          'hospitalName': _hospitalNameController.text.trim(),
          'hospitalAddress': _hospitalAddressController.text.trim(),
          'consultationFee': int.tryParse(_feeController.text.trim()),
          'specialization': ?_specialization,
          'qualifications': _qualificationsController.text.trim(),
          'yearsOfExperience': int.tryParse(_experienceController.text.trim()),
          'treatments': _treatmentsController.text.trim(),
          'availabilityDays': _formatDays(),
          'availabilityHours':
              '${_formatTime(_workStart)} - ${_formatTime(_workEnd)}',
          'availableToday': _availableToday,
        },
      });
      ref.invalidate(authControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromUser();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                UserAvatar(
                  url: _imageUrl,
                  kind: AvatarKind.self,
                  radius: 48,
                  child: _uploadingPhoto
                      ? const CircularProgressIndicator()
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _uploadingPhoto ? null : _changePhoto,
                    borderRadius: BorderRadius.circular(kCardRadius),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name*'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _email,
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              helperText: 'Contact support to change your sign-in email.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+256 7XX XXX XXX',
              helperText: 'Used for appointment reminders and 2FA.',
            ),
          ),
          const SizedBox(height: 16),
          if (_role == 'doctor') ..._doctorFields() else ..._patientFields(),
          const SizedBox(height: 16),
          const Text(
            'Emergency Contact',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emergencyNameController,
            decoration: const InputDecoration(labelText: 'Contact Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emergencyRelationController,
            decoration: const InputDecoration(labelText: 'Relationship'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  List<Widget> _patientFields() {
    return [
      DropdownButtonFormField<String>(
        initialValue: _gender,
        decoration: const InputDecoration(labelText: 'Gender'),
        items: _genderOptions
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (value) => setState(() => _gender = value),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _bloodgroup,
        decoration: const InputDecoration(labelText: 'Blood Group'),
        items: _bloodGroupOptions
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (value) => setState(() => _bloodgroup = value),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _maritalStatus,
        decoration: const InputDecoration(labelText: 'Marital Status'),
        items: _maritalStatusOptions
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (value) => setState(() => _maritalStatus = value),
      ),
      const SizedBox(height: 12),
      InkWell(
        onTap: _pickDateOfBirth,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
          ),
          child: Text(
            _dateOfBirth == null
                ? 'Select date'
                : DateFormat('d MMM yyyy').format(_dateOfBirth!),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Age'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _addressController,
        minLines: 1,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Home Address'),
      ),
      const SizedBox(height: 16),
      const Text('Insurance', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: _insuranceProviderController,
        decoration: const InputDecoration(
          labelText: 'Primary Insurance',
          hintText: 'e.g. Jubilee, AAR, UAP Old Mutual',
          helperText: 'Keep this updated to avoid billing issues.',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _insuranceMemberNoController,
        decoration: const InputDecoration(labelText: 'Member Number'),
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _doctorFields() {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final specialties = {
      for (final c in categories) c.name,
      ?_specialization,
    }.toList()..sort();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return [
      DropdownButtonFormField<String>(
        initialValue: _specialization,
        decoration: const InputDecoration(labelText: 'Specialization'),
        items: [
          for (final name in specialties)
            DropdownMenuItem(value: name, child: Text(name)),
        ],
        onChanged: (value) => setState(() => _specialization = value),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _qualificationsController,
        decoration: const InputDecoration(
          labelText: 'Qualifications',
          hintText: 'e.g. MBChB, MMed Paediatrics',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _experienceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Years of experience'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _treatmentsController,
        minLines: 1,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Conditions you treat',
          hintText: 'Separate with commas, e.g. Asthma, Malaria',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _bioController,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'About / Bio'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _hospitalNameController,
        decoration: const InputDecoration(labelText: 'Hospital Name'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _hospitalAddressController,
        decoration: const InputDecoration(labelText: 'Hospital Address'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _feeController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Consultation Fee (UGX)'),
      ),
      const SizedBox(height: 20),
      const Text('Availability', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(
        'Patients can only book the days and hours you set here.',
        style: TextStyle(color: muted, fontSize: 13),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var d = 1; d <= 7; d++)
            FilterChip(
              label: Text(_dayNames[d - 1]),
              selected: _workDays.contains(d),
              selectedColor: seedTeal,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _workDays.contains(d) ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (on) =>
                  setState(() => on ? _workDays.add(d) : _workDays.remove(d)),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.schedule, size: 18),
              label: Text('From ${_formatTime(_workStart)}'),
              onPressed: () => _pickTime(start: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.schedule, size: 18),
              label: Text('To ${_formatTime(_workEnd)}'),
              onPressed: () => _pickTime(start: false),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Available today'),
        subtitle: const Text('Shows an "Available today" badge to patients'),
        value: _availableToday,
        onChanged: (v) => setState(() => _availableToday = v),
      ),
      const SizedBox(height: 16),
    ];
  }
}
