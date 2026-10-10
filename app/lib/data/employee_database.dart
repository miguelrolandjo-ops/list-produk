import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'employee_database.g.dart';

@DriftDatabase(include: {'employee.drift'})
class EmployeeDatabase extends _$EmployeeDatabase {
  EmployeeDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'employee'));

  @override
  int get schemaVersion => 1;
}
