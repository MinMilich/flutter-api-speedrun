param(
  [Parameter(Mandatory=$true)][string]$Url,
  [string]$ListKey = "",
  [string]$Campo = "",
  [string]$Pantalla = "ListaScreen",
  [string]$Titulo = "Lista API"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$pkg = (Select-String -Path "pubspec.yaml" -Pattern "^name:\s*(.+)$").Matches.Groups[1].Value.Trim()
Write-Host "Paquete: $pkg"

Write-Host "[1/5] Leyendo API..."
$json = irm $Url

# Detectar lista
$list = $null
$esArrayRaiz = $false
if ($json -is [System.Array]) {
  $list = $json
  $esArrayRaiz = $true
  $ListKey = "__ROOT_ARRAY__"
  Write-Host "Detectado: lista directa en raiz."
} elseif ($json -is [pscustomobject] -or $json -is [hashtable]) {
  if (-not $ListKey) {
    foreach ($p in $json.PSObject.Properties) {
      $v = $p.Value
      if ($v -is [System.Array] -and $v.Count -gt 0 -and ($v[0] -is [pscustomobject] -or $v[0] -is [hashtable])) { $ListKey = $p.Name; break }
    }
  }
  if (-not $ListKey) {
    # fallback: cualquier array
    foreach ($p in $json.PSObject.Properties) {
      if ($p.Value -is [System.Array]) { $ListKey = $p.Name; break }
    }
  }
  if (-not $ListKey) { throw "No pude detectar la lista. Claves: $($json.PSObject.Properties.Name -join ', ')" }
  $list = $json.$ListKey
  Write-Host "ListKey detectado: $ListKey"
} else {
  throw "Respuesta no reconocida."
}

if (-not $list -or $list.Count -eq 0) { throw "La lista está vacía." }
$sample = $list[0]
$props = @($sample.PSObject.Properties.Name)
Write-Host "Campos encontrados: $($props -join ', ')"

# Detectar campo principal
if (-not $Campo) {
  $preferidos = @('name','title','firstName','first_name','nombre','question','fullName','username','common','label')
  foreach ($p in $preferidos) { if ($props -contains $p) { $Campo = $p; break } }
  if (-not $Campo) {
    foreach ($p in $props) { $v = $sample.$p; if ($v -is [string]) { $Campo = $p; break } }
  }
  if (-not $Campo) { $Campo = $props[0] }
}
Write-Host "Campo principal: $Campo"

# Detectar imagen
$imgField = ""
$imgPrefs = @('image','imageUrl','image_url','img','photo','portrait','portrait_path','thumbnail','avatar','picture','flag','sprite')
foreach ($p in $imgPrefs) {
  if ($props -contains $p) { $imgField = $p; break }
}
if (-not $imgField) {
  foreach ($p in $props) { $v = $sample.$p; if ($v -is [string] -and ($v -match '^https?://.*(jpg|jpeg|png|webp|gif|svg)' -or $v -match '/.*\.(jpg|jpeg|png|webp|gif)')) { $imgField = $p; break } }
}
Write-Host "Campo imagen: $(if($imgField){$imgField}else{'(ninguno)'})"

# Detectar campo subtitulo
$subField = ""
foreach ($p in $props) { if ($p -ne $Campo -and $p -ne $imgField) { $v=$sample.$p; if ($v -is [string] -or $v -is [int] -or $v -is [double] -or $v -is [bool]) { $subField=$p; break } } }
Write-Host "Campo subtitulo: $(if($subField){$subField}else{'(ninguno)'})"

Write-Host "[2/5] Agregando http..."
flutter pub add http | Out-Null

Write-Host "[3/5] Creando archivos..."
New-Item -ItemType Directory -Force -Path "lib\models","lib\services","lib\screens","test" | Out-Null

# Imagen: puede ser ruta relativa (simpsons) o URL completa
$imgGetter = "''"
if ($imgField) {
  $imgGetter = @"
() {
    final v = json['__IMG__'];
    if (v == null) return '';
    final s = v.toString();
    if (s.startsWith('http')) return s;
    if (s.startsWith('/')) return 'https://cdn.thesimpsonsapi.com/500${s}';
    return s;
  }()
"@.Replace('__IMG__', $imgField)
}

$model = @'
class Item {
  final Map<String, dynamic> raw;
  final String title;
  final String subtitle;
  final String imageUrl;

  Item({required this.raw, required this.title, required this.subtitle, required this.imageUrl});

  factory Item.fromJson(Map<String, dynamic> json) {
    String pick(String key) {
      final v = json[key];
      if (v == null) return '';
      if (v is Map || v is List) return v.toString();
      return v.toString();
    }
    return Item(
      raw: json,
      title: pick('__CAMPO__'),
      subtitle: pick('__SUB__'),
      imageUrl: __IMGGET__,
    );
  }

  List<MapEntry<String, String>> get fields {
    return raw.entries.map((e) {
      final v = e.value;
      String s;
      if (v == null) { s = 'null'; }
      else if (v is Map || v is List) { s = const JsonEncoder.withIndent('  ').convert(v); }
      else { s = v.toString(); }
      return MapEntry(e.key, s);
    }).toList();
  }
}
'@.Replace('__CAMPO__', $Campo).Replace('__SUB__', $subField).Replace('__IMGGET__', $imgGetter)
# Need JsonEncoder import in model
$model = "import 'dart:convert';`n`n" + $model
Set-Content -Path "lib\models\item.dart" -Value $model -Encoding UTF8

if ($esArrayRaiz) {
  $parseLine = "    final results = jsonDecode(response.body) as List<dynamic>;"
} else {
  $parseLine = "    final data = jsonDecode(response.body) as Map<String, dynamic>;`n    final results = data['__LISTKEY__'] as List<dynamic>;"
}
$serviceTpl = @'
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:__PKG__/models/item.dart';

class ApiService {
  Future<List<Item>> getItems() async {
    final url = Uri.parse('__URL__');
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Error ${response.statusCode}');
__PARSE__
    return results.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }
}
'@
$service = $serviceTpl.Replace('__PKG__',$pkg).Replace('__URL__',$Url).Replace('__PARSE__',$parseLine).Replace('__LISTKEY__',$ListKey)
Set-Content -Path "lib\services\api_service.dart" -Value $service -Encoding UTF8

$detail = @'
import 'package:flutter/material.dart';
import 'package:__PKG__/models/item.dart';

class DetalleScreen extends StatelessWidget {
  final Item item;
  const DetalleScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title.isEmpty ? 'Detalle' : item.title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (item.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Image.network(item.imageUrl, height: 220, fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 64)),
            ),
          for (final f in item.fields)
            Card(
              child: ListTile(
                title: Text(f.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: SelectableText(f.value),
              ),
            ),
        ],
      ),
    );
  }
}
'@.Replace('__PKG__',$pkg)
Set-Content -Path "lib\screens\detalle_screen.dart" -Value $detail -Encoding UTF8

$screen = @'
import 'package:flutter/material.dart';
import 'package:__PKG__/models/item.dart';
import 'package:__PKG__/services/api_service.dart';
import 'package:__PKG__/screens/detalle_screen.dart';

class __PANTALLA__ extends StatefulWidget {
  const __PANTALLA__({super.key});
  @override
  State<__PANTALLA__> createState() => _S_PANTALLA_State();
}

class _S_PANTALLA_State extends State<__PANTALLA__> {
  late final Future<List<Item>> _future;
  @override
  void initState() { super.initState(); _future = ApiService().getItems(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('__TITULO__')),
      body: FutureBuilder<List<Item>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Sin datos'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: item.imageUrl.isNotEmpty
                      ? Image.network(item.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const CircleAvatar(child: Icon(Icons.image_not_supported)))
                      : CircleAvatar(child: Text('${i + 1}')),
                  title: Text(item.title.isEmpty ? '(sin título)' : item.title),
                  subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleScreen(item: item))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
'@.Replace('__PKG__',$pkg).Replace('__PANTALLA__',$Pantalla).Replace('__TITULO__',$Titulo)
$screen = $screen.Replace('_S_PANTALLA_State', '_' + $Pantalla + 'State')
Set-Content -Path "lib\screens\lista_screen.dart" -Value $screen -Encoding UTF8

$main = @'
import 'package:flutter/material.dart';
import 'package:__PKG__/screens/lista_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: __PANTALLA__());
  }
}
'@.Replace('__PKG__',$pkg).Replace('__PANTALLA__',$Pantalla)
Set-Content -Path "lib\main.dart" -Value $main -Encoding UTF8

$test = @'
import 'package:flutter_test/flutter_test.dart';
import 'package:__PKG__/main.dart';

void main() {
  testWidgets('App carga', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
'@.Replace('__PKG__',$pkg)
Set-Content -Path "test\widget_test.dart" -Value $test -Encoding UTF8

Write-Host "[4/5] Analizando..."
dart analyze
Write-Host "[5/5] Listo. Corre: flutter run -d chrome"
