# 🚀 Guía Rápida - 5 Minutos

## ✅ Pasos Esenciales

### 1. Instalar Flutter (si no lo tienes)

**Linux/macOS:**
```bash
# Descargar Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar
flutter doctor
```

**Windows:**
- Descarga desde https://flutter.dev/docs/get-started/install/windows
- Agrega al PATH
- Ejecuta `flutter doctor`

### 2. Configurar Backend URL

**Edita:** `lib/core/constants/api_constants.dart`

```dart
static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator
// O
static const String baseUrl = 'https://tu-backend.com'; // Producción
```

### 3. Instalar y Ejecutar

```bash
cd /home/ubuntu/supplement_app/flutter_app

# Instalar dependencias
flutter pub get

# Conectar dispositivo o abrir emulador
# Luego ejecutar:
flutter run
```

## 📱 Probar la App

### Primera vez:

1. **Registrarse**
   - Abre la app
   - Toca "No tienes cuenta? Regístrate"
   - Completa el formulario
   - Acepta los términos
   - Toca "Registrarse"

2. **Dashboard**
   - Verás la pantalla vacía (sin suplementos)
   - Mensaje: "No tienes suplementos aún"

3. **Agregar Suplemento** (🚧 Aún no implementado)
   - Por ahora, puedes agregar suplementos desde:
     - Postman/Insomnia usando el API
     - Swagger del backend (`/api`)

4. **Ver Progreso**
   - Una vez agregados suplementos, aparecerán en el dashboard
   - Toca "Tomar" para registrar una toma
   - Observa cómo cambia la barra de progreso
   - Ve tu racha actual en el badge naranja

## 🐛 Troubleshooting Rápido

### No conecta al backend

```bash
# Verifica que el backend esté corriendo
curl http://localhost:3000/api

# Si funciona, ajusta la URL en api_constants.dart
```

### Error de dependencias

```bash
flutter clean
flutter pub get
```

### Emulador no aparece

```bash
# Listar dispositivos
flutter devices

# Abrir emulador Android
# (desde Android Studio o con comandos)
```

## 📝 URLs Importantes

- **Backend API Docs**: `http://localhost:3000/api`
- **Backend Health**: `http://localhost:3000`
- **Registrar Usuario**: `POST http://localhost:3000/auth/register`

## 🔑 Credenciales de Prueba

Para crear usuario de prueba rápidamente:

```json
{
  "email": "test@ejemplo.com",
  "password": "123456",
  "username": "testuser"
}
```

## 🚀 Next Steps

1. Lee el **README.md** completo para entender la arquitectura
2. Implementa la pantalla de "Agregar Suplemento" (ver guía en README)
3. Implementa notificaciones locales (dependencias ya instaladas)
4. Agrega sistema de amigos y leaderboards

¡Listo! Ya tienes tu app funcionando. 🎉
