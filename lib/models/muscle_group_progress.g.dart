// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_group_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MuscleGroupProgressAdapter extends TypeAdapter<MuscleGroupProgress> {
  @override
  final int typeId = 4;

  @override
  MuscleGroupProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MuscleGroupProgress(
      muscleGroup: fields[0] as String,
      xp: fields[1] as double,
      level: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MuscleGroupProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.muscleGroup)
      ..writeByte(1)
      ..write(obj.xp)
      ..writeByte(2)
      ..write(obj.level);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuscleGroupProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
