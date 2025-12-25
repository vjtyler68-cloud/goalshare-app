// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_todos.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyTodosAdapter extends TypeAdapter<DailyTodos> {
  @override
  final int typeId = 12;

  @override
  DailyTodos read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyTodos(
      dateKey: fields[0] as String,
      items: (fields[1] as List?)?.cast<TodoItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyTodos obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTodosAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
