param(
  [Parameter(Mandatory=$true)][string]$Url,
  [string]$ListKey = "results",
  [string]$Campo = "name",
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
$list = $json.$ListKey
if (-not $list) { throw "No encontré la lista '$ListKey'. Claves: $($json.PSObject.Properties.Name -join ', ')" }
$props = $list[0].PSObject.Properties.Name
Write-Host "Campos encontrados: $($props -join ', ')"

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

$service = @'
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:__PKG__/models/item.dart';

class ApiService {
  Future<List<Item>> getItems() async {
    final url = Uri.parse('__URL__');
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Error ${response.statusCode}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['__LISTKEY__'] as List<dynamic>;
    return results.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }
}
'@.Replace('__PKG__',$pkg).Replace('__URL__',$Url).Replace('__LISTKEY__',$ListKey)
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
