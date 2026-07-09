// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_gratitude.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyGratitudeAdapter extends TypeAdapter<DailyGratitude> {
  @override
  final int typeId = 14;

  @override
  DailyGratitude read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyGratitude(
      dateKey: fields[0] as String,
      entries: (fields[1] as List?)?.cast<GratitudeEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyGratitude obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.entries);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyGratitudeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
