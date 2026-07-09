// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 13;

  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      gratitudeItems: (fields[2] as List).cast<String>(),
      dayText: fields[3] as String,
      starRating: fields[4] as int,
      mood: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime?,
      edited: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.gratitudeItems)
      ..writeByte(3)
      ..write(obj.dayText)
      ..writeByte(4)
      ..write(obj.starRating)
      ..writeByte(5)
      ..write(obj.mood)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.edited);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
