# flutter-api-speedrun

Generador automÃ¡tico universal para Flutter: le das una API y crea la app completa.

## Uso rÃ¡pido

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

## Selector visual en terminal (elegir campos)

```powershell
.\generar_api.ps1 -Url "https://thesimpsonsapi.com/api/characters?page=1" -Elegir
```

Dentro del selector:
- `1,3,5` alterna campos para el detalle
- `a` todo / `n` nada
- `t:2` define tÃ­tulo, `s:3` subtÃ­tulo, `i:4` imagen
- `d` continuar

## SelecciÃ³n por parÃ¡metros

```powershell
.\generar_api.ps1 -Url "URL" -Campos "name,age,status"
.\generar_api.ps1 -Url "URL" -Ocultar "url,created"
```

## Headers / auth

```powershell
.\generar_api.ps1 -Url "URL" -Header "Authorization: Bearer TOKEN" -Header "X-Api-Key: KEY"
```

## ParÃ¡metros

| ParÃ¡metro | DescripciÃ³n | Default |
|---|---|---|
| `-Url` | API a consumir | obligatorio |
| `-ListKey` | Clave de la lista | auto |
| `-Campo` | Campo principal | auto |
| `-Pantalla` | Nombre widget pantalla | `ListaScreen` |
| `-Titulo` | TÃ­tulo AppBar | `Lista API` |
| `-Campos` | Campos a incluir en detalle | todos |
| `-Ocultar` | Campos a ocultar en detalle | ninguno |
| `-MaxPaginas` | MÃ¡ximo pÃ¡ginas a seguir por `next` | `5` |
| `-Elegir` | Selector visual en terminal | off |
| `-Header` | Header HTTP `Clave: Valor` (repetible) | ninguno |

## QuÃ© genera

- `lib/models/item.dart` - modelo universal con `raw` y todos los campos
- `lib/services/api_service.dart` - GET, parseo, paginaciÃ³n `next/info.next`, headers
- `lib/screens/lista_screen.dart` - lista con loading/error/tap
- `lib/screens/detalle_screen.dart` - detalle con todos los campos (o filtrados)
- `lib/main.dart` y `test/widget_test.dart`

## LÃ­mites actuales

- PaginaciÃ³n automÃ¡tica: `next` / `info.next` (URL completa). Cursor/token no estÃ¡ndar puede requerir ajuste.
- Auth simple por headers soportada; OAuth/flows complejos requieren ajuste.
- Detalle por endpoint separado por item no es automÃ¡tico aÃºn.
- Esquemas muy anidados se muestran como JSON/texto en detalle.

## Fallback IA (estricto)

Solo se activa si pasas `-AiFallback` y `dart analyze` falla. Nunca se ejecuta solo por defecto.

``powershell
# Usa DEEPSEEK_API_KEY desde entorno o .env
.\generar_api.ps1 -Url "https://API" -AiFallback -EnvFile "C:\Users\Nestor\Desktop\.env"
``

Reglas estrictas:
- Lee la clave solo de `DEEPSEEK_API_KEY` o del `.env` indicado/ubicaciones conocidas.
- EnvÃ­a muestra JSON + error de `dart analyze` + archivos actuales.
- Solo acepta JSON con claves permitidas: `lib/models/item.dart`, `lib/services/api_service.dart`, `lib/screens/lista_screen.dart`, `lib/screens/detalle_screen.dart`, `lib/main.dart`.
- Rechaza claves no permitidas, markdown/comandos, o respuestas invÃ¡lidas.
- Escribe archivos, vuelve a correr `dart analyze`; si sigue fallando, reporta y no insiste.

## Lo que aÃºn falta para "cualquier API completa"

- PaginaciÃ³n por cursor/token no estÃ¡ndar (`next_cursor`, `pageToken`, etc.) sin URL `next`.
- Detalle por endpoint separado por item (lista trae `id/url`, detalle en otro GET).
- OAuth/flows de auth complejos (hoy: headers fijos).
- Esquemas muy heterogÃ©neos donde cada item tiene forma distinta.
- Contratos binarios/no JSON, GraphQL, streaming, WebSockets.

Para esos casos: generador automÃ¡tico primero; si no alcanza, `-AiFallback` estricto o ajuste manual pequeÃ±o, siempre validado con `dart analyze`.
