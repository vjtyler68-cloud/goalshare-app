// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logged_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoggedEntryAdapter extends TypeAdapter<LoggedEntry> {
  @override
  final int typeId = 15;

  @override
  LoggedEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoggedEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      meal: fields[2] as String,
      foodItem: fields[3] as FoodItem,
      quantity: fields[4] as double,
      loggedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LoggedEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.meal)
      ..writeByte(3)
      ..write(obj.foodItem)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.loggedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoggedEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
