import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AppState>((ref) {
  return AuthNotifier();
});

enum AuthStatus { unknown, authenticated, unauthenticated }

class AppState {
  final AuthStatus status;
  final String? token;
  final String? userName;
  final String? userId;
  final String? role;

  AppState({
    this.status = AuthStatus.unknown,
    this.token,
    this.userName,
    this.userId,
    this.role,
  });

  AppState copyWith({
    AuthStatus? status,
    String? token,
    String? userName,
    String? userId,
    String? role,
  }) {
    return AppState(
      status: status ?? this.status,
      token: token ?? this.token,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AppState> {
  final _authService = AuthService();

  AuthNotifier() : super(AppState()) {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final token = await _authService.getToken();
    if (token != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        userName: await _authService.getUserName(),
        userId: await _authService.getUserId(),
        role: await _authService.getRole(),
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.unknown);
    try {
      final success = await _authService.login(email, password);
      if (success) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: await _authService.getToken(),
          userName: await _authService.getUserName(),
          userId: await _authService.getUserId(),
          role: await _authService.getRole(),
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AppState();
  }
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medical_services, size: 80, color: Colors.teal[800]),
              const SizedBox(height: 16),
              Text(
                'Prisha Pharma MR',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Medical Representative Portal',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    final status = ref.read(authProvider).status;
    if (status == AuthStatus.authenticated && mounted) {
      context.go(AppRoutes.home);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock,
          obscureText: true,
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const CircularProgressIndicator()
            : CustomButton(
                text: 'Login',
                onPressed: _submit,
              ),
      ],
    );
  }
}