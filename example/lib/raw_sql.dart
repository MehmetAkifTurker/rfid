import 'dart:developer';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class RawSQL {
  Database? _db;
  String sql = '';

  Future<void> openDB() async {
    var databasesPath = await getApplicationDocumentsDirectory();
    String path = join(databasesPath.path, 'demo.db');

    if (_db != null) {
      throw DBAlreadyOpenException();
    }
    try {
      final db = await openDatabase(path);
      _db = db;
      await db.execute(createTagsTable);
    } catch (e) {
      DBCanNotOpenedException();
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await openDB();
    } on DBAlreadyOpenException {
      // empty
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DBIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DBIsNotOpen();
    } else {
      return db;
    }
  }

  Future<int> insertDB(Data data) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    sql = 'UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME="$tableName"';
    await db.rawQuery(sql);
    sql =
        'INSERT INTO $tableName($adColumn,$epcColumn,$turColumn,$numberColumn,$masterColumn,$expDateColumn) VALUES ("${data.ad}", "${data.epc}", "${data.tur}", ${data.number}, "${data.master}", "${data.expDate}")';
    int id = await db.rawInsert(sql);
    //print(id);
    return id;
  }

  Future<List<Map<String, Object?>>> getDB() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    sql = 'SELECT * FROM $tableName';
    final results = await db.rawQuery(sql);
    return results.toList();
  }

  Future<List<Map<String, Object?>>> getDBwithFilter(
      [List<String>? columnNames, List<String>? values]) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    sql = 'SELECT * FROM $tableName';

    if (columnNames != null &&
        values != null &&
        columnNames.length == values.length) {
      final filterLenght = columnNames.length;
      //  print('FilterLenght = $filterLenght');
      sql = '$sql WHERE';
      for (int i = 0; i <= filterLenght - 1; i++) {
        sql = '$sql ${columnNames[i]} = ${values[i]}';
        if (i < filterLenght - 1) {
          sql = '$sql AND ';
        }
      }
    }
    //final results = await db.rawQuery('SELECT * FROM $tableName');
    final results = await db.rawQuery(sql);
    log(sql);
    //print(results.toList());
    return results.toList();
  }

  // Future<bool> getDBwithEPC(String epc) async {
  //   await _ensureDbIsOpen();
  //   final db = _getDatabaseOrThrow();
  //   sql = 'SELECT * FROM $tableName WHERE $epcColumn = "$epc"';
  //   final results = await db.rawQuery(sql);
  //   return results.isNotEmpty;
  // }

  Future<List<Map<String, Object?>>> getDBwithEPC(String epc) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    sql = 'SELECT * FROM $tableName WHERE $epcColumn = "$epc"';
    final results = await db.rawQuery(sql);
    return results;
  }

  Future<int> deleteFromDB({required Object? id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    sql = 'DELETE FROM $tableName WHERE $idColumn = $id';
    final count = await db.rawQuery(sql);
    return count.length;
  }

  Future<int> updateDB({
    required Object? id,
    required Data data,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    sql =
        'UPDATE $tableName SET $adColumn = "${data.ad}" ,$epcColumn = "${data.epc}" ,$turColumn = "${data.tur}" ,$numberColumn = ${data.number} ,$masterColumn = "${data.master}",$expDateColumn = "${data.expDate}" WHERE $idColumn = $id';
    final result = await db.rawUpdate(sql);
    return result;
  }

  Future<List<String>> getDBOnlyMastersName() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    List<String> masterList = [];
    sql = 'SELECT $adColumn FROM $tableName WHERE $numberColumn = 1';
    final results = await db.rawQuery(sql);
    for (var result in results) {
      masterList.add(result['ad'].toString());
    }
    return masterList;
  }

  // Future<void> deleteTable() async {
  //   await _ensureDbIsOpen();
  //   final db = _getDatabaseOrThrow();
  //   sql = 'DROP TABLE $tableName';
  //   await db.rawQuery(sql);
  // }
}

class Data {
  late int id;
  final String epc;
  final String ad;
  final String tur;
  final int number;
  final String master;
  final String expDate;

  Data({
    required this.ad,
    required this.epc,
    required this.tur,
    required this.number,
    required this.master,
    required this.expDate,
  });
}

const idColumn = 'id';
const epcColumn = 'epc';
const adColumn = 'ad';
const turColumn = 'tur';
const numberColumn = 'number';
const masterColumn = 'masterTag';
const expDateColumn = 'expDate';

const tableName = 'test';
const createTagsTable = ''' CREATE TABLE IF NOT EXISTS "test" (
	"$idColumn"	INTEGER NOT NULL UNIQUE,
  "$epcColumn"	TEXT NOT NULL UNIQUE,
	"$adColumn"	TEXT NOT NULL,
	"$turColumn"	TEXT,
	"$numberColumn"	INTEGER,
  "$masterColumn"	TEXT,
  "$expDateColumn" TEXT,
  
	PRIMARY KEY("$idColumn" AUTOINCREMENT)
);''';

class DBAlreadyOpenException implements Exception {}

class DBNotOpenedException implements Exception {}

class DBCanNotOpenedException implements Exception {}

class DBIsNotOpen implements Exception {}
