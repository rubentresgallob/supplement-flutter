# 💊 Suplementos Tracker - Flutter App

App móvil para seguimiento de suplementación desarrollada en Flutter para iOS y Android. Conectada con backend NestJS.

---

## 🎯 Características Implementadas

### ✅ Funcionalidades Completas

- **Autenticación JWT**
  - Registro de usuarios
  - Inicio de sesión
  - Cierre de sesión
  - Persistencia de sesión

- **Dashboard/Home**
  - Lista de suplementos del usuario
  - Progreso diario por suplemento (X/Y tomas)
  - Barra de progreso visual
  - Botón rápido "Tomar" para registrar tomas
  - Pull to refresh
  - Badge de racha actual y récord

- **Arquitectura**
  - Clean Architecture (data, domain, presentation)
  - Gestión de estado con BLoC pattern
  - Separación de responsabilidades
  - API Client con Dio y interceptores
  - Almacenamiento local con SharedPreferences

### 🚧 Funcionalidades Pendientes (Por Implementar)

- Añadir/editar/eliminar suplementos
- Detalle de suplemento con estadísticas
- Sistema de amigos
- Leaderboards y comparaciones
- Notificaciones locales
- Perfil de usuario
- Sección de ayuda

---

## 🛠️ Requisitos Previos

### Software Necesario

1. **Flutter SDK** (>= 3.0.0)
   - Descarga: https://flutter.dev/docs/get-started/install
   - Verifica la instalación: `flutter doctor`

2. **Android Studio** (para Android)
   - Descarga: https://developer.android.com/studio
   - Instala Android SDK y emulador

3. **Xcode** (para iOS - solo en macOS)
   - Descarga desde App Store
   - Instala Command Line Tools

4. **Editor de Código**
   - VS Code (recomendado) con extensiones:
     - Flutter
     - Dart
   - O Android Studio

### Backend

Esta app requiere el backend NestJS funcionando. Asegúrate de que:
- El backend esté corriendo (localmente o desplegado)
- Tengas la URL del backend lista para configurar

---

## 🚀 Instalación

### 1. Clonar o Descargar el Proyecto

```bash
cd /home/ubuntu/supplement_app/flutter_app
```

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Configurar URL del Backend

Edita el archivo `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // Cambia esta URL por la de tu backend
  static const String baseUrl = 'https://tu-backend-desplegado.com';
  // O para desarrollo local:
  // static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // iOS simulator
  ...
}
```

**Nota importante para emuladores:**
- Android Emulator: usa `http://10.0.2.2:3000` para acceder a localhost
- iOS Simulator: usa `http://localhost:3000`
- Dispositivo físico: usa la IP local de tu computadora (ej: `http://192.168.1.100:3000`)

### 4. Ejecutar la App

#### Android

```bash
# Con emulador abierto o dispositivo conectado
flutter run
```

#### iOS (solo macOS)

```bash
# Primero instala pods
cd ios
pod install
cd ..

# Luego ejecuta
flutter run
```

---

## 🏛️ Arquitectura del Proyecto

### Clean Architecture + BLoC

```
lib/
├── core/                    # Núcleo de la aplicación
│   ├── constants/          # Constantes (API, app)
│   ├── errors/             # Manejo de errores
│   ├── network/            # Cliente API (Dio)
│   └── utils/              # Utilidades (validadores)
│
├── data/                   # Capa de datos
│   ├── models/             # Modelos (JSON serialization)
│   ├── datasources/        # Fuentes de datos (API, local)
│   └── repositories/       # Implementación de repositorios
│
├── domain/                 # Capa de dominio
│   ├── entities/           # Entidades de negocio
│   └── repositories/       # Interfaces de repositorios
│
├── presentation/           # Capa de presentación (UI)
│   ├── auth/               # Módulo de autenticación
│   │   ├── bloc/           # BLoC (events, states)
│   │   ├── pages/          # Páginas (login, register)
│   │   └── widgets/        # Widgets reutilizables
│   ├── home/               # Módulo home
│   │   ├── bloc/
│   │   ├── pages/
│   │   └── widgets/
│   └── app.dart            # App principal
│
└── main.dart               # Punto de entrada
```

### Flujo de Datos

```
UI (Pages/Widgets)
  ↓
BLoC (Events/States)
  ↓
Repositories
  ↓
DataSources (API/Local)
  ↓
API Client (Dio)
  ↓
Backend (NestJS)
```

---

## 📝 Guía para Expandir Funcionalidades

### 📦 Añadir Nueva Pantalla

#### 1. Crear estructura de carpetas

```bash
mkdir -p lib/presentation/nueva_feature/{bloc,pages,widgets}
```

#### 2. Crear BLoC

**nueva_feature_event.dart:**
```dart
abstract class NuevaFeatureEvent extends Equatable {
  const NuevaFeatureEvent();
  @override
  List<Object> get props => [];
}

class LoadDataEvent extends NuevaFeatureEvent {}
```

**nueva_feature_state.dart:**
```dart
abstract class NuevaFeatureState extends Equatable {
  const NuevaFeatureState();
  @override
  List<Object> get props => [];
}

class LoadingState extends NuevaFeatureState {}
class LoadedState extends NuevaFeatureState {
  final List<Data> data;
  const LoadedState(this.data);
  @override
  List<Object> get props => [data];
}
```

**nueva_feature_bloc.dart:**
```dart
class NuevaFeatureBloc extends Bloc<NuevaFeatureEvent, NuevaFeatureState> {
  final DataSource dataSource;
  
  NuevaFeatureBloc(this.dataSource) : super(LoadingState()) {
    on<LoadDataEvent>(_onLoadData);
  }
  
  Future<void> _onLoadData(
    LoadDataEvent event,
    Emitter<NuevaFeatureState> emit,
  ) async {
    try {
      emit(LoadingState());
      final data = await dataSource.getData();
      emit(LoadedState(data));
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }
}
```

#### 3. Crear Page

```dart
class NuevaFeaturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NuevaFeatureBloc(dataSource)
        ..add(LoadDataEvent()),
      child: Scaffold(
        appBar: AppBar(title: Text('Nueva Feature')),
        body: BlocBuilder<NuevaFeatureBloc, NuevaFeatureState>(
          builder: (context, state) {
            if (state is LoadingState) {
              return Center(child: CircularProgressIndicator());
            }
            if (state is LoadedState) {
              return ListView(children: [/* ... */]);
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
```

---

### 🔔 Implementar Notificaciones Locales

Las dependencias ya están instaladas. Solo falta implementar:

#### 1. Inicializar en main.dart

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin notifications = 
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar timezone
  tz.initializeTimeZones();
  
  // Configurar notificaciones
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await notifications.initialize(settings);
  
  runApp(MyApp());
}
```

#### 2. Programar notificación

```dart
import 'package:timezone/timezone.dart' as tz;

Future<void> scheduleNotification(
  int id,
  String title,
  String body,
  DateTime scheduledTime,
) async {
  await notifications.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledTime, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'supplements_channel',
        'Recordatorios de Suplementos',
        channelDescription: 'Notificaciones para tomar suplementos',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
```

---

### 👥 Implementar Sistema de Amigos

El backend ya tiene los endpoints. Solo falta:

#### 1. Crear modelos

```dart
class Friend extends Equatable {
  final String id;
  final String username;
  final String email;
  // ...
}

class FriendRequest extends Equatable {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'rejected'
  // ...
}
```

#### 2. Crear DataSource

```dart
class FriendsRemoteDataSource {
  final ApiClient _apiClient;
  
  Future<List<Friend>> getFriends() async {
    final response = await _apiClient.get('/friends');
    return (response.data as List)
        .map((json) => FriendModel.fromJson(json))
        .toList();
  }
  
  Future<void> sendFriendRequest(String username) async {
    await _apiClient.post('/friends/request', data: {'username': username});
  }
  
  Future<void> acceptRequest(String requestId) async {
    await _apiClient.post('/friends/accept/$requestId');
  }
  // ...
}
```

#### 3. Crear UI

Sigue el patrón de Home: BLoC + Page + Widgets

---

### 🏆 Implementar Leaderboards

Similar a amigos, el backend ya está listo:

```dart
class LeaderboardEntry {
  final String userId;
  final String username;
  final int streak; // o adherence
  final int rank;
}

// DataSource
Future<List<LeaderboardEntry>> getFriendsLeaderboard() async {
  final response = await _apiClient.get('/leaderboard/friends');
  // ...
}
```

---

## 📦 Comandos Útiles

```bash
# Verificar estado de Flutter
flutter doctor

# Limpiar build
flutter clean

# Obtener dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar en modo release
flutter run --release

# Construir APK (Android)
flutter build apk --release

# Construir App Bundle (Android)
flutter build appbundle --release

# Construir IPA (iOS)
flutter build ios --release

# Ejecutar tests
flutter test

# Analizar código
flutter analyze

# Formatear código
dart format lib/
```

---

## 🐛 Debugging

### Problemas Comunes

#### 1. Error de conexión al backend

**Síntoma:** `DioException: Connection failed`

**Solución:**
- Verifica que el backend esté corriendo
- Usa la URL correcta según tu entorno:
  - Android Emulator: `http://10.0.2.2:3000`
  - iOS Simulator: `http://localhost:3000`
  - Dispositivo físico: IP local (ej: `http://192.168.1.100:3000`)

#### 2. Error de autenticación (401)

**Síntoma:** `AuthException: Sesión expirada`

**Solución:**
- El token JWT expiró
- Cierra sesión e inicia nuevamente
- Verifica que el backend esté enviando tokens válidos

#### 3. Dependencias no encontradas

**Síntoma:** `Error: Could not find package...`

**Solución:**
```bash
flutter clean
flutter pub get
```

### Ver Logs

```bash
# Logs en tiempo real
flutter logs

# O desde el IDE (VS Code / Android Studio)
# Pestaña "Debug Console"
```

---

## 📊 Next Steps Recomendados

### Prioridad Alta

1. **Implementar CRUD de suplementos**
   - Página para añadir suplemento
   - Navegación al detalle para editar
   - Confirmación para eliminar

2. **Página de detalle de suplemento**
   - Información completa
   - Historial de tomas
   - Estadísticas y gráficos
   - Racha específica del suplemento

3. **Sistema de notificaciones**
   - Configuración por suplemento
   - Recordatorios basados en horarios
   - Notificaciones persistentes

### Prioridad Media

4. **Sistema social**
   - Buscar y añadir amigos
   - Ver progreso de amigos
   - Aceptar/rechazar solicitudes

5. **Leaderboards**
   - Ranking por racha
   - Ranking por adherencia
   - Filtros y períodos

6. **Perfil de usuario**
   - Ver/editar información
   - Estadísticas globales
   - Configuración de la app

### Prioridad Baja

7. **Mejoras UI/UX**
   - Animaciones
   - Temas (modo oscuro)
   - Personalización de colores

8. **Features adicionales**
   - Exportar datos (PDF/CSV)
   - Gráficos de adherencia
   - Integración con calendario
   - Recordatorios inteligentes

---

## 📚 Recursos

### Documentación Oficial

- [Flutter](https://flutter.dev/docs)
- [Dart](https://dart.dev/guides)
- [BLoC](https://bloclibrary.dev/)
- [Dio](https://pub.dev/packages/dio)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

### Tutoriales Recomendados

- [Clean Architecture en Flutter](https://resocoder.com/flutter-clean-architecture-tdd/)
- [BLoC Pattern](https://www.youtube.com/watch?v=knMvKPKBzGE)
- [Manejo de estado en Flutter](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)

---

## ❓ Ayuda

Si encuentras problemas:

1. Revisa la sección de **Debugging** arriba
2. Verifica que el backend esté funcionando correctamente
3. Consulta los logs: `flutter logs`
4. Revisa la documentación del backend en Swagger

---

## 📝 Notas Importantes

- **Disclaimer**: Todos los textos de la app incluyen el disclaimer sobre consultar profesionales sanitarios
- **Seguridad**: Los tokens JWT se guardan de forma segura en SharedPreferences
- **Offline**: La app requiere conexión a internet para funcionar (considera implementar cache local)
- **Idioma**: Todo está en español (textos UI, comentarios, docs)

---

¡Buena suerte con el desarrollo! 🚀
