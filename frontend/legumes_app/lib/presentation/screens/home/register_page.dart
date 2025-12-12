import 'package:flutter/material.dart';
import 'package:legumes_app/core/utils/navigator.dart';
import 'package:legumes_app/data/services/vendor_service.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/local_provider.dart';
import 'package:legumes_app/presentation/screens/home/login_page.dart';
import 'package:legumes_app/presentation/screens/home/splash_screen.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final VendorService _authService = VendorService();

  bool _isLoading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _authService.createVendor(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (success) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() => _error = "Erreur lors de l'inscription.");
      }
    } catch (e) {
      setState(() => _error = "Erreur : ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.register,
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: AppColors.secondary),
            onPressed: () {
              final current = localeProvider.locale.languageCode;
              final newLocale =
                  current == 'fr' ? const Locale('ar') : const Locale('fr');
              localeProvider.changeLocale(newLocale);
            },
            tooltip: 'Changer la langue',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 400 : 500),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Icon(Icons.person_add,
                              size: 64, color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.register,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.name,
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value != null && value.trim().length >= 3
                                    ? null
                                    : AppLocalizations.of(context)!.invalidNom,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _shopNameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.shopName,
                              prefixIcon: const Icon(Icons.store),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value != null && value.trim().length >= 3
                                    ? null
                                    : AppLocalizations.of(context)!.invalidNom,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.phone,
                              prefixIcon: const Icon(Icons.phone),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) => value == null ||
                                    value.trim().isEmpty ||
                                    value.trim().length >= 8
                                ? null
                                : AppLocalizations.of(context)!.invalidPhone,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.location,
                              prefixIcon: const Icon(Icons.location_on),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.email,
                              prefixIcon: const Icon(Icons.email),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) => value != null &&
                                    value.contains('@')
                                ? null
                                : AppLocalizations.of(context)!.invalidEmail,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.password,
                              prefixIcon: const Icon(Icons.lock),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value != null && value.length >= 6
                                    ? null
                                    : AppLocalizations.of(context)!
                                        .passwordTooShort,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.confirmPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value == _passwordController.text
                                    ? null
                                    : AppLocalizations.of(context)!
                                        .passwordMismatch,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _register,
                                    child: Text(
                                        AppLocalizations.of(context)!.register),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              print('Bouton Se connecter cliqué');
                              Navigator.of(context)
                                  .pushReplacementNamed('/login');
                            },
                            child: Text(
                              AppLocalizations.of(context)!.haveAccount,
                              style:
                                  const TextStyle(color: AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
