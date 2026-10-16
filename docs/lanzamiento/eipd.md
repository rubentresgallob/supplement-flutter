# Evaluación de impacto relativa a la protección de datos (art. 35 RGPD): BORRADOR

> ⚠️ **Borrador para revisión profesional.** Lo ha preparado el desarrollo a partir del código de la rama `lanzamiento-gratuito`. Un profesional de protección de datos debe revisarlo antes de considerarlo definitivo.

**Responsable:** [NOMBRE Y APELLIDOS], [EMAIL DE CONTACTO]. **Fecha:** [FECHA]. **Versión:** 1.0 (borrador).

## 1. ¿Hace falta una EIPD?

Se tratan datos de salud (categoría especial) de personas usuarias de cualquier país y con funciones sociales. La lista de tratamientos que exigen EIPD de la AEPD incluye el tratamiento de categorías especiales de datos combinado con otros criterios. Aquí se dan, como mínimo, dos: la escala potencial (app pública en tiendas de todo el mundo) y la puesta en común con terceros (los amigos). Por prudencia, se hace la EIPD.

## 2. Descripción del tratamiento

- **Qué hace la app:** registra los suplementos alimenticios que toma la persona (nombre, forma, dosis, veces al día y franjas), sus tomas con fecha y hora, y calcula su calendario, sus rachas y su cumplimiento. Tiene amigos con clasificación, avisos de «Motivar» (push en Android), y un juego de puntos y objetos cosméticos.
- **Arquitectura y flujos:**
  - La app y la web hablan solo con el servidor (Render, Frankfurt, detrás de Cloudflare).
  - El servidor es lo único que se conecta a la BD (Supabase, París).
  - Los emails salen por Brevo (Francia).
  - La web se sirve desde Firebase Hosting (Google).
  - Los avisos push van por Firebase Cloud Messaging (Google).
  - Codemagic compila la app sin datos de usuarios.
- **Ciclo de vida:**
  - Registro con tres consentimientos separados.
  - Uso.
  - Exportación («Descargar mis datos»).
  - Borrado inmediato en cascada, desde la app o desde la web pública.
  - Borrado automático de las cuentas sin verificar (24 h) y de las inactivas (24 meses + 30 días de aviso).
- **Lo que no se hace:** publicidad, analítica, seguimiento, venta de datos, decisiones automatizadas con efectos jurídicos, recomendación de dosis.

## 3. Necesidad y proporcionalidad

- **Base jurídica:**
  - Consentimiento explícito para los datos de salud (art. 9.2.a), con una casilla separada que no viene marcada.
  - Consentimiento separado y revocable al momento para compartir con los amigos (interruptores, apagados por defecto, con su historial).
  - Contrato para la cuenta y el juego.
  - Interés legítimo para la seguridad.
- **Minimización:**
  - Solo se pide email, nombre de usuario y contraseña.
  - No se piden el nombre real, la fecha de nacimiento, el sexo, el peso ni la ubicación.
  - El catálogo no envía la dosis típica, las funciones ni los beneficios.
  - A los amigos se les da solo el mes y el año de alta, nunca el email.
  - Las horas de los recordatorios y la bio se quedan en el dispositivo.
- **Exactitud:** los datos los introduce la persona usuaria, que puede editarlos o borrarlos.
- **Limitación del plazo:** ver el punto 2. Registros de 7 días; IP solo en memoria.
- **Información:** Política de privacidad en capas: resumen en el registro y texto completo accesible sin sesión. Aviso sanitario en la app.
- **Derechos:** exportación en JSON, borrado en la app y en la web, interruptores y contacto por email. Plazo de respuesta: 1 mes.
- **Encargados:** contratos DPA con Supabase, Render, Brevo y Google (tarea pendiente: aceptarlos y archivarlos). Transferencias cubiertas con cláusulas contractuales tipo o el Marco de Privacidad de Datos.

## 4. Riesgos y medidas

| # | Riesgo | Probabilidad / gravedad inicial | Medidas | Riesgo residual |
|---|---|---|---|---|
| R1 | **Un amigo ve datos de salud que la persona no quería compartir** | Media / alta | Interruptores apagados por defecto; pantalla «Qué verán tus amigos» en la primera solicitud; efecto inmediato en la API (403 `SHARING_DISABLED`, `progress` y `today` nulos); solo amistades aceptadas; tests que lo comprueban. | Bajo |
| R2 | **Saber quién usa la app** (enumerar emails) para deducir que alguien toma suplementos | Media / media | Respuesta única en solicitudes, registro, recuperación y reenvío de códigos; el email nunca sale en respuestas entre usuarios; límites por IP. | Bajo |
| R3 | **Acoso o suplantación entre usuarios** | Media / media | Bloquear (borra la amistad e impide solicitudes), denunciar con aviso al responsable, filtro de nombres, suspensión y cambio forzoso de nombre con el motivo comunicado; «Motivar» limitado a 1 al día por pareja. | Bajo |
| R4 | **Acceso no autorizado a la cuenta** | Media / alta | Contraseñas con bcrypt; códigos con hash, caducidad e intentos limitados; límites de inicio de sesión; tokens que caducan y dejan de valer si la cuenta se borra o se suspende; email verificado obligatorio. Pendiente: valorar la doble verificación más adelante. | Medio-bajo |
| R5 | **Brecha en un proveedor** (BD o servidor) | Baja / alta | Proveedores con certificaciones (SOC 2/ISO) y DPA; datos en la UE; acceso a la BD solo desde el servidor; registros sin datos personales. Pendiente: procedimiento de notificación de brechas (72 h a la AEPD). | Medio-bajo |
| R6 | **Datos de salud fuera de la UE o en manos de terceros** | Baja / media | BD y servidor en la UE; transferencias con garantías. El aviso push puede llevar el nombre de un suplemento a través de Google FCM: se informa en la política, y se puede cambiar a un texto genérico si se quiere eliminar el riesgo. | Bajo-medio |
| R7 | **Datos en el dispositivo compartido** (recordatorios con el nombre del suplemento en la pantalla de bloqueo; datos locales) | Media / baja | Se informa en la política; al cerrar sesión se borran el token, el id, el nombre de usuario, la bio y las horas de los recordatorios; las notificaciones se cancelan. | Bajo |
| R8 | **Uso por menores** | Baja / media | Casilla obligatoria de 18 años o más; clasificación 18+ y público objetivo 18+ en las tiendas; borrado si se detecta un menor. | Bajo |
| R9 | **Que se tome la app como consejo médico** | Media / media | Aviso sanitario en «Añadir suplemento», en el tutorial y en los Términos; sin dosis sugeridas ni beneficios del catálogo. | Bajo |
| R10 | **Conservación excesiva** | Media / baja | Plazos definidos y lógica de borrado automático hecha. Pendiente: activar el disparador diario (INFORME §6.a). | Bajo, cuando se active el disparador |

## 5. Conclusión provisional

Con las medidas aplicadas, el riesgo residual se considera **aceptable** y no parece necesaria la consulta previa a la AEPD (art. 36), **a falta de la revisión profesional** y de completar lo pendiente:
- los DPA;
- el disparador de la conservación;
- el procedimiento de brechas;
- comprobar los plazos de los registros y de las copias de seguridad de los proveedores.

Revisar esta EIPD si se añaden pagos, publicidad, push en iOS, inicio de sesión con terceros o integraciones de salud (Health Connect o HealthKit).
