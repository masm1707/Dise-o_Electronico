import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miguecoordenadas/main.dart';

void main() {
  testWidgets('HomePage se construye y muestra el título', (WidgetTester tester) async {
    // Montamos solo HomePage dentro de un MaterialApp (no dispara inicializaciones de plugins).
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    // Verifica que el título de la app esté en pantalla.
    expect(find.text('GeoAlerta'), findsOneWidget);

    // Verifica que exista el botón para enviar (no lo pulsamos para no invocar plugins).
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
