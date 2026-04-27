import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_legacy_vault/core/constants/app_colors.dart';
import 'package:sfx_legacy_vault/core/services/encryption_service.dart';
import 'package:sfx_legacy_vault/features/vault/domain/models/vault_model.dart';
import 'package:sfx_legacy_vault/features/vault/presentation/providers/vault_provider.dart';
import 'package:sfx_legacy_vault/features/vault/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vault setup screen - Step-by-step wizard with encryption progress
class VaultSetupScreen extends ConsumerStatefulWidget {
  final String userId;

  const VaultSetupScreen({super.key, required this.userId});

  @override
  ConsumerState<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends ConsumerState<VaultSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dataController = TextEditingController();
  final _emailController = TextEditingController();
  final _passphraseController = TextEditingController();

  int _deadlineDays = 14;
  String _vaultType = 'crypto';
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassphrase = false;
  int _currentStep = 0;

  late AnimationController _progressController;

  // Step labels
  static const List<String> _stepLabels = [
    'Vault Details',
    'Your Secrets',
    'Recipient',
    'Deadline',
    'Encryption Key',
  ];

  // Step icons
  static const List<IconData> _stepIcons = [
    Icons.info_outline_rounded,
    Icons.lock_outline_rounded,
    Icons.person_outline_rounded,
    Icons.schedule_rounded,
    Icons.key_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _passphraseController.text = EncryptionService.generatePassphrase();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dataController.dispose();
    _emailController.dispose();
    _passphraseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _saveVault() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Animate encryption progress
    await _progressController.forward(from: 0.0);

    try {
      final passphrase = _passphraseController.text;
      final encryptedData =
          await EncryptionService.encrypt(_dataController.text, passphrase);

      final vault = VaultModel(
        id: '',
        userId: widget.userId,
        name: _nameController.text.trim().isEmpty ? 'My Vault' : _nameController.text.trim(),
        vaultType: _vaultType,
        lastActiveAt: DateTime.now(),
        targetEmail: _emailController.text.trim(),
        encryptedData: encryptedData,
        deadlineDays: _deadlineDays,
        createdAt: DateTime.now(),
        status: 'active',
      );

      await ref.read(vaultNotifierProvider.notifier).saveVault(vault);

      // Store passphrase locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('encryption_passphrase', passphrase);

      if (mounted) {
        // Show success animation
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save vault: ${e.toString()}';
      });
      _progressController.reset();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _regeneratePassphrase() {
    final newPass = EncryptionService.generatePassphrase();
    _passphraseController.text = newPass;
  }

  void _nextStep() {
    // Validate current step before advancing
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showStepError('Give your vault a name');
          return;
        }
      case 1:
        if (_dataController.text.trim().isEmpty) {
          _showStepError('Enter your secrets to protect');
          return;
        }
      case 2:
        if (_emailController.text.trim().isEmpty ||
            !_emailController.text.contains('@')) {
          _showStepError('Enter a valid recipient email');
          return;
        }
      case 3:
        // Deadline is always valid (slider)
      case 4:
        break;
    }
    if (_currentStep < _stepLabels.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showStepError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _errorMessage == message) {
        setState(() => _errorMessage = null);
      }
    });
  }

  /// Calculate passphrase strength 0-100
  int _passphraseStrength(String pass) {
    int score = 0;
    if (pass.length >= 12) {
      score += 20;
    } else if (pass.length >= 8) {
      score += 10;
    }
    if (pass.contains(RegExp(r'[A-Z]'))) {
      score += 15;
    }
    if (pass.contains(RegExp(r'[a-z]'))) {
      score += 15;
    }
    if (pass.contains(RegExp(r'[0-9]'))) {
      score += 15;
    }
    if (pass.contains(RegExp(r'[^A-Za-z0-9]'))) {
      score += 15;
    }
    if (pass.length >= 20) {
      score += 20;
    }
    return score.clamp(0, 100);
  }

  Color _strengthColor(int score) {
    if (score >= 75) return AppColors.neonGreen;
    if (score >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  String _strengthLabel(int score) {
    if (score >= 75) return 'Strong';
    if (score >= 50) return 'Moderate';
    return 'Weak';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: _currentStep > 0 ? _prevStep : () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key, size: 22, color: AppColors.neonGreen),
            const SizedBox(width: 8),
            Text(
              'Set Up Your Vault',
              style: const TextStyle(color: AppColors.neonGreen),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Text(
            'Step ${_currentStep + 1}/${_stepLabels.length}',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -50,
            left: size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.neonGreen.withValues(alpha:0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step progress bar
                    _buildStepProgress(),
                    const SizedBox(height: 24),

                    // Step title with icon + description
                    _buildStepHeader(),
                    const SizedBox(height: 20),

                    // Step content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildStepContent(),
                    ),

                    const SizedBox(height: 16),

                    // Error message
                    if (_errorMessage != null)
                      _buildErrorMessage(_errorMessage!),

                    // Navigation buttons
                    _buildNavigationButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    final totalSteps = _stepLabels.length;
    final progress = _currentStep / (totalSteps - 1);

    return Column(
      children: [
        // Linear progress bar with gradient
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonGreen),
          ),
        ).animate()
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 12),

        // Step dots with labels
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isActive = index == _currentStep;
            final isCompleted = index < _currentStep;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.neonGreen
                          : isActive
                              ? AppColors.neonGreen.withValues(alpha: 0.2)
                              : AppColors.surface,
                      border: Border.all(
                        color: isActive
                            ? AppColors.neonGreen
                            : AppColors.surfaceVariant,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, size: 16, color: AppColors.background)
                          : Icon(
                              _stepIcons[index],
                              size: 14,
                              color: isActive
                                  ? AppColors.neonGreen
                                  : AppColors.textSecondary.withValues(alpha: 0.4),
                            ),
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _stepLabels[index],
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepHeader() {
    return Column(
      children: [
        // Step icon + title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                _stepIcons[_currentStep],
                size: 20,
                color: AppColors.neonGreen,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _stepLabels[_currentStep],
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _stepDescriptions[_currentStep],
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha:0.8),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static const List<String> _stepDescriptions = [
    'Give your vault a clear name and select what type of secrets it will hold.',
    'Enter the secrets you want protected. This data will be encrypted and stored securely.',
    'Who should receive your data if you go silent? This email will receive the encrypted contents.',
    'How long should we wait before triggering delivery? You must ping regularly to prevent this.',
    'Your encryption key never leaves this device. Without it, your data is unreadable forever.',
  ];

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildVaultDetailsStep(key: const ValueKey('details'));
      case 1:
        return _buildSecretsStep(key: const ValueKey('secrets'));
      case 2:
        return _buildRecipientStep(key: const ValueKey('recipient'));
      case 3:
        return _buildDeadlineStep(key: const ValueKey('deadline'));
      case 4:
        return _buildEncryptionStep(key: const ValueKey('encryption'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVaultDetailsStep({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Vault name input
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Vault Name',
            hintText: 'e.g. Bitcoin Wallet, Business Passwords, Final Letter',
            labelStyle:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            hintStyle:
                TextStyle(color: AppColors.textSecondary.withValues(alpha:0.5)),
            prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.neonGreen),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha:0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neonGreen, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Give your vault a name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Vault type selector with visual grid
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.category_rounded, size: 16,
                        color: AppColors.textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'What is this vault for?',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _VaultTypeChip(
                    type: 'crypto',
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Crypto',
                    description: 'Wallets & Keys',
                    selected: _vaultType == 'crypto',
                    color: const Color(0xFFFF9900),
                    onTap: () => setState(() => _vaultType = 'crypto'),
                  ),
                  const SizedBox(width: 8),
                  _VaultTypeChip(
                    type: 'passwords',
                    icon: Icons.key_rounded,
                    label: 'Passwords',
                    description: 'Access & Logins',
                    selected: _vaultType == 'passwords',
                    color: const Color(0xFF00B0FF),
                    onTap: () => setState(() => _vaultType = 'passwords'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _VaultTypeChip(
                    type: 'letter',
                    icon: Icons.mail_rounded,
                    label: 'Letter',
                    description: 'Personal Message',
                    selected: _vaultType == 'letter',
                    color: AppColors.neonGreen,
                    onTap: () => setState(() => _vaultType = 'letter'),
                  ),
                  const SizedBox(width: 8),
                  _VaultTypeChip(
                    type: 'custom',
                    icon: Icons.folder_rounded,
                    label: 'Custom',
                    description: 'Other Data',
                    selected: _vaultType == 'custom',
                    color: AppColors.neonPink,
                    onTap: () => setState(() => _vaultType = 'custom'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecretsStep({Key? key}) {
    final isDataEntered = _dataController.text.trim().isNotEmpty;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withValues(alpha:0.05),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha:0.15),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.neonCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Anything you store here is encrypted with AES-256 before being saved. Examples: wallet seeds, passwords, final letters, legal documents.',
                  style: TextStyle(
                    color: AppColors.neonCyan.withValues(alpha:0.9),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Text input
        TextFormField(
          controller: _dataController,
          maxLines: 8,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Enter your secrets',
            hintText:
                'e.g. Wallet seed: abc def ghi jkl\nBank PIN: 1234\nFinal message to family...',
            alignLabelWithHint: true,
            labelStyle:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            hintStyle:
                TextStyle(color: AppColors.textSecondary.withValues(alpha:0.5)),
            prefixIcon: const Icon(Icons.note_outlined, color: AppColors.neonCyan),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha:0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter at least some data to protect';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Encrypted preview
        AnimatedCrossFade(
          firstChild: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_open_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Type your secrets above to see encrypted preview',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          secondChild: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 16, color: AppColors.neonGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Encrypted Preview (AES-256)',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '***encrypted*** (' '${_dataController.text.length} bytes)',
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: isDataEntered
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildRecipientStep({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Data flow diagram
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha:0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DataFlowNode(
                    icon: Icons.person_outline,
                    label: 'You',
                    color: AppColors.neonGreen,
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  _DataFlowNode(
                    icon: Icons.lock_outline,
                    label: 'Vault',
                    color: AppColors.neonCyan,
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  _DataFlowNode(
                    icon: Icons.email_outlined,
                    label: 'Recipient',
                    color: AppColors.neonPink,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Your data stays encrypted at every step',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Email input
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Target email address',
            hintText: 'recipient@example.com',
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.neonCyan),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha:0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Recipient email is required';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Verification note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Double-check this email. If delivery is triggered, this address will receive your encrypted data.',
                  style: TextStyle(
                    color: AppColors.warning.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineStep({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Deadline explanation
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha:0.05),
            border: Border.all(
              color: AppColors.warning.withValues(alpha:0.15),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 18, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'If you don\'t ping the app within this period, your encrypted data will be sent to your designated recipient.',
                  style: TextStyle(
                    color: AppColors.warning.withValues(alpha:0.9),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Deadline slider with visual preview
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha:0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.surfaceVariant.withValues(alpha:0.6),
            ),
          ),
          child: Column(
            children: [
              // Visual countdown preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DeadlinePreviewChip(
                      value: _deadlineDays.toString(),
                      label: 'Days',
                      color: AppColors.neonGreen,
                    ),
                    const SizedBox(width: 6),
                    _DeadlinePreviewChip(
                      value: (_deadlineDays * 24).toString().padLeft(2, '0'),
                      label: 'Hours',
                      color: AppColors.neonGreen.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    _DeadlinePreviewChip(
                      value: (_deadlineDays * 7).toString().padLeft(2, '0'),
                      label: 'Pings',
                      color: AppColors.neonGreen.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Days until delivery',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.neonGreen.withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      '$_deadlineDays days',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.neonGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: _deadlineDays.toDouble(),
                min: 7,
                max: 30,
                divisions: 23,
                activeColor: AppColors.neonGreen,
                inactiveColor: AppColors.surfaceVariant,
                onChanged: (value) {
                  setState(() => _deadlineDays = value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '7 days',
                    style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha:0.6),
                        fontSize: 12),
                  ),
                  Text(
                    '30 days',
                    style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha:0.6),
                        fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptionStep({Key? key}) {
    final strength = _passphraseStrength(_passphraseController.text);
    final sColor = _strengthColor(strength);
    final sLabel = _strengthLabel(strength);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encryption info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.neonPink.withValues(alpha:0.05),
            border: Border.all(
              color: AppColors.neonPink.withValues(alpha:0.15),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security_rounded, size: 18, color: AppColors.neonPink),
                  const SizedBox(width: 8),
                  Text(
                    'Zero-Knowledge Encryption',
                    style: TextStyle(
                      color: AppColors.neonPink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This passphrase is generated on your device and never sent to our servers. Only you can decrypt your vault data. If lost, your data is permanently inaccessible.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha:0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Passphrase display with strength meter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha:0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonPink.withValues(alpha:0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.key_rounded, size: 20, color: AppColors.neonPink),
                  const SizedBox(width: 8),
                  const Text(
                    'Encryption Key',
                    style: TextStyle(
                      color: AppColors.neonPink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _showPassphrase ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _showPassphrase = !_showPassphrase),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.neonGreen),
                    onPressed: _regeneratePassphrase,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _showPassphrase
                      ? _passphraseController.text
                      : '•••••••••••••••••••••••••••••••',
                  style: const TextStyle(
                    color: AppColors.neonPink,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ─── Strength Meter ───
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Key Strength',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.shield, size: 14, color: sColor),
                          const SizedBox(width: 4),
                          Text(
                            sLabel,
                            style: TextStyle(
                              color: sColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: strength / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(sColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Security badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepBadge(icon: Icons.key, label: 'AES-256'),
                  const SizedBox(width: 12),
                  _StepBadge(icon: Icons.storage, label: 'On-Device Only'),
                  const SizedBox(width: 12),
                  _StepBadge(icon: Icons.delete_forever, label: 'Never Shared'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      key: ValueKey(message),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: -0.2, end: 0, duration: 200.ms);
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _stepLabels.length - 1;
    final isFirstStep = _currentStep == 0;

    return Row(
      children: [
        if (!isFirstStep)
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          )
        else
          const SizedBox.shrink(),

        if (!isFirstStep) const SizedBox(width: 12),

        Expanded(
          flex: isFirstStep ? 1 : 2,
          child: isLastStep
              ? _buildSubmitButton()
              : OutlinedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                        color: AppColors.neonGreen.withValues(alpha:0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Continue'),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward,
                          size: 18,
                          color: AppColors.neonGreen.withValues(alpha:0.8)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonGreen.withValues(alpha:0.25),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        // Button
        ElevatedButton(
          onPressed: _isLoading ? null : _saveVault,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Encryption progress
                    SizedBox(
                      width: 120,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressController.value,
                            backgroundColor:
                                AppColors.background.withValues(alpha:0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.background),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Encrypting & Saving...',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 18, color: AppColors.background),
                    const SizedBox(width: 8),
                    const Text(
                      'Lock & Protect Vault',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── Deadline Preview Chips ─────────────────────────────────────────────────

class _DeadlinePreviewChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _DeadlinePreviewChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Flow Node ─────────────────────────────────────────────────────────

class _DataFlowNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DataFlowNode({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha:0.3)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha:0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Step Badge ─────────────────────────────────────────────────────────────

class _StepBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StepBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.neonPink.withValues(alpha:0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.neonPink.withValues(alpha:0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Vault Type Chip ────────────────────────────────────────────────────────

class _VaultTypeChip extends StatelessWidget {
  final String type;
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _VaultTypeChip({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : AppColors.surfaceVariant.withValues(alpha: 0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? color : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: TextStyle(
                  color: selected
                      ? color.withValues(alpha: 0.6)
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
