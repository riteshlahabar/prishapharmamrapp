import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportModel {
  final int id;
  final String type;
  final String date;
  final String summary;

  ReportModel({
    required this.id,
    required this.type,
    required this.date,
    required this.summary,
  });
}

final reportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  // TODO: Replace with real API call
  return [
    ReportModel(id: 1, type: 'Visit Report', date: '2026-11-21', summary: '5 doctor visits completed'),
    ReportModel(id: 2, type: 'Order Report', date: '2026-11-20', summary: '3 orders placed, ₹1,200 total'),
    ReportModel(id: 3, type: 'Daily Report', date: '2026-11-19', summary: '6 visits, 2 orders'),
  ];
});