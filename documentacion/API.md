# Contrato de API · v1

La app apunta por defecto a `https://al-tiro.vercel.app` y permite cambiar el origen mediante `API_BASE_URL`. Si el servicio falla o se desactiva con un valor vacío, se usa el conjunto local y los avisos quedan sin confirmar. El backend de Al Tiro publica reglas y avisos revisados a partir de documentos oficiales.

## GET /v1/rules?region=cdmx

Regiones: `cdmx`, `toluca`, `tianguistenco`, `valleMexico`. Respuesta UTF-8, JSON, HTTP 200. La respuesta tiene la misma forma que un elemento de `assets/data/rules.json`: `schemaVersion: 1`, versión, región, ventana revisada, calendario por día ISO (1=lunes), emisores reconocidos, emisores reconocidos sólo para 0/00, criterio de serie numérica, política de quinto sábado, habilitación y fuentes.

Ejemplo completo de respuesta: `api_examples/rules_cdmx.json`.

## GET /v1/notices?region=cdmx&date=2026-10-22

```json
{
  "schemaVersion": 1,
  "region": "cdmx",
  "date": "2026-10-22",
  "coverage": "unknown",
  "checkedAt": "2026-10-22T15:00:00Z",
  "freshUntil": "2026-10-22T15:30:00Z",
  "items": [],
  "sourceUrls": ["https://www.gob.mx/comisionambiental"],
  "reviewedSourceUrls": []
}
```

`coverage: complete` sólo después de revisar todas las fuentes aplicables para esa zona y fecha; `items: []` por sí solo no demuestra ausencia de contingencia. La app también verifica que la última revisión tenga menos de tres horas, no esté en el futuro y no haya vencido. Es una política de frescura del software, no un plazo establecido por la gaceta.

Cada aviso contiene `id`, `region`, fechas civiles `from`/`until`, `title`, `sourceUrl` HTTPS oficial, `kind` (`restriction` o `suspension`), `digits` (vacío = todas las terminaciones), `holograms` (vacío = todos), `startMinute` y `endMinute` (minutos del día, inicio inclusivo y final exclusivo). Los hologramas se serializan `doubleZero`, `zero`, `one`, `two`, `exempt`, `none`.

Las restricciones extraordinarias se suman al calendario. Sólo una suspensión de día completo, expresamente publicada y sin un aviso incompatible, puede anular automáticamente el calendario ordinario. Suspensiones parciales o avisos contradictorios piden revisión. No se deducen los grupos afectados a partir del título o del texto libre con IA.

## Requisitos del servicio

- HTTPS, `Content-Type: application/json; charset=utf-8`; CORS para la app web según los orígenes autorizados.
- Referencias a documento, versión y apartados. El equipo responsable valida reformas, alcance geográfico, excepciones y convenios.
- Horarios de Ciudad de México; timestamps de revisión en UTC con zona explícita.
- No introducir tokens privados en `--dart-define`: el binario y la web son inspeccionables. Si se requiere autenticación, añadir un flujo de sesión y un servicio adecuado antes de publicar.
- Errores, documentos incompletos o cobertura incierta deben retornar esa incertidumbre; no convertir fallos de captura de avisos en `complete`.

`sourceUrls` orienta hacia las autoridades de la zona y `reviewedSourceUrls` enlaza las fuentes registradas por el operador. Son campos informativos. Para que un APK previo use estos cambios se necesita una nueva compilación.
