// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NutritionGoalAdapter extends TypeAdapter<NutritionGoal> {
  @override
  final int typeId = 16;

  @override
  NutritionGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionGoal(
      dailyCalorieBudget: fields[0] as int,
      proteinTargetG: fields[1] as double?,
      carbsTargetG: fields[2] as double?,
      fatTargetG: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionGoal obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dailyCalorieBudget)
      ..writeByte(1)
      ..write(obj.proteinTargetG)
      ..writeByte(2)
      ..write(obj.carbsTargetG)
      ..writeByte(3)
      ..write(obj.fatTargetG);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
