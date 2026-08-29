/// Home + owner detail for an address, pulled from a public property-data
/// provider via our backend. [configured] is false until a data-provider key is
/// set on the server; [found] is false when no record matches the address.
class PropertyDetail {
  final bool configured;
  final bool found;
  final String address;
  final String owner;
  final bool? ownerOccupied;
  final int? yearBuilt;
  final num? squareFootage;
  final num? lotSize;
  final int? bedrooms;
  final num? bathrooms;
  final String? propertyType;
  final num? lastSalePrice;
  final String? lastSaleDate;
  final num? assessedValue;
  final num? estimatedValue;
  final num? estimatedValueLow;
  final num? estimatedValueHigh;

  PropertyDetail({
    this.configured = false,
    this.found = false,
    this.address = '',
    this.owner = '',
    this.ownerOccupied,
    this.yearBuilt,
    this.squareFootage,
    this.lotSize,
    this.bedrooms,
    this.bathrooms,
    this.propertyType,
    this.lastSalePrice,
    this.lastSaleDate,
    this.assessedValue,
    this.estimatedValue,
    this.estimatedValueLow,
    this.estimatedValueHigh,
  });

  factory PropertyDetail.fromResponse(Map<String, dynamic> j) {
    final d = (j['data'] is Map)
        ? Map<String, dynamic>.from(j['data'] as Map)
        : <String, dynamic>{};
    return PropertyDetail._fromData(
      d,
      configured: j['configured'] == true,
      found: j['found'] == true,
    );
  }

  /// Build from just the cached data blob stored on a pin (already known-good).
  factory PropertyDetail.fromData(Map<String, dynamic> d) =>
      PropertyDetail._fromData(d, configured: true, found: true);

  factory PropertyDetail._fromData(
    Map<String, dynamic> d, {
    required bool configured,
    required bool found,
  }) {
    num? n(dynamic v) => v is num ? v : null;
    return PropertyDetail(
      configured: configured,
      found: found,
      address: (d['address'] ?? '').toString(),
      owner: (d['owner'] ?? '').toString(),
      ownerOccupied: d['ownerOccupied'] is bool ? d['ownerOccupied'] as bool : null,
      yearBuilt: (d['yearBuilt'] as num?)?.toInt(),
      squareFootage: n(d['squareFootage']),
      lotSize: n(d['lotSize']),
      bedrooms: (d['bedrooms'] as num?)?.toInt(),
      bathrooms: n(d['bathrooms']),
      propertyType: d['propertyType']?.toString(),
      lastSalePrice: n(d['lastSalePrice']),
      lastSaleDate: d['lastSaleDate']?.toString(),
      assessedValue: n(d['assessedValue']),
      estimatedValue: n(d['estimatedValue']),
      estimatedValueLow: n(d['estimatedValueLow']),
      estimatedValueHigh: n(d['estimatedValueHigh']),
    );
  }

  /// The data blob (inverse of [fromData]) so a looked-up home survives in the
  /// offline pin cache. Rehydrated via [PropertyDetail.fromData].
  Map<String, dynamic> toData() => {
        'address': address,
        'owner': owner,
        if (ownerOccupied != null) 'ownerOccupied': ownerOccupied,
        if (yearBuilt != null) 'yearBuilt': yearBuilt,
        if (squareFootage != null) 'squareFootage': squareFootage,
        if (lotSize != null) 'lotSize': lotSize,
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (bathrooms != null) 'bathrooms': bathrooms,
        if (propertyType != null) 'propertyType': propertyType,
        if (lastSalePrice != null) 'lastSalePrice': lastSalePrice,
        if (lastSaleDate != null) 'lastSaleDate': lastSaleDate,
        if (assessedValue != null) 'assessedValue': assessedValue,
        if (estimatedValue != null) 'estimatedValue': estimatedValue,
        if (estimatedValueLow != null) 'estimatedValueLow': estimatedValueLow,
        if (estimatedValueHigh != null) 'estimatedValueHigh': estimatedValueHigh,
      };

  /// Whether we actually have something worth showing.
  bool get hasAny =>
      found &&
      (owner.isNotEmpty ||
          yearBuilt != null ||
          squareFootage != null ||
          lastSalePrice != null ||
          assessedValue != null ||
          estimatedValue != null ||
          bedrooms != null ||
          bathrooms != null ||
          (propertyType != null && propertyType!.isNotEmpty));
}
