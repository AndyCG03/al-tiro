# Al Tiro

Primera versión Flutter de la app de Sidarta. Persona amigable al volante, paleta Sidarta naranja/ámbar/carbón y recursos PNG optimizados; interfaz inspirada en las láminas de diseño.

## Funcionalidades

- Bienvenida por nombre y tutorial interactivo en cuatro secciones, con vehículo de ejemplo separado de los datos guardados y opción de repetir desde Ajustes.
- Calendario ordinario con días restringidos naranjas, símbolos y resumen mensual; detalle al seleccionar una fecha.

- Cinco ilustraciones seleccionables por vehículo, navegación personalizada y guía visual en Ajustes de hologramas 00, 0, 1, 2 y Exento. Ejemplos esquemáticos, no reproducciones oficiales.

- Inicio con resultado ordinario y confirmación separada de avisos extraordinarios.
- Calendario mensual por vehículo y zona.
- Vehículos guardados: placa, origen, emisor, holograma y vigencia; edición y eliminación.
- Alertas y vencimientos dentro de la app.
- Widget de pantalla de inicio (Android) en tres tamaños que se eligen solos al redimensionarlo: compacto (estado y placa), medio (estado de hoy, placa y fecha) y grande (añade la próxima restricción). Usa la paleta naranja/ámbar/carbón, símbolo + texto además de color, y modo oscuro. La app publica el resumen por el canal `mx.sidarta.al_tiro/widget`; al caducar el dato (fin del día o cambio de horario) invita a abrir la app.
- Español / English y tema claro / oscuro / sistema, con preferencias persistentes.
- API preparada y reglas locales con fuente y versión.

## Ejecutar

Se usó el SDK ya instalado: Flutter 3.47.7, Dart 3.13.5.

```powershell
flutter pub get
flutter run -d edge
```

Con un proveedor API propio:

```powershell
flutter run --dart-define=API_BASE_URL=https://tu-servicio.example
```

El dominio del ejemplo es un marcador; no es una API real. No introducir secretos en dart-define.

## Verificar y compilar

```powershell
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
flutter build apk --release
```

Para abrir el paquete web compilado:

```powershell
python -m http.server 8971 --bind 127.0.0.1 --directory build/web
```

## Documentación

- [Arquitectura](documentacion/ARQUITECTURA.md)
- [Base normativa y cobertura real](documentacion/BASE_NORMATIVA.md)
- [Contrato de API](documentacion/API.md)
- [Notas del release](documentacion/RELEASE_NOTES.md)
- [Optimización de recursos](documentacion/assets_manifest.json)

## Alcance de la versión preliminar

Las reglas son una base documentada; no se ha incorporado toda reforma, convenio y excepción vigente. El programa completo de verificación CDMX de julio–diciembre 2026 aún requiere cotejo. Las zonas o casos fuera de cobertura piden revisión y los avisos no se presentan como confirmados sin un proveedor válido. No se inventa que una API esté conectada.

Los recordatorios son dentro de la app; OCR y notificaciones en segundo plano siguen pendientes. No se ha validado en un dispositivo Android físico. La APK preliminar usa firma de pruebas; requiere firma de distribución para tiendas.

## Recursos

El logo y el carro minimalista fueron generados con la herramienta integrada de imágenes y optimizados a PNG con alfa. Los maestros y prompts están en documentacion/. Manrope se incluye con su licencia OFL en assets/fonts/OFL.txt. Los datos de cada vehículo permanecen en el dispositivo; las consultas HTTP de esta versión sólo envían zona y fecha.
