# flutter-api-speedrun

Generador automático universal para Flutter: le das una API y crea la app completa.

## Uso (1 comando, solo la URL)

```powershell
irm https://raw.githubusercontent.com/MinMilich/flutter-api-speedrun/main/generar_api.ps1 -OutFile generar_api.ps1
.\generar_api.ps1 -Url "https://API-AQUI"
flutter run -d chrome
```

Ejecuta el script **dentro de un proyecto Flutter** (donde exista `pubspec.yaml`). Si no tienes proyecto:

```powershell
flutter create mi_app
cd mi_app
irm https://raw.githubusercontent.com/MinMilich/flutter-api-speedrun/main/generar_api.ps1 -OutFile generar_api.ps1
.\generar_api.ps1 -Url "https://API-AQUI"
flutter run -d chrome
```

## Qué hace automático

- Detecta si la lista viene en raíz `[ ... ]` o dentro de una clave (`results`, `data`, `docs`, etc.)
- Detecta paginación `next` / `info.next` y la sigue (hasta `MaxPaginas`)
- Detecta campo principal, subtítulo e imagen (string URL u objeto `medium/original/url/src`)
- Crea modelo, servicio, pantalla lista, pantalla detalle (muestra todos los campos), main y test
- Ejecuta `dart analyze`

## Elegir qué campos mostrar/ocultar

```powershell
# Solo estos campos en el detalle
.\generar_api.ps1 -Url "URL" -Campos "name,age,status,occupation"

# Ocultar campos del detalle
.\generar_api.ps1 -Url "URL" -Ocultar "url,created,episode"
```

## Parámetros opcionales

| Parámetro | Descripción | Default |
|---|---|---|
| `-Url` | API a consumir | obligatorio |
| `-ListKey` | Clave donde viene la lista | auto |
| `-Campo` | Campo principal | auto |
| `-Pantalla` | Nombre del widget pantalla | `ListaScreen` |
| `-Titulo` | Título AppBar | `Lista API` |
| `-Campos` | Campos a incluir en detalle, separados por coma | todos |
| `-Ocultar` | Campos a ocultar en detalle, separados por coma | ninguno |
| `-MaxPaginas` | Máximo de páginas a seguir por `next` | `5` |

## Límites

- Funciona mejor con APIs JSON públicas que devuelven lista de objetos.
- Casos borde que pueden requerir ajuste/IA: auth/headers, paginación por cursor no estándar, esquemas muy anidados, detalle por endpoint separado, envelopes de error con forma de lista.
