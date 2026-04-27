import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz_lib;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'core/network/api_client.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/local_storage_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/supplements_remote_datasource.dart';
import 'data/datasources/intakes_remote_datasource.dart';
import 'data/datasources/friends_remote_datasource.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone local del dispositivo (necesario para programar notificaciones)
  tz.initializeTimeZones();
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  tz_lib.setLocalLocation(tz_lib.getLocation(timezoneInfo.identifier));

  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  final sharedPreferences = await SharedPreferences.getInstance();

  final localStorage = LocalStorageDataSource(sharedPreferences);
  final apiClient = ApiClient(localStorage);
  final authDataSource = AuthRemoteDataSource(apiClient, localStorage);
  final supplementsDataSource = SupplementsRemoteDataSource(apiClient);
  final intakesDataSource = IntakesRemoteDataSource(apiClient);
  final friendsDataSource = FriendsRemoteDataSource(apiClient);

  final authBloc = AuthBloc(authDataSource, localStorage);
  authBloc.add(AuthCheckStatusEvent());

  runApp(
    SupplementTrackerApp(
      authBloc: authBloc,
      authDataSource: authDataSource,
      supplementsDataSource: supplementsDataSource,
      intakesDataSource: intakesDataSource,
      friendsDataSource: friendsDataSource,
      localStorage: localStorage,
    ),
  );
}
