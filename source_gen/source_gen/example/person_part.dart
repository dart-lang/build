part of source_gen.example.person;


@JsonSerializable()
class Order extends Object with _$OrderSerializerMixin {
  int count;
  int itemNumber;
  bool isRushed;

  Order();

  factory Order.fromJson(json) => _$OrderFromJson(json);
}

@JsonSerializable()
const testValue = 12345;
