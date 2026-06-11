class AddressModel {
  final int id;
  final String name;
  final String phone;
  final String house;
  final String road;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String? landmark;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.house,
    required this.road,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.landmark,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      house: json['house'],
      road: json['road'],
      city: json['city'],
      state: json['state'],
      country: json['country'] ?? 'India',
      pincode: json['pincode'],
      landmark: json['landmark'],
      isDefault: json['isDefault'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id":id,
      "name": name,
      "phone": phone,
      "house": house,
      "road": road,
      "city": city,
      "state": state,
      "country": country,
      "pincode": pincode,
      "landmark": landmark,
      "isDefault": isDefault ? 1 : 0,
    };
  }
  AddressModel copyWith({
    bool? isDefault,
  }) {
    return AddressModel(
      id: id,
      name: name,
      phone: phone,
      house: house,
      road: road,
      city: city,
      state: state,
      country: country,
      pincode: pincode,
      landmark: landmark,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get fullAddress {
    return "$house, $road, $city, $state, $country - $pincode";
  }

}
