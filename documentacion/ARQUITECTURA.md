# Al Tiro · arquitectura de la primera versión

Flutter 3.47.7 / Dart 3.13.5 de la instalación existente. Paquetes resueltos con `pubspec.lock`; no se actualizó el SDK. Android, web y proyecto Windows.

## Separación de responsabilidades

- `domain/models.dart`: vehículo, emisor de la verificación, zona de destino, holograma, vigencia, política, fuente, aviso y resultado.
- `domain/rules_engine.dart`: funciones puras por fecha civil y hora local. No contiene interfaz, HTTP ni textos traducidos.
- `data/repositories.dart`: contrato `CirculationRepository`, versión local de reglas y adaptador HTTP configurable.
- `application/app_controller.dart`: selección de vehículo/zona/fecha y persistencia en el dispositivo. Descarta respuestas de solicitudes anteriores cuando el usuario cambia de contexto.
- `presentation/`: pantallas adaptables; navegación inferior en móvil y lateral en ventanas amplias.
- `l10n/app_text.dart`: recursos de español e inglés; fechas y diálogos Material localizados. Nuevos idiomas se agregan sin tocar las reglas.
- `assets/data/rules.json`: versión revisada de calendario ordinario. Una política remota válida puede sustituirla.

## Modelo de la consulta

La entidad de matrícula, el emisor del holograma y el destino son campos separados. El año-modelo es descriptivo: nunca asigna holograma. Una fecha de vigencia es inclusiva hasta el final de ese día civil. Todos los horarios se interpretan en `America/Mexico_City`, aunque el teléfono esté en otra zona horaria.

El resultado distingue calendario ordinario, ventanas horarias de restricción, motivo, avisos extraordinarios confirmados y fuentes. Si faltan avisos vigentes, no se convierte un resultado ordinario favorable en una autorización completa para circular.

## API

Se habilita con `--dart-define=API_BASE_URL=https://tu-servicio.example`. No se incluyó una URL inventada ni credenciales. El proveedor debe ser un servicio propio con revisión editorial/legal de fuentes oficiales. El contrato está en `API.md`.

La API sólo recibe zona y fecha; no se envía la placa ni el nombre del vehículo. Se exige HTTPS, salvo localhost en compilación de depuración. Hay timeout, validación de esquema, contexto de consulta, fuentes y vigencia. Un fallo vuelve a las reglas locales con los avisos sin confirmar, nunca a una decisión positiva antigua.

## Apariencia y recursos

Modo claro, oscuro o del sistema; idioma y preferencias guardados. Manrope se incluye localmente con OFL. El conductor y el carro actuales siguen la identidad Sidarta naranja/ámbar/carbón; se conserva la composición redondeada del símbolo anterior; se exportaron PNG con alfa y variantes de tamaño. Las medidas y reducción están en `assets_manifest_sidarta.json` (identidad actual) y `assets_manifest.json` (primera versión). Los originales se conservan fuera del directorio de assets compilados.

## Qué funciona y qué queda fuera

Funciona: alta/edición/eliminación de vehículos, varios autos, consultas ordinarias por fecha, calendario mensual, ventanas horarias, recordatorios dentro de la app, enlaces oficiales, preferencias, idiomas y tema. El cliente API está implementado y probado con un servidor simulado en pruebas.

Pendiente: servicio remoto de avisos reales, OCR de placas, notificaciones en segundo plano, pruebas en un dispositivo Android físico y revisión normativa exhaustiva de todas las excepciones y reformas vigentes. Los supuestos no implementados se marcan para revisión; no se simula que funcionan.
