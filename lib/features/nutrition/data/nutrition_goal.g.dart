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
      currentWeightLbs: fields[4] as double?,
      goalWeightLbs: fields[5] as double?,
      targetDate: fields[6] as DateTime?,
      targetWeeklyRateLbs: fields[7] as double?,
      ageYears: fields[8] as int?,
      sexMale: fields[9] as bool?,
      heightCm: fields[10] as double?,
      activityLevel: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionGoal obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.dailyCalorieBudget)
      ..writeByte(1)
      ..write(obj.proteinTargetG)
      ..writeByte(2)
      ..write(obj.carbsTargetG)
      ..writeByte(3)
      ..write(obj.fatTargetG)
      ..writeByte(4)
      ..write(obj.currentWeightLbs)
      ..writeByte(5)
      ..write(obj.goalWeightLbs)
      ..writeByte(6)
      ..write(obj.targetDate)
      ..writeByte(7)
      ..write(obj.targetWeeklyRateLbs)
      ..writeByte(8)
      ..write(obj.ageYears)
      ..writeByte(9)
      ..write(obj.sexMale)
      ..writeByte(10)
      ..write(obj.heightCm)
      ..writeByte(11)
      ..write(obj.activityLevel);
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
