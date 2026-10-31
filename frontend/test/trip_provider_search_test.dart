import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/presentation/widgets/trip_search_field.dart';
import 'package:fleet_management/providers/trip_provider.dart';

/// Stands in for GET /api/trips: [total] trips (RR-0 is the newest), filtered by q / bilty like the backend,
/// newest first, honouring `limit` (default 50).
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.total);
  final int total;
  final List<Map<String, dynamic>> requests = [];
  Duration Function(Map<String, dynamic> params)? delay;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? body, Future<void>? cancel) async {
    final params = Map<String, dynamic>.from(o.queryParameters);
    requests.add(params);
    final d = delay?.call(params);
    if (d != null) await Future<void>.delayed(d);
    final q = (params['q'] as String?)?.toLowerCase();
    final bilty = (params['bilty'] as String?)?.toLowerCase();
    final limit = (params['limit'] as int?) ?? 50;
    final all = [
      for (var i = 0; i < total; i++) (no: 'RR-$i', rr: 'rlplwmz${4000 + i}', bilty: '${5000 + i}')
    ]
        .where((t) =>
            (q == null || t.no.toLowerCase().contains(q) || t.rr.toLowerCase().contains(q)) &&
            (bilty == null || t.bilty.contains(bilty)))
        .toList();
    final trips = all
        .take(limit)
        .map((t) => '{"id":"${t.no}","trip_number":"${t.no}","rr_trip_number":"${t.rr}","s4_bilty_number":"${t.bilty}",'
            '"origin":"A","destination":"B","load_item":"x","status":"ongoing","organization_id":"org"}')
        .join(',');
    return ResponseBody.fromString(
      '{"total":${all.length},"trips":[$trips]}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeApi extends ApiService {
  _FakeApi(this._d);
  final Dio _d;
  @override
  Dio get dio => _d;
}

TripNotifier _notifier(_FakeAdapter a) {
  final d = Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = a;
  return TripNotifier(_FakeApi(d));
}

const _active = 'ongoing,pending';
Future<void> _pause([int ms = 450]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('the active list opens on the newest 20 only, and knows the full count', () async {
    final a = _FakeAdapter(70);
    final n = _notifier(a);
    await n.loadTrips(statusFilter: _active, rrWeb: true);
    expect(n.state.trips.length, 20);
    expect(n.state.trips.first.tripNumber, 'RR-0');
    expect(n.state.activeTotal, 70, reason: 'the header count is every active trip, not 20');
    expect(a.requests.single['limit'], 20);
    expect(a.requests.single.containsKey('q'), isFalse);
    n.dispose();
  });

  test('typing in the search box asks the server, which reaches trips older than the first 20', () async {
    final a = _FakeAdapter(70);
    final n = _notifier(a);
    await n.loadTrips(statusFilter: _active, rrWeb: true);
    n.setSearch(query: '', bilty: '5065', rrWeb: true);
    await _pause();
    expect(n.state.trips.map((t) => t.tripNumber), ['RR-65']);
    expect(a.requests.last['bilty'], '5065');
    expect(a.requests.last['limit'], 200);
    expect(n.state.activeTotal, 70, reason: 'a search result must not shrink the header count');

    n.setSearch(query: 'rlplwmz4069', bilty: '', rrWeb: true);
    await _pause();
    expect(n.state.trips.map((t) => t.tripNumber), ['RR-69']);
    n.dispose();
  });

  test('only the last keystroke is sent', () async {
    final a = _FakeAdapter(70);
    final n = _notifier(a);
    await n.loadTrips(statusFilter: _active, rrWeb: true);
    final before = a.requests.length;
    for (final text in ['R', 'RR', 'RR-', 'RR-6']) {
      n.setSearch(query: text, bilty: '', rrWeb: true);
      await _pause(60);
    }
    await _pause();
    expect(a.requests.length, before + 1);
    expect(a.requests.last['q'], 'RR-6');
    n.dispose();
  });

  test('refreshes after a search keep the search; clearing it goes back to the newest 20', () async {
    final a = _FakeAdapter(70);
    final n = _notifier(a);
    n.setSearch(query: '', bilty: '5065', rrWeb: true);
    await _pause();
    await n.silentRefresh(statusFilter: _active, rrWeb: true); // the 30-second poll
    expect(a.requests.last['bilty'], '5065');
    expect(n.state.trips.map((t) => t.tripNumber), ['RR-65']);

    n.setSearch(query: '', bilty: '', rrWeb: true);
    await _pause();
    expect(n.state.trips.length, 20);
    expect(a.requests.last.containsKey('bilty'), isFalse);
    n.dispose();
  });

  test('a search with no match gives an empty list, not an error', () async {
    final a = _FakeAdapter(70);
    final n = _notifier(a);
    await n.loadTrips(statusFilter: _active, rrWeb: true);
    n.setSearch(query: 'nothing-like-this', bilty: '', rrWeb: true);
    await _pause();
    expect(n.state.trips, isEmpty);
    expect(n.state.error, isNull);
    expect(n.state.activeTotal, 70);
    n.dispose();
  });

  test('a slow older response never overwrites a newer search', () async {
    final a = _FakeAdapter(70);
    a.delay = (p) => p['q'] == 'RR-1' ? const Duration(milliseconds: 300) : Duration.zero;
    final n = _notifier(a);
    final slow = n.loadTrips(statusFilter: _active, rrWeb: true, query: 'RR-1');
    await _pause(20);
    await n.loadTrips(statusFilter: _active, rrWeb: true, query: 'RR-2');
    await slow;
    expect(n.state.trips.every((t) => t.tripNumber.contains('RR-2')), isTrue);
    n.dispose();
  });

  test('clearSearch forgets the search without a request', () async {
    final a = _FakeAdapter(70);
    final n = _notifier(a);
    await n.loadTrips(statusFilter: _active, rrWeb: true, query: 'RR-6');
    final before = a.requests.length;
    n.clearSearch();
    expect(a.requests.length, before);
    await n.loadTrips(statusFilter: _active, rrWeb: true);
    expect(a.requests.last.containsKey('q'), isFalse);
    expect(a.requests.last['limit'], 20);
    n.dispose();
  });

  test('Records and unfiltered history are not limited or searched', () async {
    final a = _FakeAdapter(70);
    final n = _notifier(a);
    n.setSearch(query: 'RR-6', bilty: '', rrWeb: true);
    await _pause();
    await n.loadTrips(rrOnly: true);
    expect(a.requests.last.containsKey('limit'), isFalse);
    expect(a.requests.last.containsKey('q'), isFalse);
    await n.loadTrips();
    expect(a.requests.last.containsKey('limit'), isFalse);
    await n.loadTrips(statusFilter: 'completed');
    expect(a.requests.last.containsKey('q'), isFalse);
    n.dispose();
  });

  group('latestUnlessSearching', () {
    final trips = List.generate(70, (i) => 'RR-$i');
    test('no search: newest 20', () {
      expect(latestUnlessSearching(trips, '', '').length, 20);
      expect(latestUnlessSearching(trips, '  ', ' ').first, 'RR-0');
    });
    test('short list shown whole', () => expect(latestUnlessSearching(trips.take(7).toList(), '', '').length, 7));
    test('searching shows every match', () {
      expect(latestUnlessSearching(trips, 'RR-', '').length, 70);
      expect(latestUnlessSearching(trips, '', '4089').length, 70);
    });
  });
}
