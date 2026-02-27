import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum Role {
  system('system'),
  user('user'),
  assistant('assistant'),
  tool('tool');

  const Role(this.value);
  final String value;
}
