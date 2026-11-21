import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';

final reportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  return [
    ReportModel(id: 1, type: 'Visit Report', date: '2026-11-21', summary: '5 doctor visits completed'),
    ReportModel(id: 2, type: 'Order Report', date: '2026-11-20', summary: '3 orders placed, ₹1,200 total'),
    ReportModel(id: 3, type: 'Daily Report', date: '2026-11-19', summary: '6 visits, 2 orders'),
  ];
});