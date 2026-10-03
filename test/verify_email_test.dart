import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplement_tracker/core/errors/exceptions.dart';
import 'package:supplement_tracker/data/datasources/auth_remote_datasource.dart';
import 'package:supplement_tracker/data/datasources/local_storage_datasource.dart';
import 'package:supplement_tracker/data/models/user_model.dart';
import 'package:supplement_tracker/presentation/auth/bloc/auth_bloc.dart';
import 'package:supplement_tracker/presentation/auth/bloc/auth_event.dart';
import 'package:supplement_tracker/presentation/auth/bloc/auth_state.dart';
import 'package:supplement_tracker/presentation/auth/pages/verify_email_page.dart';

class _FakeAuth implements AuthRemoteDataSource {
  final verified = <(String, String)>[];
  final resent = <String>[];

  @override
  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {}

  @override
  Future<UserModel> login({required String email, required String password}) async =>
      throw EmailNotVerifiedException();

  @override
  Future<UserModel> verifyEmail({required String email, required String code}) async {
    verified.add((email, code));
    return UserModel.fromJson({
      'id': 1,
      'email': email,
      'username': 'test',
      'created_at': '2026-10-01T00:00:00.000Z',
    });
  }

  @override
  Future<void> resendVerification(String email) async => resent.add(email);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _frames(WidgetTester tester, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late LocalStorageDataSource storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorageDataSource(await SharedPreferences.getInstance());
  });

  test('registrarse o entrar sin verificar pide el código', () async {
    final bloc = AuthBloc(_FakeAuth(), storage);
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const AuthRegisterEvent(email: 'yo@example.com', password: 'clave123', username: 'yo'));
    bloc.add(const AuthLoginEvent(email: 'yo@example.com', password: 'clave123'));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(states.whereType<AuthNeedsVerificationState>().map((s) => s.email),
        ['yo@example.com', 'yo@example.com']);
    expect(states.whereType<AuthAuthenticatedState>(), isEmpty);
    await sub.cancel();
    await bloc.close();
  });

  testWidgets('verificar email: código → sesión iniciada; reenviar tras la espera', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fake = _FakeAuth();

    await tester.pumpWidget(RepositoryProvider<AuthRemoteDataSource>.value(
      value: fake,
      child: BlocProvider(
        create: (_) => AuthBloc(fake, storage),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const VerifyEmailPage(email: 'yo@example.com'),
                )),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await _frames(tester);

    // Recién enviado: no deja reenviar todavía
    expect(find.textContaining('Reenviar en'), findsOneWidget);
    await tester.tap(find.textContaining('Reenviar en'));
    await _frames(tester);
    expect(fake.resent, isEmpty);

    // Pasado el minuto sí
    await tester.pump(const Duration(seconds: VerifyEmailPage.resendSeconds + 1));
    await tester.tap(find.text('¿No te llega? Reenviar código'));
    await _frames(tester);
    expect(fake.resent, ['yo@example.com']);

    // Código incompleto → no se envía
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Verificar'));
    await _frames(tester);
    expect(find.text('El código tiene 6 cifras'), findsOneWidget);
    expect(fake.verified, isEmpty);

    // Bien → verifica y cierra la pantalla
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verificar'));
    await _frames(tester, 20);
    expect(fake.verified, [('yo@example.com', '123456')]);
    expect(find.byType(VerifyEmailPage), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
