# flutter-api-speedrun

Generador automático universal para Flutter: le das una API y crea la app completa.

Cumple el flujo de examen: **widgets + BLoC + consumo de servicios**. Por defecto genera arquitectura BLoC.

## Uso rápido

```powershell
irm https://raw.githubusercontent.com/MinMilich/flutter-api-speedrun/main/generar_api.ps1 -OutFile generar_api.ps1
.\generar_api.ps1 -Url "https://API-AQUI"
flutter run -d chrome
```

Ejecuta dentro de un proyecto Flutter (`pubspec.yaml`). Si no existe:

```powershell
flutter create mi_app; cd mi_app
irm https://raw.githubusercontent.com/MinMilich/flutter-api-speedrun/main/generar_api.ps1 -OutFile generar_api.ps1
.\generar_api.ps1 -Url "https://API-AQUI"
flutter run -d chrome
```

Android (emulador):

```powershell
.\generar_api.ps1 -Url "https://API-AQUI"
flutter run -d emulator-5554
```

## BLoC (default) / simple

```powershell
# Default: BLoC
.\generar_api.ps1 -Url "https://thesimpsonsapi.com/api/characters?page=1"

# Simple FutureBuilder
.\generar_api.ps1 -Url "https://thesimpsonsapi.com/api/characters?page=1" -Arquitectura simple
```

## Selector visual en terminal (elegir campos)

```powershell
.\generar_api.ps1 -Url "https://thesimpsonsapi.com/api/characters?page=1" -Elegir
```

Dentro del selector:
- `1,3,5` alterna campos para el detalle
- `a` todo / `n` nada
- `t:2` define título, `s:3` subtítulo, `i:4` imagen
- `d` continuar

## Selección por parámetros

```powershell
.\generar_api.ps1 -Url "URL" -Campos "name,age,status"
.\generar_api.ps1 -Url "URL" -Ocultar "url,created"
```

## Headers / auth simple

```powershell
.\generar_api.ps1 -Url "URL" -Header "Authorization: Bearer TOKEN" -Header "X-Api-Key: KEY"
```

## Detalle por endpoint separado

Si la lista trae `id/url` y el detalle completo está en otro GET:

```powershell
.\generar_api.ps1 -Url "https://jsonplaceholder.typicode.com/posts" -DetalleUrl "https://jsonplaceholder.typicode.com/posts/{id}"
```

`-DetalleUrl` acepta placeholders con cualquier campo del item: `{id}`, `{url}`, `{slug}`, etc.

## Parámetros

| Parámetro | Descripción | Default |
|---|---|---|
| `-Url` | API a consumir | obligatorio |
| `-ListKey` | Clave de la lista | auto |
| `-Campo` | Campo principal | auto |
| `-Pantalla` | Nombre widget pantalla | `ListaScreen` |
| `-Titulo` | Título AppBar | `Lista API` |
| `-Campos` | Campos a incluir en detalle | todos |
| `-Ocultar` | Campos a ocultar en detalle | ninguno |
| `-MaxPaginas` | Máximo páginas a seguir | `5` |
| `-Elegir` | Selector visual en terminal | off |
| `-Header` | Header HTTP `Clave: Valor` (repetible) | ninguno |
| `-DetalleUrl` | GET de detalle por item, con `{campo}` | vacío |
| `-Arquitectura` | `bloc` o `simple` | `bloc` |
| `-AiFallback` | Fallback IA estricto (solo si falla/analyze o explícito) | off |
| `-EnvFile` | Ruta `.env` con `DEEPSEEK_API_KEY` | búsqueda automática |
| `-AiModelo` | Modelo para fallback | `deepseek-chat` |

## Qué genera

- `lib/models/item.dart` - modelo universal con `raw` y todos los campos
- `lib/services/api_service.dart` - GET, parseo, headers, paginación
- `lib/bloc/items_bloc.dart` - BLoC/event/state (cuando `-Arquitectura bloc`)
- `lib/screens/lista_screen.dart` - lista con loading/error/tap
- `lib/screens/detalle_screen.dart` - detalle con todos los campos; o fetch por `-DetalleUrl`
- `lib/main.dart` y `test/widget_test.dart`

## Casos borde cubiertos (antes del fallback)

- Lista en raíz `[ ... ]` o dentro de `results/data/items/...`
- Paginación `next` / `info.next` con URL completa
- Paginación cursor/token básica (`next_cursor`, `cursor`, `pageToken`, etc.) en top-level/meta/pagination
- Paginación `page`/`total_pages`/`hasMore` y `offset/limit` básicas
- Todos los campos visibles en detalle; filtro por `-Campos`/`-Ocultar`/`-Elegir`
- Headers/auth simple por `-Header`
- Imagen como URL string u objeto (`original/medium/url/src`)
- Detalle por endpoint separado con `-DetalleUrl`
- Items heterogéneos/no-map: se ignoran entradas no-map; valores complejos se muestran como JSON/texto
- Detección clara para 401/403, HTML, binario/no-JSON y respuestas tipo GraphQL

## Fallback IA (estricto)

Solo se activa si pasas `-AiFallback` y `dart analyze` falla. Nunca se ejecuta solo por defecto.

```powershell
.\generar_api.ps1 -Url "https://API" -AiFallback -EnvFile "C:\Users\Nestor\Desktop\.env"
```

Reglas estrictas:
- Lee la clave solo de `DEEPSEEK_API_KEY` o del `.env` indicado/ubicaciones conocidas.
- Envía muestra JSON + error de `dart analyze` + archivos actuales.
- Solo acepta JSON con claves permitidas: `lib/models/item.dart`, `lib/services/api_service.dart`, `lib/screens/lista_screen.dart`, `lib/screens/detalle_screen.dart`, `lib/main.dart`.
- Rechaza claves no permitidas, markdown/comandos, o respuestas inválidas.
- Escribe archivos, vuelve a correr `dart analyze`; si sigue fallando, reporta y no insiste.

## Límites / casos estructurales

Estos casos se detectan o se reportan con claridad; si no son automáticos, usar `-AiFallback` estricto o ajuste manual pequeño:

- **OAuth/flows complejos** (refresh token, firma, multi-paso): usar headers/tokens ya obtenidos, o adaptar auth.
- **GraphQL**: el generador es REST/JSON por GET; para GraphQL usar endpoint REST equivalente o adaptar query POST manualmente.
- **No JSON / binario / streaming / WebSocket**: fuera del alcance automático del generador REST.
- **Paginación no estándar** (cursor en header/body, POST paginado): puede requerir ajuste manual del service.
- **Esquemas muy heterogéneos**: el modelo es tolerante, pero UI de negocio específica puede requerir ajuste.
- **UI específica de negocio**: el generador crea base genérica funcional; el examen/diseño específico se ajusta encima.

Siempre validar con `dart analyze` antes de entregar.