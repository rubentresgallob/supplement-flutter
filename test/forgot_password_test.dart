import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplement_tracker/data/datasources/auth_remote_datasource.dart';
import 'package:supplement_tracker/data/datasources/local_storage_datasource.dart';
import 'package:supplement_tracker/data/models/user_model.dart';
import 'package:supplement_tracker/presentation/auth/bloc/auth_bloc.dart';
import 'package:supplement_tracker/presentation/auth/pages/forgot_password_page.dart';

class _FakeAuth implements AuthRemoteDataSource {
  final sentTo = <String>[];
  final resets = <(String, String, String)>[];

  @override
  Future<void> forgotPassword(String email) async => sentTo.add(email);

  @override
  Future<UserModel> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    resets.add((email, code, newPassword));
    return UserModel.fromJson({
      'id': 1,
      'email': email,
      'username': 'test',
      'created_at': '2026-10-01T00:00:00.000Z',
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _frames(WidgetTester tester, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('recuperar contraseña: email → código + contraseña nueva', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageDataSource(await SharedPreferences.getInstance());
    final fake = _FakeAuth();

    // Como en la app: los providers envuelven a MaterialApp
    await tester.pumpWidget(RepositoryProvider<AuthRemoteDataSource>.value(
      value: fake,
      child: BlocProvider(
        create: (_) => AuthBloc(fake, storage),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ForgotPasswordPage(initialEmail: 'yo@example.com'),
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

    // Paso 1: enviar código al email que venía del login
    await tester.tap(find.text('Enviar código'));
    await _frames(tester);
    expect(fake.sentTo, ['yo@example.com']);
    expect(find.text('Código'), findsOneWidget);

    // Paso 2: las contraseñas no coinciden → no se envía
    await tester.enterText(find.widgetWithText(TextFormField, 'Código'), '123456');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña nueva'), 'nueva123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Repite la contraseña'), 'otra123');
    await tester.tap(find.text('Cambiar contraseña'));
    await _frames(tester);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(fake.resets, isEmpty);

    // Bien → cambia la contraseña y cierra la pantalla
    await tester.enterText(find.widgetWithText(TextFormField, 'Repite la contraseña'), 'nueva123');
    await tester.tap(find.text('Cambiar contraseña'));
    await _frames(tester, 20);
    expect(fake.resets, [('yo@example.com', '123456', 'nueva123')]);
    expect(find.byType(ForgotPasswordPage), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
