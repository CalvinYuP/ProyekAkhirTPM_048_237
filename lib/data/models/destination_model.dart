// lib/data/models/destination_model.dart
import 'dart:convert';

class Destination {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price; // dalam IDR
  final double rating;
  final String imageUrl;
  final String address;
  final String openTime;
  final String closeTime;
  final double latitude;
  final double longitude;

  Destination({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.address,
    required this.openTime,
    required this.closeTime,
    required this.latitude,
    required this.longitude,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      address: json['address'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'rating': rating,
      'imageUrl': imageUrl,
      'address': address,
      'openTime': openTime,
      'closeTime': closeTime,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static List<Destination> fromJsonList(String jsonString) {
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((item) => Destination.fromJson(item)).toList();
  }
}