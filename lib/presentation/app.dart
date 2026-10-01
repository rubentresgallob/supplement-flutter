import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/forui_theme.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/supplements_remote_datasource.dart';
import '../data/datasources/intakes_remote_datasource.dart';
import '../data/datasources/friends_remote_datasource.dart';
import '../data/datasources/rewards_remote_datasource.dart';
import '../data/datasources/pro_remote_datasource.dart';
import '../data/datasources/local_storage_datasource.dart';
import 'auth/bloc/auth_bloc.dart';
import 'auth/bloc/auth_state.dart';
import 'auth/pages/login_page.dart';
import 'home/pages/home_page.dart';
import 'home/bloc/home_bloc.dart';
import 'onboarding/pages/onboarding_page.dart';
import 'rewards/bloc/rewards_cubit.dart';
import 'pro/bloc/pro_cubit.dart';

class SupplementTrackerApp extends StatelessWidget {
  final AuthBloc authBloc;
  final AuthRemoteDataSource authDataSource;
  final SupplementsRemoteDataSource supplementsDataSource;
  final IntakesRemoteDataSource intakesDataSource;
  final FriendsRemoteDataSource friendsDataSource;
  final RewardsRemoteDataSource rewardsDataSource;
  final ProRemoteDataSource proDataSource;
  final LocalStorageDataSource localStorage;

  const SupplementTrackerApp({
    super.key,
    required this.authBloc,
    required this.authDataSource,
    required this.supplementsDataSource,
    required this.intakesDataSource,
    required this.friendsDataSource,
    required this.rewardsDataSource,
    required this.proDataSource,
    required this.localStorage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authDataSource),
        RepositoryProvider.value(value: supplementsDataSource),
        RepositoryProvider.value(value: intakesDataSource),
        RepositoryProvider.value(value: friendsDataSource),
        RepositoryProvider.value(value: rewardsDataSource),
        RepositoryProvider.value(value: proDataSource),
        RepositoryProvider.value(value: localStorage),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider(
            create: (context) => HomeBloc(supplementsDataSource, intakesDataSource, localStorage),
          ),
          BlocProvider(
            create: (context) => RewardsCubit(rewardsDataSource, intakesDataSource),
          ),
          BlocProvider(create: (context) => ProCubit(proDataSource)),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          // App en español (textos de forui y de Material)
          locale: AppLocalization.locale,
          localizationsDelegates: AppLocalization.delegates,
          supportedLocales: AppLocalization.supportedLocales,
          // Tema forui conectado a nuestros tokens para sus componentes
          builder: (context, child) => FTheme(
            data: AppForuiTheme.data,
            child: child!,
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) =>
                current is! AuthLoadingState || previous is AuthInitialState,
            builder: (context, state) {
              if (state is AuthInitialState || state is AuthLoadingState) {
                return const _SplashScreen();
              }
              if (state is AuthAuthenticatedState) {
                return _OnboardingGate(localStorage: localStorage);
              }
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }

  static const _font = FTypeface.defaultFontFamily;

  ThemeData _buildTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.bgCard,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onPrimary,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: base.textTheme.apply(fontFamily: _font).copyWith(
        bodyLarge: const TextStyle(
            fontFamily: _font,
            color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: const TextStyle(
            fontFamily: _font,
            color: AppColors.textPrimary, fontSize: 14),
        bodySmall: const TextStyle(
            fontFamily: _font,
            color: AppColors.textSecondary, fontSize: 12),
        labelLarge: const TextStyle(
            fontFamily: _font,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14),
        labelMedium: const TextStyle(
            fontFamily: _font,
            color: AppColors.textSecondary, fontSize: 12),
        labelSmall: const TextStyle(
            fontFamily: _font,
            color: AppColors.textMuted, fontSize: 11),
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: const TextStyle(
            fontFamily: _font,
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.bgCardElevated),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgCardElevated,
        selectedColor: AppColors.primary.withValues(alpha: 0.25),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        checkmarkColor: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCardElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Muestra el tutorial de Capsu la primera vez; después, la Home.
class _OnboardingGate extends StatefulWidget {
  final LocalStorageDataSource localStorage;
  const _OnboardingGate({required this.localStorage});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late bool _done = widget.localStorage.isOnboardingDone();

  Future<void> _finish() async {
    await widget.localStorage.setOnboardingDone();
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _done
          ? const HomePage()
          : OnboardingPage(key: const ValueKey('onboarding'), onDone: _finish),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrandLogo(size: 72),
              SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final double size;
  const _BrandLogo({this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(LucideIcons.flame,
          color: Colors.white, size: size * 0.55),
    );
  }
}
