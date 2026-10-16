import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import '../core/constants/app_constants.dart';
import '../core/design/design.dart';
import '../core/theme/forui_theme.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/supplements_remote_datasource.dart';
import '../data/datasources/intakes_remote_datasource.dart';
import '../data/datasources/friends_remote_datasource.dart';
import '../data/datasources/rewards_remote_datasource.dart';
import '../data/datasources/local_storage_datasource.dart';
import 'auth/bloc/auth_bloc.dart';
import 'auth/bloc/auth_state.dart';
import 'auth/pages/legal_accept_page.dart';
import 'auth/pages/login_page.dart';
import 'home/pages/home_page.dart';
import 'home/bloc/home_bloc.dart';
import 'onboarding/pages/onboarding_page.dart';
import 'rewards/bloc/rewards_cubit.dart';

class SupplementTrackerApp extends StatelessWidget {
  final AuthBloc authBloc;
  final AuthRemoteDataSource authDataSource;
  final SupplementsRemoteDataSource supplementsDataSource;
  final IntakesRemoteDataSource intakesDataSource;
  final FriendsRemoteDataSource friendsDataSource;
  final RewardsRemoteDataSource rewardsDataSource;
  final LocalStorageDataSource localStorage;

  const SupplementTrackerApp({
    super.key,
    required this.authBloc,
    required this.authDataSource,
    required this.supplementsDataSource,
    required this.intakesDataSource,
    required this.friendsDataSource,
    required this.rewardsDataSource,
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
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildAppTheme(),
          themeMode: ThemeMode.dark,
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
                if (state.user.needsLegalAcceptance) {
                  return LegalAcceptPage(user: state.user);
                }
                return _OnboardingGate(localStorage: localStorage);
              }
              return const LoginPage();
            },
          ),
        ),
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
      duration: AppMotion.slow,
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
    return const Scaffold(
      body: AmbientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Floating(child: IridescentOrb(size: 64)),
              SizedBox(height: AppSpace.xxl),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
