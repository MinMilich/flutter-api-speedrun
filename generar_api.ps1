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
  if (-not $ListKey) { $ListKey = "__ROOT_ARRAY__" }
  Write-Host "Detectado: la respuesta es una lista directa."
} else {
  if (-not $ListKey) {
    foreach ($p in $json.PSObject.Properties) {
      if ($p.Value -is [System.Array] -and $p.Value.Count -gt 0) { $ListKey = $p.Name; break }
    }
  }
  if (-not $ListKey) { throw "No pude detectar la lista. Claves: $($json.PSObject.Properties.Name -join ', ')" }
  $list = $json.$ListKey
  Write-Host "ListKey detectado: $ListKey"
}

if (-not $list -or $list.Count -eq 0) { throw "La lista está vacía." }
$sample = $list[0]
$props = @($sample.PSObject.Properties.Name)
Write-Host "Campos encontrados: $($props -join ', ')"

# Detectar campo
if (-not $Campo) {
  $preferidos = @('name','title','firstName','first_name','nombre','question','fullName','username')
  foreach ($p in $preferidos) { if ($props -contains $p) { $Campo = $p; break } }
  if (-not $Campo) {
    foreach ($p in $props) {
      $v = $sample.$p
      if ($v -is [string] -or $v -is [ValueType]) { $Campo = $p; break }
    }
  }
}
if (-not $Campo) { throw "No pude detectar un campo para mostrar. Campos: $($props -join ', ')" }
Write-Host "Campo elegido: $Campo"

Write-Host "[2/5] Agregando http..."
flutter pub add http | Out-Null

Write-Host "[3/5] Creando archivos..."
New-Item -ItemType Directory -Force -Path "lib\models","lib\services","lib\screens","test" | Out-Null

$model = @'
class Item {
  final String __CAMPO__;

  Item({required this.__CAMPO__});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      __CAMPO__: json['__CAMPO__'].toString(),
    );
  }
}
'@.Replace('__CAMPO__', $Campo)
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

$screen = @'
import 'package:flutter/material.dart';
import 'package:__PKG__/models/item.dart';
import 'package:__PKG__/services/api_service.dart';

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
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => ListTile(title: Text(items[i].__CAMPO__)),
          );
        },
      ),
    );
  }
}
'@.Replace('__PKG__',$pkg).Replace('__PANTALLA__',$Pantalla).Replace('__TITULO__',$Titulo).Replace('__CAMPO__',$Campo)
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
