# Supplement Tracker — App

App de **Supplement Tracker** para llevar el control de los suplementos que tomas: registro de tomas, rachas,
calendario, amigos y una tienda de recompensas con la mascota Capsu. Android, iOS y web desde el mismo código.
El backend (NestJS) es un repositorio aparte.

**Stack:** Flutter (Dart 3) · flutter_bloc · Dio · forui · Firebase Cloud Messaging · Codemagic · Firebase Hosting

## Arquitectura

Por capas, con el estado en BLoC/Cubit:

```
UI (pages, widgets) → BLoC / Cubit → datasources (Dio) → API REST del backend
```

| Carpeta | Qué hay |
|---|---|
| `lib/presentation/` | Una carpeta por funcionalidad, cada una con `bloc/`, `pages/` y `widgets/` |
| `lib/data/` | `datasources/` (llamadas a la API y almacenamiento local) y `models/` (JSON ↔ Dart) |
| `lib/domain/entities/` | Entidades: usuario, suplemento, toma, racha |
| `lib/core/` | Cliente HTTP, errores, servicios (notificaciones, push), constantes y el design system (`core/design/`) |

No hay capa de repositorios: los BLoC usan directamente los datasources. Para el tamaño actual de la app es suficiente.

| Funcionalidad | Qué hace |
|---|---|
| `auth` | Registro con verificación por email y consentimientos, login, recuperar contraseña |
| `onboarding` | Tutorial inicial con Capsu |
| `home` | Stack del día, registrar y deshacer tomas, racha, recordatorios locales |
| `calendar` | Calendario mensual de progreso (también el de un amigo, si lo comparte) |
| `friends` | Amigos, ranking, perfil de un amigo, «Motivar» (push), bloquear y denunciar |
| `rewards` | Puntos, logros y tienda (medallas, banners y accesorios de Capsu) |
| `profile` | Ajustes de privacidad, descargar mis datos, eliminar la cuenta |
| `legal` | Política de privacidad y términos dentro de la app |

**Seguridad:**
- El token JWT se guarda con `flutter_secure_storage`: Keystore en Android y Keychain en iOS.
- En la web queda cifrado en el almacenamiento del navegador, pero con la clave en ese mismo navegador: no protege
  frente a XSS.
- En `SharedPreferences` solo van datos no sensibles: id, nombre de usuario, horarios de recordatorio, tutorial visto.
  Se borran al cerrar sesión.
- La app no escribe en los logs el token ni los cuerpos de las peticiones.

## Puesta en marcha

Requisitos: Flutter (canal stable) y, para iOS, Xcode.

```bash
flutter pub get
flutter run                                              # contra el backend de producción
flutter run --dart-define=API_URL=http://10.0.2.2:3000   # emulador Android contra un backend local
```

La URL del backend se pasa al compilar con `--dart-define=API_URL=...`; si no se pasa, se usa la de producción
(`lib/core/constants/api_constants.dart`).

## Tests

```bash
flutter test
flutter analyze
```

Los tests de widgets y de BLoC están en `test/`: home y tomas, calendario, perfil de un amigo, tienda,
consentimientos, verificación de email, notificaciones y otros.

## Despliegue

- **Android:** Codemagic (`codemagic.yaml`). Cada push a `main` ejecuta análisis, tests y genera el APK.
- **Web:** Firebase Hosting. Se compila sin recursos de Google, para no cargar nada de terceros:
  ```bash
  flutter build web --release --no-web-resources-cdn
  firebase deploy --only hosting
  ```
- **iOS:** pendiente (requiere cuenta de Apple Developer).

## Licencia

© 2026 rubentresgallob. Todos los derechos reservados. El código se publica solo para que se pueda consultar;
no se concede permiso para copiarlo, modificarlo, distribuirlo ni usarlo. Ver [LICENSE](LICENSE).
