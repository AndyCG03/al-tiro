# Base normativa y cobertura

Revisión de fuentes: 22 de octubre de 2026. Esta primera versión es una implementación de referencia con alcance explícito; no constituye una certificación de cumplimiento de todas las disposiciones mexicanas.

## Fuentes primarias consultadas

1. **Gaceta Oficial del Distrito Federal, 19 junio 2014, No. 1882.** Decreto del Programa Hoy No Circula, apartados IV–XI, páginas 8–11. [Documento oficial](https://data.consejeria.cdmx.gob.mx/portal_old/uploads/gacetas/1906201421236d2801b.pdf). Copia en `fuentes/cdmx_2014-06-19.pdf`.
2. **Gaceta del Gobierno del Estado de México, 30 junio 2025**, acuerdo para las zonas metropolitanas del Valle de Toluca y Santiago Tianguistenco, artículos PRIMERO–SEXTO y OCTAVO, páginas 80–82. [Documento oficial](https://legislacion.edomex.gob.mx/sites/legislacion.edomex.gob.mx/files/files/pdf/gct/2025/junio/jun301/jun301c.pdf). Copia en `fuentes/edomex_2025-06-30.pdf`.
3. **Registro oficial del programa de verificación de CDMX, segundo semestre 2026**, publicado el 1 julio 2026. [Ficha de SEDEMA](https://proyectos.sedema.cdmx.gob.mx/datos/gocdmx/gaceta-simple/programa-de-verificacion-vehicular-obligatoria-para-el-segundo-semestre-del-ano-2026). Se verificó la ficha, pero la descarga del documento completo no respondió. No se afirma que sus disposiciones completas estén incorporadas.

La Gaceta CDMX, la Gaceta del Gobierno del Estado de México y el Diario Oficial de la Federación son publicaciones distintas. No existe una sola regla nacional de circulación obtenible únicamente del color de la placa o de los años del auto.

## Matriz de implementación

| Supuesto | Implementación | Fundamento |
|---|---|---|
| Un día entre semana, 05:00–22:00 | Sí | CDMX IV.3/IV.4; Edoméx TERCERO, tabla 1 |
| Holograma 1, sábados por paridad | Sí, primero/tercero impares y segundo/cuarto pares | Mismos apartados |
| Holograma 2, todos los sábados | Sí | Mismos apartados |
| Horario matutino de no reconocidos | Sí, 05:00–11:00 entre semana | CDMX V; Edoméx CUARTO |
| 0/00/E reconocidos, exención ordinaria | Sí, con constancia vigente | CDMX IV.2/VII; Edoméx SEGUNDO/SEXTO |
| Guanajuato/Michoacán en Toluca/Tianguistenco | Reconocimiento sólo de 0/00 | Edoméx SEGUNDO |
| Matrícula con varias series numéricas | Primera serie en CDMX; criterio diferenciado por zona | CDMX X; Edoméx TERCERO |
| Sólo letras | Tratamiento viernes/par | CDMX X; tabla mexiquense para matrículas sin número |
| Quinto sábado | Revisión explícita, sin inventar una resolución | Tabla mexiquense remite a CAMe; requiere disposición aplicable |
| Motocicletas, régimen ordinario | Exención ordinaria; avisos se revisan aparte | Transitorio SÉPTIMO CDMX; Edoméx SEXTO XI |
| Taxi, carga, permisos y casos especiales | Revisión específica; no se aplican reglas de particular | Regímenes adicionales y excepciones |
| Contingencias / suspensión | Modelo de avisos versionados vía API | CDMX XI; Edoméx QUINTO/OCTAVO |
| Certificado vencido o sin vigencia | Revisión, sin asignar holograma por modelo | No se presume una constancia vigente |

## Cobertura y asuntos pendientes

El conjunto local contiene una base ordinaria para CDMX y para Toluca/Tianguistenco. El reconocimiento ampliado de constancias en CDMX queda sujeto a actualizar el programa semestral: la lista local conservadora no pretende sustituir convenios posteriores. No se han incorporado por completo pase turístico, discapacidad, autos antiguos, autorregulación, emergencias, regímenes profesionales y excepciones de trayecto. Se identifican como casos de revisión, no como prohibiciones ni exenciones automáticas.

Valle de México del lado mexiquense está marcado como cobertura pendiente: el acuerdo de 2025 no debe extrapolarse automáticamente a esos municipios, pues remite a otro acuerdo. La selección de una zona no geolocaliza al usuario ni demuestra que esté dentro de sus municipios.

Los campos `reviewFrom`/`reviewThrough` son la ventana de revisión del conjunto de software (julio–diciembre 2026), no la fecha de derogación legal de un decreto. Al salir de esa ventana la app pide actualización. Las reglas deberán ser cotejadas con reformas, programas semestrales, convenios y avisos vigentes antes de ofrecer un servicio operativo de autorización de circulación.

No se calculan multas, tenencia ni asignaciones de holograma a partir de emisiones. Se guardan la constancia y vigencia declaradas por el usuario, sin verificar su autenticidad.
