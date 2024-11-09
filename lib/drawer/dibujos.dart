import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:grafos/models/ModelArco.dart';
import 'package:grafos/models/ModelGrafo.dart';

class DibujaNodo extends CustomPainter {
  final List<ModeloNodo> nodos;
  final List<ModeloNodo> resultadoNodos;
  final List<Animation<Color?>> colorAnimations;

  DibujaNodo(this.nodos, this.resultadoNodos, this.colorAnimations);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < nodos.length; i++) {
      final nodo = nodos[i];
      Paint paint = Paint()
        ..style = PaintingStyle.fill;

      // Aplica el degradado si está activo
      if (nodo.esDegradado && nodo.colorDegradado != null && nodo.colorDegradado!.length >= 2) {
        paint.shader = LinearGradient(
          colors: nodo.colorDegradado!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: Offset(nodo.x, nodo.y), radius: nodo.radio));
      } else {
        paint.color = nodo.color;
      }

      // Dibuja el círculo del nodo
      canvas.drawCircle(Offset(nodo.x, nodo.y), nodo.radio, paint);

      // Aplica el borde si tiene grosor
      if (nodo.bordeAncho > 0) {
        Paint borderPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = nodo.bordeAncho;
        canvas.drawCircle(Offset(nodo.x, nodo.y), nodo.radio, borderPaint);
      }

      // Dibuja el nombre del nodo
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 12,
      );
      final textSpan = TextSpan(
        text: nodo.nombre,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: nodo.radio * 2,
      );
      final offset = Offset(nodo.x - textPainter.width / 2, nodo.y - textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
class DibujoArco extends CustomPainter {
  final List<ModeloArco> vArco;
  final List<ModeloArco> resultadoArcos;
  final List<Animation<Color?>> colorAnimations;
  final Animation<double> progressAnimation; // Animación de progreso para la conexión

  DibujoArco(this.vArco, this.resultadoArcos, this.colorAnimations, this.progressAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    Paint pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var i = 0; i < vArco.length; i++) {
      var arco = vArco[i];

      // Selecciona el color animado si el arco es parte de la solución
      if (resultadoArcos.contains(arco)) {
        int colorIndex = resultadoArcos.indexOf(arco);
        pincel.color = colorAnimations[colorIndex].value ?? arco.color;
      } else {
        pincel.color = arco.color;
      }

      Offset origen = Offset(arco.origen.x, arco.origen.y);
      Offset destino = Offset(arco.destino.x, arco.destino.y);
      Offset controlPoint = arco.puntoControl;

      // Crear el camino del arco con una curva cuadrática de Bézier
      Path path = Path()
        ..moveTo(origen.dx, origen.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, destino.dx, destino.dy);

      if (resultadoArcos.contains(arco)) {
        // Extraer el camino parcial basado en el progreso de la animación
        PathMetric pathMetric = path.computeMetrics().first;
        Path partialPath = pathMetric.extractPath(0, pathMetric.length * progressAnimation.value);
        canvas.drawPath(partialPath, pincel);
      } else {
        canvas.drawPath(path, pincel); // Dibuja el arco completo si no es parte de la solución
      }

      // Dibujar el peso del arco en el punto de control
      TextPainter textPainter = TextPainter(
        text: TextSpan(style: TextStyle(color: pincel.color, fontSize: 16), text: arco.peso),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(controlPoint.dx, controlPoint.dy - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
