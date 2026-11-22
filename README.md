# flutter-api-speedrun

Generador automático para crear una app Flutter que consume una API.

## Uso (desde cualquier PC con Flutter + PowerShell)

```powershell
irm https://raw.githubusercontent.com/MinMilich/flutter-api-speedrun/main/generar_api.ps1 -OutFile generar_api.ps1
.\generar_api.ps1 -Url "https://thesimpsonsapi.com/api/characters?page=1" -ListKey "results" -Campo "name" -Pantalla "SimpsonsScreen" -Titulo "Simpsons"
flutter run -d chrome
```

Cambia solo: `-Url`, `-ListKey`, `-Campo`.
