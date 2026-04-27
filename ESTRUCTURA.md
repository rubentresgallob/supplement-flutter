# 📁 Estructura Completa del Proyecto

## 📊 Vista General

```
flutter_app/
├── lib/                          # Código fuente principal
│   ├── core/                     # Núcleo de la aplicación
│   │   ├── constants/
│   │   │   ├── api_constants.dart    # URLs y endpoints del API
│   │   │   └── app_constants.dart    # Constantes de la app (colores, textos)
│   │   ├── errors/
│   │   │   ├── exceptions.dart       # Excepciones personalizadas
│   │   │   └── failures.dart         # Tipos de fallos
│   │   ├── network/
│   │   │   └── api_client.dart       # Cliente Dio con interceptores
│   │   └── utils/
│   │       └── validators.dart       # Validadores de formularios
│   │
│   ├── data/                     # Capa de datos
│   │   ├── models/                # Modelos con serialización JSON
│   │   │   ├── user_model.dart
│   │   │   ├── user_supplement_model.dart
│   │   │   ├── intake_model.dart
│   │   │   └── streak_model.dart
│   │   ├── datasources/           # Fuentes de datos
│   │   │   ├── local_storage_datasource.dart  # SharedPreferences
│   │   │   ├── auth_remote_datasource.dart    # API Auth
│   │   │   ├── supplements_remote_datasource.dart  # API Suplementos
│   │   │   └── intakes_remote_datasource.dart      # API Tomas
│   │   └── repositories/          # [Por implementar si es necesario]
│   │
│   ├── domain/                   # Capa de dominio
│   │   ├── entities/              # Entidades de negocio (sin lógica de serialización)
│   │   │   ├── user.dart
│   │   │   ├── user_supplement.dart
│   │   │   ├── intake.dart
│   │   │   └── streak.dart
│   │   └── repositories/          # [Interfaces - si se necesitan]
│   │
│   ├── presentation/             # Capa de presentación (UI)
│   │   ├── auth/                  # Módulo de autenticación
│   │   │   ├── bloc/
│   │   │   │   ├── auth_bloc.dart         # Lógica de autenticación
│   │   │   │   ├── auth_event.dart        # Eventos (Login, Register, Logout)
│   │   │   │   └── auth_state.dart        # Estados (Loading, Authenticated, Error)
│   │   │   ├── pages/
│   │   │   │   ├── login_page.dart        # Pantalla de login
│   │   │   │   └── register_page.dart     # Pantalla de registro
│   │   │   └── widgets/               # [Widgets reutilizables del módulo]
│   │   │
│   │   ├── home/                  # Módulo home/dashboard
│   │   │   ├── bloc/
│   │   │   │   ├── home_bloc.dart         # Lógica del home
│   │   │   │   ├── home_event.dart        # Eventos (LoadSupplements, MarkTaken)
│   │   │   │   └── home_state.dart        # Estados (Loading, Loaded, Empty, Error)
│   │   │   ├── pages/
│   │   │   │   └── home_page.dart         # Pantalla principal (dashboard)
│   │   │   └── widgets/
│   │   │       ├── supplement_card.dart   # Tarjeta de suplemento
│   │   │       └── streak_badge.dart      # Badge de racha
│   │   │
│   │   ├── supplement_detail/     # [Por implementar]
│   │   │   ├── bloc/
│   │   │   └── pages/
│   │   │
│   │   └── app.dart               # Widget principal de la app
│   │
│   └── main.dart                  # Punto de entrada de la aplicación
│
├── android/                      # Configuración Android
│   └── app/
│       ├── build.gradle          # Configuración de build
│       └── src/main/
│           └── AndroidManifest.xml  # Manifest (permisos, etc.)
│
├── ios/                          # Configuración iOS
│   └── Runner/
│       └── Info.plist            # Info.plist (permisos, etc.)
│
├── test/                         # Tests
│
├── pubspec.yaml                  # Dependencias y configuración
├── analysis_options.yaml         # Reglas de análisis de código
├── .gitignore                    # Archivos ignorados por Git
├── .env.example                  # Ejemplo de variables de entorno
├── README.md                     # Documentación completa
├── QUICKSTART.md                 # Guía rápida (5 minutos)
└── ESTRUCTURA.md                 # Este archivo
```

## 📝 Resumen de Archivos Importantes

### 🎯 Core (7 archivos)

- **api_constants.dart**: Todas las URLs y endpoints del backend
- **app_constants.dart**: Colores, textos, keys de storage
- **api_client.dart**: Cliente HTTP con Dio, interceptores, manejo de errores
- **validators.dart**: Validadores de formularios (email, password, etc.)
- **exceptions.dart** y **failures.dart**: Manejo de errores

### 📊 Data Layer (8 archivos)

**Models (4):**
- user_model.dart
- user_supplement_model.dart
- intake_model.dart
- streak_model.dart

**DataSources (4):**
- local_storage_datasource.dart - SharedPreferences (tokens, user data)
- auth_remote_datasource.dart - Registro, login, logout
- supplements_remote_datasource.dart - CRUD de suplementos
- intakes_remote_datasource.dart - Tomas y rachas

### 🏛️ Domain Layer (4 archivos)

**Entities (4):**
- user.dart
- user_supplement.dart
- intake.dart
- streak.dart

### 🎨 Presentation Layer (11 archivos)

**Auth Module (5):**
- auth_bloc.dart, auth_event.dart, auth_state.dart
- login_page.dart
- register_page.dart

**Home Module (5):**
- home_bloc.dart, home_event.dart, home_state.dart
- home_page.dart
- supplement_card.dart (widget)
- streak_badge.dart (widget)

**App (1):**
- app.dart - MaterialApp, Theme, Routing

### ⚙️ Configuration (5 archivos)

- **main.dart**: Entry point, inicialización de datasources y BLoCs
- **pubspec.yaml**: Dependencias, assets, configuración del proyecto
- **analysis_options.yaml**: Reglas de linter
- **.gitignore**: Archivos a ignorar
- **.env.example**: Template de variables de entorno

## 📊 Estadísticas del Proyecto

- **Total de archivos Dart**: 31
- **Líneas de código**: ~3,000 (estimado)
- **Módulos completos**: 2 (Auth, Home)
- **Módulos pendientes**: ~6 (Supplement Detail, Add/Edit, Friends, Leaderboard, Profile, Help)
- **Dependencias principales**: 12
- **Plataformas**: Android + iOS

## 🔗 Dependencias Clave

### State Management
- **flutter_bloc** (^8.1.3) - Gestión de estado
- **equatable** (^2.0.5) - Comparación de objetos

### Networking
- **dio** (^5.4.0) - Cliente HTTP
- **http** (^1.1.0) - HTTP básico

### Storage
- **shared_preferences** (^2.2.2) - Almacenamiento local key-value
- **sqflite** (^2.3.0) - Base de datos SQLite (preparado, no usado aún)

### Notifications
- **flutter_local_notifications** (^16.3.0) - Notificaciones locales
- **timezone** (^0.9.2) - Manejo de zonas horarias

### UI
- **google_fonts** (^6.1.0) - Fuentes de Google

### Utils
- **intl** (^0.18.1) - Internacionalización y formateo
- **logger** (^2.0.2) - Logging

## 🛤️ Patrones de Diseño Utilizados

### 1. Clean Architecture
- **Separation of Concerns**: Data, Domain, Presentation
- **Dependency Inversion**: Domain no depende de Data o Presentation
- **Single Responsibility**: Cada clase tiene una única responsabilidad

### 2. BLoC Pattern
- **Events**: Acciones del usuario
- **States**: Estados de la UI
- **BLoC**: Lógica de negocio
- **Unidirectional Data Flow**: Event → BLoC → State → UI

### 3. Repository Pattern
- **DataSources**: Fuentes de datos (API, local)
- **Models**: Serialización/Deserialización
- **Repositories**: Abstracción sobre datasources (si se necesita)

### 4. Dependency Injection
- **Constructor Injection**: Inyección manual en main.dart
- **BlocProvider**: Proveer BLoCs a widgets

## 📚 Cómo Navegar el Código

### Para entender la autenticación:
1. `main.dart` - Inicialización de AuthBloc
2. `auth_bloc.dart` - Lógica de auth
3. `auth_remote_datasource.dart` - Llamadas al API
4. `login_page.dart` - UI de login

### Para entender el home/dashboard:
1. `app.dart` - Routing condicional (autenticado vs no autenticado)
2. `home_page.dart` - UI del dashboard
3. `home_bloc.dart` - Lógica de carga de suplementos
4. `supplement_card.dart` - Widget de tarjeta de suplemento
5. `supplements_remote_datasource.dart` - Llamadas al API de suplementos
6. `intakes_remote_datasource.dart` - Llamadas al API de tomas y rachas

### Para entender el API client:
1. `api_client.dart` - Configuración de Dio
2. `api_constants.dart` - URLs y endpoints
3. `local_storage_datasource.dart` - Manejo de tokens

## 🚀 Siguientes Archivos a Crear

### Prioridad 1: Add/Edit Supplement
```
presentation/supplement_form/
├── bloc/
│   ├── supplement_form_bloc.dart
│   ├── supplement_form_event.dart
│   └── supplement_form_state.dart
├── pages/
│   └── supplement_form_page.dart
└── widgets/
    ├── form_fields.dart
    └── schedule_picker.dart
```

### Prioridad 2: Supplement Detail
```
presentation/supplement_detail/
├── bloc/
│   ├── supplement_detail_bloc.dart
│   ├── supplement_detail_event.dart
│   └── supplement_detail_state.dart
├── pages/
│   └── supplement_detail_page.dart
└── widgets/
    ├── stats_card.dart
    ├── intake_history.dart
    └── streak_chart.dart
```

### Prioridad 3: Notifications Service
```
core/services/
└── notification_service.dart
```

---

¿Tienes preguntas sobre alguna parte de la estructura? Consulta el README.md para más detalles.
