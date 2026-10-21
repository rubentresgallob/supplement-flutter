# Lanzamiento gratuito de Supplement Tracker: informe

Rama `lanzamiento-gratuito` en los dos repositorios (app `supplement-flutter` y servidor `supplement-backend`). Nada está subido (sin push), nada está desplegado y la migración de la base de datos **no** se ha ejecutado.

Fecha del trabajo: 16-10-2026.

---

## 1. Cambios por fase y cómo probarlos

Antes de empezar se guardó en `main` lo que estaba pendiente (push de «Motivar», nombre e icono). La rama **`futuro-pro`** (en los dos repositorios) conserva el código Pro tal como estaba.

| Fase | Commits (app / servidor) | Qué cambia |
|---|---|---|
| 1. Sin Pro | `40203bc` / `ee438b1` | El código Pro se **borra** de la app en esta rama (pantalla Hazte Pro, estadísticas, PDF, control de stock, objetos Pro, aviso de «cancela la suscripción») y salen los paquetes `pdf` y `printing`. No había SDK de pagos ni de publicidad. En el servidor, Pro queda detrás de `PRO_ENABLED` (apagado por defecto): `/subscription`, `/stats` y el stock responden 404, la tienda no lista objetos Pro y no hay puntos x1,5 ni protector mensual. Se borra la web antigua de `public/`. |
| 2. Privacidad | `39cf524` / `8ae2938` | Email fuera de todas las respuestas entre usuarios. Solicitud de amistad con respuesta única. Registro sin revelar emails (ver §6). Logs: solo método, ruta, código, duración e id de usuario; los 500 sin mensaje. La app ya no registra el token ni los cuerpos de las peticiones. Web sin Google. «Descargar mis datos» completo. |
| 3. Registro | `1cbfe3b` / `b631a60` | Tres casillas separadas y sin marcar. Se guarda la fecha y la versión de cada aceptación. Pantalla de reaceptación. Enlaces legales en el login y el registro. Fuera los botones decorativos de Google y Apple. |
| 4. Social | `4c05042` / `056b63c` | Interruptores «Compartir mi progreso» y «Compartir mis suplementos» (apagados), con su historial. Pantalla «Qué verán tus amigos» antes de la primera solicitud. Bloquear, denunciar, filtro de nombres, suspensión y `scripts/moderar.ts`. |
| 5. Catálogo | `bdfd463` / `a2b5304` | Sin dosis sugerida; la API ya no envía dosis típica, funciones, beneficios ni notas. Aviso sanitario. |
| 6. Conservación | — / `e3c695b`, `9e52b1d` | `RetentionService` (24 h, 24 meses + 30 días). Borrado sin sesión desde la web. Cascada comprobada. **Falta el disparador diario (ver §6).** |
| 7. Legales | `6d35347` / `3115f19` | Política y Términos v1.0 en `docs/legal/`, dentro de la app y en `/privacidad` y `/terminos`. Al cerrar sesión también se borran la bio y las horas de los recordatorios del dispositivo. |
| 8. Tiendas | `4864607` / `7ee23b6` | Permisos mínimos, sin alarmas exactas, `PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption`, script de la cuenta demo. Fuera el botón «Notificaciones», que no hacía nada. |

### Cómo probarlo (en local, después de la migración)

```cmd
REM 1. Migración (producción: ver §5). Para probar en local hace falta una BD con la migración aplicada.
cd C:\Users\Usuario\Desktop\App_Suplementaci_n_Flutter\supplement_backend\nodejs_space
git checkout lanzamiento-gratuito
npx prisma generate
npm test
npm run start:dev

REM 2. App contra el servidor local
cd C:\Users\Usuario\Desktop\App_Suplementaci_n_Flutter\supplement_app\flutter_app
git checkout lanzamiento-gratuito
flutter pub get
flutter test
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```

Qué mirar:
- Registro con las 3 casillas.
- Un usuario antiguo ve la pantalla «Hemos actualizado nuestros textos».
- Añadir suplemento: dosis vacía y aviso sanitario.
- Amigos: pantalla «Qué verán tus amigos» en la primera solicitud.
- Perfil: los dos interruptores, «Usuarios bloqueados», «Descargar mis datos», textos legales y «Eliminar mi cuenta».
- Perfil de un amigo: menú ⋮ con Bloquear y Denunciar.
- `http://localhost:3000/privacidad`, `/terminos` y `/eliminar-cuenta.html`.

---

## 2. Formularios de las tiendas

### 2.1 Etiquetas de privacidad de la App Store («App Privacy»)

- **¿Recogéis datos?** Sí. **¿Seguimiento (tracking)?** No, de ningún tipo.
- Todos los datos siguientes están **vinculados a la identidad**, **no se usan para tracking** y su finalidad es **Funcionalidad de la app**:

| Categoría de Apple | Dato | Notas |
|---|---|---|
| Contact Info → Email Address | Email | Cuenta, verificación y recuperación |
| Health & Fitness → Health | Suplementos, dosis, tomas, calendario, rachas | Categoría especial |
| User Content → Other User Content | Nombre de usuario, nombres de suplementos personalizados, texto de las denuncias | |
| Identifiers → User ID | Id y nombre de usuario | |
| Diagnostics → Other Diagnostic Data | Registros del servidor (id de usuario, ruta, código), 7 días | Opción prudente: los registros guardan el id 7 días |

- No se recogen: ubicación, contactos, fotos, audio, compras, datos financieros, historial de navegación ni de búsqueda, ni identificadores de publicidad. En iOS no hay avisos push en esta versión, así que no hay token de dispositivo.

### 2.2 Seguridad de los datos de Google Play

- **¿Recoge o comparte datos?** Recoge: sí. Comparte: **no**. Los proveedores (Supabase, Render, Brevo y Google Firebase) son encargados del tratamiento, y lo que ven los amigos lo inicia el propio usuario; ninguna de las dos cosas cuenta como «compartir» para Google.
- **Cifrado en tránsito:** sí (HTTPS).
- **El usuario puede pedir que se borren sus datos:** sí, desde la app y en https://supplement-backend.onrender.com/eliminar-cuenta.html.
- Datos recogidos (todos **obligatorios**, salvo los indicados como opcionales; ninguno se trata efímeramente):

| Tipo de Google Play | Finalidad |
|---|---|
| Información personal → Dirección de correo | Funcionalidad de la app, gestión de la cuenta |
| Información personal → IDs de usuario | Funcionalidad de la app, gestión de la cuenta |
| Salud y forma física → Información de salud | Funcionalidad de la app |
| Actividad en la app → Otro contenido generado por el usuario (nombres personalizados, texto de denuncias; opcional) | Funcionalidad de la app, prevención de fraude/seguridad (denuncias) |
| Actividad en la app → Interacciones con la app (registros del servidor, 7 días) | Funcionalidad de la app, seguridad |
| Dispositivo u otros IDs → token de Firebase Cloud Messaging (opcional: solo con sesión iniciada en Android) | Funcionalidad de la app (avisos de «Motivar») |

### 2.3 Declaración de apps de salud (Google Play, Contenido de la app)

- Funciones de salud: **Gestión de medicación y tratamientos** (registro y recordatorios de los suplementos que toma el usuario). Si el formulario ofrece «Nutrición», márcala también.
- No es un producto sanitario, no está regulada, no da diagnósticos ni recomienda dosis, no usa Health Connect y no se dirige a menores.
- Política de privacidad: https://mi-suplementacion-app.web.app/privacidad.

### 2.4 Clasificación por edades

- **Google Play (IARC):** categoría «Utilidad/Productividad» o «Salud y bienestar». Sin violencia, sexo, lenguaje soez, drogas, apuestas ni compras. **Interacción entre usuarios: sí** (amigos, nombres de usuario), con bloqueo, denuncia y moderación. No comparte la ubicación. Además, en **Público objetivo y contenido**, marca solo **18 años o más**.
- **App Store:** en el cuestionario, «Temas médicos o de tratamiento / salud y bienestar»: **sí, poco frecuente o leve** (registro de suplementos con aviso sanitario). Contenido generado por usuarios: limitado a nombres de usuario y con moderación. Mensajería: no. Como la app es solo para adultos, sube la clasificación a la máxima (**18+**) con la opción de clasificación más alta.

### 2.5 Estado de «no comerciante» (Ley de Servicios Digitales)

- **App Store Connect** → Business → Digital Services Act: **«No soy comerciante» (not a trader)**. Es una persona física sin actividad económica y la app es gratuita, sin compras ni publicidad.
- **Google Play Console** → Configuración → Estado de comerciante: **no comerciante**.
- ⚠️ Si en el futuro hay planes de pago o publicidad, hay que revisar este estado.

### 2.6 Notas para el revisor

Crea la cuenta antes del envío (ver §5) y pega esto en «Notas de revisión» (App Store) o en «Instrucciones de acceso» (Google Play):

> Supplement Tracker es una app gratuita para registrar los suplementos que toma el usuario, sus tomas y su constancia. No es un producto sanitario ni recomienda dosis: el usuario escribe la dosis de la etiqueta.
>
> Cuenta de prueba: [EMAIL DE LA CUENTA DEMO] / [CONTRASEÑA DE LA CUENTA DEMO]. Tiene 3 suplementos con 3 semanas de tomas, una amiga (laura_demo) que comparte su progreso y sus suplementos, y una solicitud de amistad pendiente (pablo_demo).
>
> La primera respuesta del servidor puede tardar hasta un minuto si lleva un rato sin uso (plan gratuito).
>
> - Borrar la cuenta: Perfil → «Eliminar mi cuenta» (abajo del todo). También sin abrir la app: https://supplement-backend.onrender.com/eliminar-cuenta.html
> - Bloquear o denunciar a un usuario: Amigos → laura_demo → menú ⋮, o el menú ⋮ de la solicitud de pablo_demo.
> - Qué ven los amigos: Perfil → «Compartir mi progreso» y «Compartir mis suplementos» (apagados por defecto).
> - Descargar mis datos: Perfil → «Descargar mis datos».
> - La app no tiene compras, suscripciones, publicidad ni seguimiento. No hay inicio de sesión con terceros.
> - Notificaciones: se piden al configurar el primer recordatorio. En Android, «Motivar» envía un aviso al amigo; en iOS no hay avisos push en esta versión.

---

## 3. Lo que no he podido comprobar

- **Nada contra la base de datos real con el código nuevo.** Sin la migración, el servidor falla en las rutas que leen usuarios (comprobado: error P2022, «la columna no existe»). Solo probé en local, contra producción, lo que no necesita columnas nuevas: `/privacidad`, `/terminos`, `/eliminar-cuenta.html`, la web antigua (404), `/subscription` (404) y el catálogo sin campos sanitarios.
- **iOS:** no se puede compilar en Windows. Revisa `PrivacyInfo.xcprivacy` y la entrada nueva en `project.pbxproj` en el primer build de Codemagic o Xcode.
- **En un móvil real:** ni el registro con casillas, ni la reaceptación, ni bloquear o denunciar, ni los recordatorios inexactos, ni el push.
- **Firebase Hosting:** las rutas `/privacidad` y `/terminos` (en `firebase.json`) no están desplegadas. El archivo existe en `build/web/assets/docs/legal/`.
- **Plazos de los proveedores:** que Render guarde los logs 7 días, que el plan gratuito de Supabase no tenga copias, y si Supabase, Render y Cloudflare están adheridos al Marco de Privacidad de Datos UE-EE. UU. (la política dice «cuando la empresa está adherida»).
- **Que lleguen los emails** de denuncias (`ADMIN_EMAIL`), de inactividad y de moderación: dependen de Brevo, sin probar.

---

## 4. Lo que sí he comprobado

- Tests: app **61/61**; servidor **61 de 62** (el que falla es «Hello World», que ya fallaba antes de este trabajo). `flutter analyze`: 0 errores y 0 avisos (2 «info» de antes). TypeScript sin errores, incluidos los scripts.
- **Web compilada** (`flutter build web --release --no-web-resources-cdn`) abierta en Chrome con puppeteer: **0 peticiones fuera de nuestro dominio**, también escribiendo un emoji (la fuente se sirve desde `assets/fallback-fonts/`). Los textos `gstatic` que hay dentro de `flutter.js` y `main.dart.js` son direcciones por defecto del motor que no llegan a usarse.
- **Permisos reales del APK de release** (manifiesto final): `INTERNET`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`; los de Firebase Messaging `WAKE_LOCK`, `ACCESS_NETWORK_STATE` y `c2dm.permission.RECEIVE`; y uno interno de AndroidX (`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`). Ya no hay alarmas exactas ni `REQUEST_INSTALL_PACKAGES`. targetSdk 36, que es lo que exige Google Play desde el 31-08-2026.
- **Cascada en la BD real** (consulta de solo lectura): todas las claves externas hacia `user` y `user_supplement` borran en cascada. Las tablas nuevas también, salvo `user_report.reported_id`, que se pone a NULL (la denuncia recibida queda anónima).
- **Revisión final con búsquedas:** ni la app ni la web ni `public/` mencionan Pro, precios ni suscripciones. Pro solo queda en el servidor, apagado. Ningún servicio social devuelve emails: el email solo se usa para buscar el destinatario de una solicitud.
- Los 3 usuarios de la BD (1, 12, 13) son tuyos. Ninguno tiene versiones aceptadas, así que verán la reaceptación.

---

## 5. Tareas manuales pendientes

1. **Contratos de encargo del tratamiento (DPA):** acéptalos y guarda una copia en PDF de cada uno:
   - Supabase: Dashboard → Organization → Legal Documents.
   - Render: DPA en render.com/dpa.
   - Brevo: Settings → Security/GDPR.
   - Google Firebase: Firebase Console → Configuración del proyecto → Privacidad → «Términos de procesamiento de datos».
2. **Rellenar los `[CORCHETES]`** de `docs/legal/*.html`: `[FECHA]`, `[NOMBRE Y APELLIDOS]`, `[NIF]`, `[DIRECCIÓN POSTAL O APARTADO DE CORREOS]`, `[EMAIL DE CONTACTO]`, `[DÍAS]` y `[PLAZO DE CONSERVACIÓN DE LOS AVISOS DE DENUNCIA]`. Después, cópialos al servidor:
   ```cmd
   copy /Y docs\legal\politica-privacidad.html ..\..\supplement_backend\nodejs_space\public\privacidad.html
   copy /Y docs\legal\terminos.html ..\..\supplement_backend\nodejs_space\public\terminos.html
   ```
3. **Línea base de las migraciones en producción** (UNA sola vez, antes del primer despliegue con migraciones).
   Le dice a Prisma que la BD de producción ya tiene `0_init`; no cambia ninguna tabla:
   ```cmd
   cd C:\Users\Usuario\Desktop\App_Suplementaci_n_Flutter\supplement_backend\nodejs_space
   npx prisma migrate resolve --applied 0_init
   npx prisma migrate status
   ```
   `status` debe decir que falta solo `20261016000000_lanzamiento_gratuito` (solo añade columnas y tablas).
   Esa se aplica sola al desplegar (`render.yaml`: `prisma migrate deploy`). Si prefieres aplicarla a mano antes:
   `npx prisma migrate deploy`. Los usuarios existentes quedan con los dos interruptores apagados.
4. **Variables de Render** (Environment):
   - `PRO_ENABLED=false` y borrar `PRO_TEST_MODE`.
   - `ADMIN_EMAIL=[EMAIL DE CONTACTO]`.
   - `MAIL_FROM_NAME=Supplement Tracker`.
   - `FIREBASE_SERVICE_ACCOUNT`, si aún no está.
5. **Verificar plazos:** Render → Logs (retención del plan) y Supabase → Database → Backups. Si cambian, actualiza la política, sube su versión en `src/legal/legal.ts` y volverá a pedirse la aceptación.
6. **Orden del despliegue:** migración → servidor (merge a `main` y push) → app (Codemagic) y web (`flutter build web --release --no-web-resources-cdn` + `firebase deploy --only hosting --project mi-suplementacion-app`). La app y la web antiguas no funcionan con el servidor nuevo: el registro exige las 3 casillas.
7. **Cuenta demo** (después de la migración):
   ```cmd
   npx tsx --env-file=.env scripts/crear-cuenta-demo.ts [EMAIL DE LA CUENTA DEMO] [CONTRASEÑA]
   ```
8. **URLs para las tiendas:**
   - Privacidad: https://mi-suplementacion-app.web.app/privacidad
   - Términos: https://mi-suplementacion-app.web.app/terminos
   - Eliminar cuenta: https://supplement-backend.onrender.com/eliminar-cuenta.html
9. **Moderación:** revisa las denuncias con `npx tsx --env-file=.env scripts/moderar.ts denuncias`.
10. **Disparador diario de la conservación:** decide una opción (§6).

---

## 6. Decisiones abiertas

**a) Disparador diario de la conservación (Fase 6).** El servidor no tiene ningún planificador, y en el plan gratuito de Render se duerme a los 15 minutos sin uso, así que un temporizador dentro del servidor no es fiable. Opciones:

1. **(Recomendada) GitHub Actions, gratis.** Un workflow diario (`schedule: cron`) llama a `POST /maintenance/retention` con una cabecera secreta (`MAINTENANCE_TOKEN`). Eso despierta el servidor y ejecuta `RetentionService.run()`. Hay que añadir el endpoint (unas 20 líneas) y el workflow.
2. Ejecutarlo al arrancar el servidor y, como mucho, una vez cada 12 h mientras haya tráfico. No necesita nada externo, pero si nadie usa la app durante semanas, no se ejecuta.
3. Render Cron Job: es de pago.

Mientras tanto, las cuentas sin verificar se siguen borrando en cada registro, como antes.

**b) Registro y emails existentes.** Antes, el registro respondía «Email already exists», así que revelaba qué emails tenían cuenta. Ahora responde igual que a un registro nuevo y al dueño del email le llega «Ya tienes una cuenta». Alternativas: dejarlo como estaba (más cómodo, pero revela cuentas) o pedir el email en un primer paso y el resto después (no cambia el problema). El nombre de usuario sí sigue diciendo «ya existe»: es público dentro de la app.

**c) Push de «Motivar».** Lo mantienes, como decidiste. El texto del aviso puede incluir el nombre de un suplemento tuyo y pasa por Google (Firebase Cloud Messaging); la política lo explica. Si prefieres que no pase ningún dato de salud por Google, se puede cambiar el texto a uno genérico.

**d) Otros:**
- Las denuncias recibidas quedan sin vínculo con la cuenta, pero su texto libre podría mencionar el nombre de usuario.
- `JWT_SECRET` tiene un valor por defecto en el código si falta la variable. En Render existe, pero conviene quitar ese valor por defecto.
- Swagger (`/api`) es público y documenta también las rutas Pro, aunque respondan 404.
- Los dibujos del Capsu galaxia y de la aureola siguen en `capsu.dart`, pero no se pueden alcanzar.

---

## 7. Qué cambiar en los textos al activar nuevas funciones

| Función | Cláusulas afectadas | Nuevos encargados | Base jurídica | ¿Nuevo consentimiento? |
|---|---|---|---|---|
| **Suscripción Pro** (RevenueCat + App Store/Google Play) | Términos: §3 (ya no «sin compras»), §10, nueva sección de pagos (precio, renovación, cancelación en la tienda, desistimiento de 14 días con renuncia expresa para contenido digital, reembolsos según la tienda). Política: §2 (estado de la suscripción, id de cliente de RevenueCat, recibos), §3, §5, §6 (obligaciones fiscales: 6 años según el Código de Comercio) y §12. Revisar el estado de «no comerciante» (probablemente pasarás a serlo). | RevenueCat, Inc. (EE. UU.; DPA + cláusulas tipo/DPF). Apple y Google siguen como responsables independientes del cobro. | Contrato (6.1.b) y obligación legal (6.1.c) para la facturación | Sí, aceptar los Términos nuevos (subir la versión → reaceptación). No hace falta un consentimiento de datos nuevo. |
| **Publicidad** | Política: §2 (identificador de publicidad, IP, datos del dispositivo), §3, §5, §11 (cookies y banner en la web), §12. Términos §10. Formularios de las tiendas (anuncios: sí; tracking según el caso). | La red de anuncios (p. ej. Google AdMob) como responsable o encargado según el modelo, y una CMP certificada por IAB TCF. | Consentimiento (6.1.a y art. 22 LSSI) para anuncios personalizados o identificadores; interés legítimo solo para anuncios contextuales sin identificadores. **Nunca datos de salud para anuncios** (art. 9). | Sí: CMP con consentimiento previo, ATT en iOS. |
| **Push en iOS** (Motivar en iPhone) | Política §2 («solo en Android» → también iOS) y §5 (Apple Push Notification service). Formulario de Apple: Identifiers → Device ID. | Apple (APNs) a través de Firebase. | Igual que en Android: contrato y, para el nombre del suplemento, el consentimiento de salud | No, si se mantiene el mismo uso. Avisa del cambio en la app. |
| **Inicio de sesión con Google y Apple** | Política §2 (identificador de Google/Apple, email que comparte el proveedor, email de relay de Apple), §3 y §5. Términos §4. | Google y Apple como responsables independientes de su autenticación. | Contrato (6.1.b) | No. Apple exige «Iniciar sesión con Apple» si se ofrece Google. |

Para cualquiera de estos cambios: sube la versión en `src/legal/legal.ts` (`LEGAL_VERSIONS` y `LEGAL_CHANGES`) y en los dos HTML. La app pedirá aceptar al iniciar sesión.

---

## 8. Otros documentos

- `docs/lanzamiento/registro-actividades.md`: borrador del Registro de actividades de tratamiento (art. 30 RGPD).
- `docs/lanzamiento/eipd.md`: borrador de la Evaluación de impacto (art. 35 RGPD), pendiente de revisión profesional.
