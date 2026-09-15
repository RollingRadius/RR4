import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/receiving_document_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

final receivingDocumentApiProvider = Provider<ReceivingDocumentApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReceivingDocumentApi(apiService);
});
