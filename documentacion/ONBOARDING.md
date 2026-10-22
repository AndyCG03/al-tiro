# Bienvenida y recorrido interactivo

Primero se pide el nombre (2 a 30 caracteres), guardado sólo en este dispositivo. Después se muestra un recorrido por Inicio, Calendario, Mis autos, Alertas y Guía usando los mismos componentes de la app. La barra inferior cambia la sección y su explicación. En Calendario se pueden tocar fechas y cambiar el mes para consultar el detalle ordinario.

El recorrido usa un AppController en modo preview con repositorio local propio y un vehículo Demo. Las escrituras de preferencias están desactivadas en ese controlador; nunca se añade Demo a los vehículos del usuario. Una llamada pendiente se invalida al cerrar el controlador. Se indica expresamente que los datos son de ejemplo.

El usuario puede omitir el recorrido. Al terminar se guarda tutorialComplete; el perfil, autos, idioma y tema sobreviven al reinicio. Los datos anteriores sin nombre o sin el nuevo campo se conservan y pasan por la nueva bienvenida. El tutorial se puede repetir desde Ajustes sin alterar los autos guardados.

El calendario distingue restricciones ordinarias con naranja y un símbolo de prohibición; revisión con signo de interrogación y borde; sin restricción ordinaria con superficie neutra y guion. Siempre se mantiene el aviso de contingencias sin confirmar cuando no hay cobertura oficial vigente. El recuento mensual no representa una autorización general de circulación.

Validación: pruebas de nombre requerido, recorrido entre secciones, ausencia de autos Demo en datos reales, conservación de perfil/tema/idioma/autos y selector de ilustraciones. Las reglas legales siguen separadas de la presentación.
