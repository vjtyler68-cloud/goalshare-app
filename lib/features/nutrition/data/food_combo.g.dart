// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_combo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodComboAdapter extends TypeAdapter<FoodCombo> {
  @override
  final int typeId = 18;

  @override
  FoodCombo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodCombo(
      id: fields[0] as String,
      name: fields[1] as String,
      items: (fields[2] as List).cast<FoodItem>(),
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FoodCombo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodComboAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
