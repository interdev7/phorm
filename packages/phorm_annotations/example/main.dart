// Examples print to the console for illustration only.
// ignore_for_file: avoid_print

import 'package:phorm_annotations/phorm_annotations.dart';

// In a real project you annotate your model classes and let `phorm_generator`
// produce the schema, JSON mappers and migrations. The annotations below show
// the declarative surface you work with.
//
// @Schema(
//   tableName: 'users',
//   paranoid: true, // adds soft-delete (deleted_at) support
//   indexes: [Index(columns: ['email'], unique: true)],
//   relationships: [HasMany(model: 'posts', foreignKey: 'user_id')],
// )
// class User {
//   @ID(autoIncrement: true)
//   final int id;
//
//   @Column(unique: true)
//   final String email;
//
//   @Column(nullable: true)
//   final String? name;
//
//   const User(this.id, this.email, this.name);
// }

void main() {
  // Table-level configuration.
  const schema = Schema(
    tableName: 'users',
    paranoid: true,
    indexes: [
      Index(columns: ['email'], unique: true),
    ],
    relationships: [
      HasMany(model: 'posts', foreignKey: 'user_id'),
    ],
  );

  print('table:        ${schema.tableName}');
  print('soft delete:  ${schema.paranoid}');
  print('naming:       ${schema.columnNaming}');
  print('dialect:      ${schema.dialect}');
  print('indexes:      ${schema.indexes.length}');
  print('relations:    ${schema.relationships.length}');

  // Column-level configuration.
  const id = ID(autoIncrement: true);
  const email = Column(unique: true, columnName: 'email_address');
  print('\nprimary key autoIncrement: ${id.autoIncrement}');
  print('email column name:         ${email.columnName}');
  print('email unique:              ${email.unique}');
}
