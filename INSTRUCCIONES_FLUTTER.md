# 📱 INSTRUCCIONES - App Flutter con Emulador Android

## ✅ REQUISITOS PREVIOS

### 1. Instalar Flutter
- **Descarga:** https://docs.flutter.dev/get-started/install/windows
- **Descomprime** en `C:\src\flutter`
- **Agrega al PATH:**
  - Panel de Control → Sistema → Configuración avanzada → Variables de entorno
  - Edita PATH y agrega: `C:\src\flutter\bin`
- **Verifica:**
  ```cmd
  flutter doctor
  ```

### 2. Instalar Android Studio
- **Descarga:** https://developer.android.com/studio
- **Instala** con las opciones por defecto
- **Durante instalación:** Marca "Android SDK" y "Android Virtual Device"

### 3. Configurar Emulador Android
1. Abre **Android Studio**
2. Click en **More Actions → Virtual Device Manager**
3. Click **Create Device**
4. Selecciona **Pixel 6** (o cualquier dispositivo moderno)
5. Selecciona **API Level 33** (Android 13) o superior
6. Click **Next → Finish**

---

## 🚀 EJECUTAR LA APP

### PASO 1: Descomprimir el Proyecto
```cmd
# Descomprime flutter_app_emulador.zip en:
C:\Users\Usuario\Desktop\Supple\MySupleAPP\

# Deberías tener:
C:\Users\Usuario\Desktop\Supple\MySupleAPP\flutter_app\
```

### PASO 2: Instalar Dependencias
```cmd
cd C:\Users\Usuario\Desktop\Supple\MySupleAPP\flutter_app
flutter pub get
```

### PASO 3: Iniciar Backend (IMPORTANTE)
**En otra terminal, asegúrate de que el backend esté corriendo:**
```cmd
cd C:\Users\Usuario\Desktop\Supple\MySupleAPP\suplementos_backend(1)\nodejs_space
npm run start:dev
```

**Verifica que esté corriendo en:** http://127.0.0.1:3000

### PASO 4: Iniciar Emulador
1. Abre **Android Studio**
2. Click en **Device Manager** (ícono de móvil arriba a la derecha)
3. Click en el **▶️ Play** del emulador que creaste
4. **Espera** a que el emulador arranque completamente (puede tardar 1-2 minutos)

### PASO 5: Ejecutar la App
```cmd
# Desde la carpeta flutter_app
flutter run
```

**La app se instalará automáticamente en el emulador** 🎉

---

## 🎮 PROBAR LA APP

### 1. Registro
- Se abrirá la pantalla de **Login**
- Toca **"¿No tienes cuenta? Regístrate"**
- Completa:
  - **Nombre de usuario:** testuser
  - **Email:** test@ejemplo.com
  - **Contraseña:** 123456
- Toca **"Registrarse"**

### 2. Dashboard
- Verás la pantalla principal
- Estadísticas: **0/0 Hoy**, **0 🔥 Racha**, **0 Suplementos**
- Mensaje: "No tienes suplementos aún"

### 3. Agregar Suplementos
**Desde la app web (navegador en tu PC):**
1. Ve a: http://127.0.0.1:3000
2. Inicia sesión con las mismas credenciales
3. Click en **"📚 Catálogo"**
4. Busca un suplemento (ej: "Vitamina D3")
5. Click **"➕ Añadir a Mi Lista"**
6. Configura dosis y frecuencia

**Vuelve al emulador:**
- Cierra la app (swipe up)
- Ábrela de nuevo
- **Verás el suplemento en tu dashboard** 🎉

### 4. Registrar Tomas
- Toca el botón **"💊 Tomar"** en un suplemento
- La barra de progreso se actualizará
- El contador de tomas aumentará

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### ❌ "No devices found"
```cmd
# Verifica que el emulador esté corriendo
flutter devices

# Deberías ver algo como:
# emulator-5554 (mobile) • Android SDK built for x86_64
```

### ❌ "Unable to connect to backend"
1. Verifica que el backend esté corriendo: http://127.0.0.1:3000
2. La URL en la app es: `http://10.0.2.2:3000` (especial para emulador)
3. Si no funciona, edita `lib/core/constants/api_constants.dart`:
   ```dart
   static const String baseUrl = 'http://10.0.2.2:3000';
   ```

### ❌ "Build failed"
```cmd
flutter clean
flutter pub get
flutter run
```

### ❌ Emulador muy lento
- Asegúrate de tener **HAXM** instalado (Android Studio lo instala)
- En BIOS, habilita **Virtualización (VT-x/AMD-V)**
- Usa un emulador con **API 33** o superior

---

## 📚 RECURSOS

- **Flutter Docs:** https://docs.flutter.dev
- **Android Studio:** https://developer.android.com/studio
- **API Backend Swagger:** http://127.0.0.1:3000/api

---

## 🎯 PRÓXIMOS PASOS

1. ✅ Ejecutar la app en emulador
2. ✅ Registrarte y probar login
3. ✅ Agregar suplementos desde la web
4. ✅ Registrar tomas desde la app móvil
5. 🚧 Implementar pantalla de "Agregar Suplemento" en la app
6. 🚧 Agregar notificaciones push

---

¡Listo! Si tienes problemas, revisa la sección de **Solución de Problemas** 🚀
