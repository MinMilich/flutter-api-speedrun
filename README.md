# flutter-api-speedrun

Generador automático universal para Flutter: le das una API y crea la app completa.

## Uso (1 comando, solo la URL)

```powershell
irm https://raw.githubusercontent.com/MinMilich/flutter-api-speedrun/main/generar_api.ps1 -OutFile generar_api.ps1
.\generar_api.ps1 -Url "https://API-AQUI"
flutter run -d chrome
```

## Qué hace automático
- Detecta si la lista viene en raíz `[ ... ]` o dentro de una clave (`results`, `data`, `docs`, etc.)
- Detecta campo principal, subtítulo e imagen
- Crea modelo, servicio, pantalla lista, pantalla detalle (muestra TODOS los campos), main y test
- Ejecuta `dart analyze`

## Opcional (solo si quieres forzar)
```powershell
.\generar_api.ps1 -Url "URL" -ListKey "data" -Campo "title" -Pantalla "MiScreen" -Titulo "Mi App"
```
