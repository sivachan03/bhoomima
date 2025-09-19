import 'package:isar/isar.dart';
import '../db/isar_service.dart';

abstract class BaseRepo {
  Future<Isar> get db => IsarService.open();
}