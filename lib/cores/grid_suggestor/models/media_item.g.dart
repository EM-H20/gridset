// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MediaItemImpl _$$MediaItemImplFromJson(Map<String, dynamic> json) =>
    _$MediaItemImpl(
      id: json['id'] as String,
      type: $enumDecode(_$MediaTypeEnumMap, json['type']),
      aspectRatio: (json['aspectRatio'] as num).toDouble(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$MediaItemImplToJson(_$MediaItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$MediaTypeEnumMap[instance.type]!,
      'aspectRatio': instance.aspectRatio,
      'durationMs': instance.durationMs,
    };

const _$MediaTypeEnumMap = {MediaType.photo: 'photo', MediaType.video: 'video'};
