import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../utils/custom_snackbar.dart';
import '../../view_model/auth_controller/auth_controller.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _reasonDetailsController = TextEditingController();

  String? _selectedReason;
  bool _isConfirmed = false;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'No longer using the app',
    'Privacy / Security concerns',
    'Created a duplicate account',
    'Too many notifications',
    'Technical issues or bugs',
    'Other reason',
  ];

  @override
  void initState() {
    super.initState();
    final userData = _authController.userData.value;
    final phone = userData?['phone'] ?? '';
    final email = userData?['email'] ?? '';
    if (phone.toString().isNotEmpty && phone.toString() != 'N/A') {
      _contactController.text = phone.toString();
    } else if (email.toString().isNotEmpty && email.toString() != 'N/A') {
      _contactController.text = email.toString();
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    _reasonDetailsController.dispose();
    super.dispose();
  }

  void _submitDeleteRequest() async {
    if (_contactController.text.trim().isEmpty) {
      CustomSnackbar.show(
        title: 'Required Field',
        message: 'Please enter your registered Phone or Email.',
        isError: true,
      );
      return;
    }

    if (_selectedReason == null) {
      CustomSnackbar.show(
        title: 'Required Field',
        message: 'Please select a reason for account deletion.',
        isError: true,
      );
      return;
    }

    if (!_isConfirmed) {
      CustomSnackbar.show(
        title: 'Confirmation Required',
        message: 'Please check the confirmation box before submitting.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API request processing
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.pinkAccent,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Request Submitted",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your account deletion request has been received.\n\nYour account and associated data will be deleted within 24 to 48 hours. If you change your mind, please contact support before 24 hours.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.offAllNamed(AppRoutes.home); // Return to main page
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Delete Account",
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 800;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ⚠️ WARNING CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Important Warning",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "If you delete your account, you will not be able to use your account and services. All your watch history, watchlist, active subscriptions, and settings will be permanently deleted.\n\nYour account deletion request will be processed within 24 to 48 hours.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Account Deletion Request Form",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Please fill out the form below to proceed with deleting your account.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),

                    const SizedBox(height: 20),

                    /// REGISTERED PHONE / EMAIL FIELD
                    const Text(
                      "Registered Phone Number / Email",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contactController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter your phone or email",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        prefixIcon: const Icon(Icons.person, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.buttonColor),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// REASON DROPDOWN FIELD
                    const Text(
                      "Reason for Deleting Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E1E1E),
                      value: _selectedReason,
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Select reason",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        prefixIcon: const Icon(Icons.help_outline, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.buttonColor),
                        ),
                      ),
                      items: _reasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(
                            reason,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedReason = newValue;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    /// ADDITIONAL DETAILS FIELD
                    const Text(
                      "Additional Details / Feedback (Optional)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonDetailsController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Tell us more about why you are leaving...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.buttonColor),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CONFIRMATION CHECKBOX
                    Theme(
                      data: Theme.of(context).copyWith(
                        unselectedWidgetColor: Colors.white54,
                      ),
                      child: CheckboxListTile(
                        value: _isConfirmed,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.redAccent,
                        checkColor: Colors.white,
                        title: const Text(
                          "I understand that deleting my account is permanent and will take 24 to 48 hours to complete.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            _isConfirmed = value ?? false;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isSubmitting ? null : _submitDeleteRequest,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "SUBMIT DELETE REQUEST",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
