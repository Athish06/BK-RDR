import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

enum AnnotationType {
  highlight, // Paint-style highlight
  textHighlight, // Text-detection highlight (like underline but with fill)
  underline,
  text,
  drawing,
  eraser,
}

class PdfAnnotation {
  final String id;
  final int pageNumber;
  final AnnotationType type;
  final Color color;
  final List<Offset> points; // Normalized points (0-1 range relative to page size)
  final List<PdfPageTextRange> textRanges; // For highlight/underline
  final String? text; // For text annotations
  final String? linkedNote; // Note associated with this annotation
  final Size? originalPageSize; // Original page size when annotation was created

  PdfAnnotation({
    required this.id,
    required this.pageNumber,
    required this.type,
    this.color = Colors.yellow,
    this.points = const [],
    this.textRanges = const [],
    this.text,
    this.linkedNote,
    this.originalPageSize,
  });

  PdfAnnotation copyWith({
    String? id,
    int? pageNumber,
    AnnotationType? type,
    Color? color,
    List<Offset>? points,
    List<PdfPageTextRange>? textRanges,
    String? text,
    String? linkedNote,
    Size? originalPageSize,
  }) {
    return PdfAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      color: color ?? this.color,
      points: points ?? this.points,
      textRanges: textRanges ?? this.textRanges,
      text: text ?? this.text,
      linkedNote: linkedNote ?? this.linkedNote,
      originalPageSize: originalPageSize ?? this.originalPageSize,
    );
  }
  
  // Convert widget coordinates to normalized coordinates (0-1 range)
  static Offset toNormalizedPoint(Offset point, Size pageSize) {
    return Offset(
      point.dx / pageSize.width,
      point.dy / pageSize.height,
    );
  }
  
  // Convert normalized coordinates back to widget coordinates
  static Offset toWidgetPoint(Offset normalizedPoint, Size pageSize) {
    return Offset(
      normalizedPoint.dx * pageSize.width,
      normalizedPoint.dy * pageSize.height,
    );
  }
  
  // Get scaled points for current page size
  List<Offset> getScaledPoints(Size currentPageSize) {
    if (originalPageSize == null) {
      // No original size stored, return points as-is (legacy behavior)
      return points;
    }
    
    // Scale points from original page size to current page size
    return points.map((normalizedPoint) {
      return Offset(
        normalizedPoint.dx * currentPageSize.width,
        normalizedPoint.dy * currentPageSize.height,
      );
    }).toList();
  }
}
