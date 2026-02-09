import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final GeoPoint? geopoint;

  const AddressModel({
    this.street = '',
    this.city = '',
    this.postalCode = '',
    this.country = 'France',
    this.geopoint,
  });

  /// Adresse complète formatée
  String get formatted => '$street, $postalCode $city';

  /// Adresse courte (ville + code postal)
  String get shortFormatted => '$city, $postalCode';

  /// Vérifie si l'adresse est valide (au minimum ville renseignée)
  bool get isValid => city.isNotEmpty;

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? 'France',
      geopoint: map['geopoint'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'geopoint': geopoint,
    };
  }

  AddressModel copyWith({
    String? street,
    String? city,
    String? postalCode,
    String? country,
    GeoPoint? geopoint,
  }) {
    return AddressModel(
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      geopoint: geopoint ?? this.geopoint,
    );
  }

  @override
  List<Object?> get props => [street, city, postalCode, country, geopoint];

  @override
  String toString() => formatted;
}
