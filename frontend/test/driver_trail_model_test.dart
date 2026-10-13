import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_management/data/models/trip_model.dart';

void main() {
  test('DriverTrail parses points and an ok gap with its route', () {
    final trail = DriverTrail.fromJson({
      'points': [
        {'latitude': 26.45, 'longitude': 80.35},
        {'latitude': 26.84, 'longitude': 80.94},
      ],
      'gaps': [
        {
          'index': 0,
          'minutes': 90.0,
          'straight_km': 75.1,
          'status': 'ok',
          'distance_km': 95,
          'route_points': [
            [26.45, 80.35],
            [26.60, 80.60],
            [26.84, 80.94],
          ],
          'provider': 'geoapify',
        },
      ],
    });
    expect(trail.points.length, 2);
    expect(trail.gaps.single.status, 'ok');
    expect(trail.gaps.single.distanceKm, 95.0);
    expect(trail.gaps.single.route[1].longitude, 80.60);
  });

  test('older response without gaps still parses; pending gap has no route', () {
    final old = DriverTrail.fromJson({
      'points': [
        {'latitude': 1.0, 'longitude': 2.0}
      ],
    });
    expect(old.gaps, isEmpty);

    final pending = TrailGap.fromJson({
      'index': 3,
      'minutes': 12,
      'straight_km': 4,
      'status': 'pending',
      'route_points': null,
      'distance_km': null,
      'provider': null,
    });
    expect(pending.route, isEmpty);
    expect(pending.distanceKm, isNull);
  });
}
