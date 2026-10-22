# Hoy Circula MX · primera versión preliminar

Primera app Flutter basada en la identidad del ajolote rosa, verde oscuro y blanco, con el carro minimalista generado para las tarjetas.

## Incluye

- Inicio, calendario mensual, varios vehículos, alta/edición/eliminación y alertas dentro de la app.
- Modo claro, oscuro y del sistema; español e inglés con preferencias persistentes.
- Reglas ordinarias por zona, holograma, matrícula, vigencia y fecha. Horarios en zona de Ciudad de México.
- Cliente HTTP preparado para una API de reglas y avisos, con validación y recuperación local ante fallos.
- Fuentes oficiales, documentación de cobertura y pruebas de casos límite.
- PNG con alfa, variantes optimizadas, fuente incluida localmente e íconos de app personalizados.

## Estado de esta entrega

**Preliminar para evaluación**, no un servicio completo de autorización para circular. Sin proveedor remoto configurado, la app mantiene los avisos extraordinarios sin confirmar. La documentación distingue los acuerdos revisados de las excepciones, reformas y programas pendientes de cotejo. No implementa OCR ni notificaciones en segundo plano. Ver `documentacion/BASE_NORMATIVA.md` y `documentacion/API.md`.

La APK está compilada en modo release con la firma de pruebas del proyecto, adecuada para evaluación interna; requiere firma de distribución y pruebas en equipo físico antes de publicar en tienda. La versión web debe abrirse mediante un servidor HTTP, no directamente como archivo.

## Validación

Flutter analyze sin incidencias; 35 pruebas superadas de reglas, API y widgets. Compilación web release y APK release. Revisión visual en navegador de guardado de un vehículo, recursos PNG, tema claro/oscuro e idioma inglés.

## Archivos

- `hoy-circula-mx-android-preview.apk`: APK para evaluación interna.
- `hoy-circula-mx-web-preview.zip`: app web compilada con recursos locales.
- `hoy-circula-mx-recursos.zip`: PNG y fuente de la identidad con licencia de la tipografía.
- `SHA256SUMS.txt`: comprobación de integridad de los paquetes.
