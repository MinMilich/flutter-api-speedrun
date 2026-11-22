# flutter-api-speedrun

Generador automático universal para Flutter: le das una API y crea la app completa.

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

## Headers / auth

```powershell
.\generar_api.ps1 -Url "URL" -Header "Authorization: Bearer TOKEN" -Header "X-Api-Key: KEY"
```

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
| `-MaxPaginas` | Máximo páginas a seguir por `next` | `5` |
| `-Elegir` | Selector visual en terminal | off |
| `-Header` | Header HTTP `Clave: Valor` (repetible) | ninguno |

## Qué genera

- `lib/models/item.dart` - modelo universal con `raw` y todos los campos
- `lib/services/api_service.dart` - GET, parseo, paginación `next/info.next`, headers
- `lib/screens/lista_screen.dart` - lista con loading/error/tap
- `lib/screens/detalle_screen.dart` - detalle con todos los campos (o filtrados)
- `lib/main.dart` y `test/widget_test.dart`

## Límites actuales

- Paginación automática: `next` / `info.next` (URL completa). Cursor/token no estándar puede requerir ajuste.
- Auth simple por headers soportada; OAuth/flows complejos requieren ajuste.
- Detalle por endpoint separado por item no es automático aún.
- Esquemas muy anidados se muestran como JSON/texto en detalle.
