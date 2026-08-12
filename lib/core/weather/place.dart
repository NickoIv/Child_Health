/// A place, rounded before it goes anywhere.
class Place {
  const Place(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Two decimals, which is about a kilometre.
  ///
  /// Enough for a temperature and not enough for an address. What leaves the
  /// phone is a request for the weather at a point, and the point does not
  /// need to be her building.
  Place get coarse => Place(
    (latitude * 100).roundToDouble() / 100,
    (longitude * 100).roundToDouble() / 100,
  );
}
