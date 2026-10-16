# Registro de actividades de tratamiento (art. 30 RGPD): BORRADOR

> Borrador para revisar. Rellena los `[CORCHETES]` y actualízalo cada vez que cambie un tratamiento.

**Responsable:** [NOMBRE Y APELLIDOS], NIF [NIF], [DIRECCIÓN POSTAL O APARTADO DE CORREOS], [EMAIL DE CONTACTO].
**Delegado de protección de datos:** no hay (no es obligatorio).
**Fecha:** [FECHA]. **Versión:** 1.0.

Aunque el art. 30.5 RGPD exime a quien tiene menos de 250 empleados, aquí el registro es obligatorio porque se tratan datos de salud (categoría especial), y además sirve para demostrar el cumplimiento.

Medidas de seguridad comunes a todas las actividades (art. 32):
- Conexiones HTTPS.
- Contraseñas y códigos cifrados con bcrypt.
- Tokens de sesión firmados que caducan a los 30 días y que dejan de valer si la cuenta se borra o se suspende.
- Límites de intentos por IP, solo en memoria.
- Registros sin datos personales salvo el id numérico, borrados a los 7 días.
- Acceso a la base de datos solo desde el servidor.
- Minimización: el catálogo solo envía lo que se muestra.
- Borrado en cascada.

---

## 1. Gestión de cuentas de usuario

- **Finalidad:** registro, verificación del email, inicio de sesión, recuperación de la contraseña, eliminación de la cuenta y avisos de seguridad.
- **Base jurídica:** contrato (6.1.b).
- **Interesados:** personas usuarias de 18 años o más.
- **Datos:** email, nombre de usuario, hash de la contraseña, fecha de alta, último acceso, códigos de verificación y recuperación (con hash), estado de verificación y de suspensión.
- **Destinatarios:** Supabase (BD, UE), Render + Cloudflare (servidor, Frankfurt) y Brevo (emails, Francia).
- **Transferencias internacionales:** posibles accesos desde EE. UU. por Supabase, Render y Cloudflare; cubiertos con cláusulas contractuales tipo o el Marco de Privacidad de Datos UE-EE. UU.
- **Plazos:** mientras la cuenta esté activa. Sin verificar, 24 h. Inactiva, 24 meses + 30 días de aviso. Los códigos caducan a los 15 o 30 minutos.

## 2. Registro de suplementos y tomas (datos de salud)

- **Finalidad:** registrar los suplementos, las dosis y las tomas, y calcular el calendario, las rachas, el cumplimiento y los recordatorios.
- **Base jurídica:** consentimiento explícito (9.2.a y 6.1.a).
- **Datos:** suplementos (nombre, forma, dosis, veces al día, franjas), tomas con fecha y hora, suplementos retirados con su historial y días protegidos.
- **Destinatarios:** Supabase, Render + Cloudflare. Google (FCM) recibe el nombre de un suplemento pendiente dentro del aviso de «Motivar» (solo Android).
- **Plazos:** hasta que se borra la cuenta (borrado inmediato y en cascada).

## 3. Funciones sociales

- **Finalidad:** amistades, solicitudes, clasificación, perfil de los amigos y avisos de «Motivar».
- **Base jurídica:** contrato (6.1.b) para lo que se ve siempre (nombre de usuario, objetos, mes de alta). Consentimiento separado (9.2.a y 6.1.a) para compartir el progreso y los suplementos (interruptores, apagados por defecto, con su historial).
- **Datos:** amistades y solicitudes, configuración de los interruptores y su historial (`sharing_event`), avisos de «Motivar» (emisor, receptor, fecha), token FCM del móvil Android.
- **Destinatarios:** los amigos aceptados (según los interruptores), Supabase, Render + Cloudflare y Google (FCM).
- **Plazos:** hasta que se borra la cuenta. El token FCM se borra al cerrar sesión o cuando deja de ser válido.

## 4. Juego: puntos y objetos

- **Finalidad:** puntos, tienda de objetos cosméticos y logros.
- **Base jurídica:** contrato (6.1.b).
- **Datos:** saldo e historial de puntos, objetos, objetos equipados y protectores de racha.
- **Plazos:** hasta que se borra la cuenta.

## 5. Moderación y denuncias

- **Finalidad:** bloquear, denunciar, revisar las denuncias, suspender cuentas y forzar el cambio de nombres de usuario.
- **Base jurídica:** interés legítimo (6.1.f) en un servicio seguro, y la obligación de tratar los avisos de contenido ilegal (Reglamento de Servicios Digitales).
- **Datos:** bloqueos; denuncias (denunciante, denunciado, motivo, texto libre, estado); suspensiones con su motivo. Aviso por email al responsable: id del denunciante, id y nombre de usuario del denunciado, motivo y texto. Nunca datos de salud.
- **Destinatarios:** Brevo (aviso por email) y el buzón del responsable.
- **Plazos:** las denuncias hechas se borran con la cuenta del denunciante; las recibidas quedan anónimas al borrarse la cuenta del denunciado. Los avisos por email: [PLAZO DE CONSERVACIÓN DE LOS AVISOS DE DENUNCIA].

## 6. Prueba del consentimiento y ejercicio de derechos

- **Finalidad:** demostrar qué aceptó cada persona y cuándo, y atender sus derechos.
- **Base jurídica:** obligación legal (6.1.c y 7.1).
- **Datos:** fechas y versiones de la aceptación de los Términos, de la Política, de la mayoría de edad y del consentimiento de datos de salud; peticiones de derechos por email.
- **Plazos:** mientras la cuenta esté activa. Las peticiones por email: [PLAZO, por ejemplo 3 años por posibles reclamaciones].

## 7. Seguridad y prevención de abusos

- **Finalidad:** limitar intentos por IP y diagnosticar errores.
- **Base jurídica:** interés legítimo (6.1.f).
- **Datos:** la IP, solo en memoria durante el periodo de limitación; registros con id de usuario, ruta, código y duración.
- **Destinatarios:** Render (registros) y Cloudflare (tráfico).
- **Plazos:** registros, 7 días (plan de Render, por verificar). La IP no se guarda.

## 8. Alojamiento de la web

- **Finalidad:** servir la versión web.
- **Base jurídica:** interés legítimo (6.1.f) en prestar el servicio web.
- **Datos:** la IP y el navegador que ve Google Firebase Hosting al servir los archivos.
- **Destinatarios:** Google (Firebase Hosting).
- **Plazos:** según Google (registros de Hosting); no tenemos acceso a ellos.
