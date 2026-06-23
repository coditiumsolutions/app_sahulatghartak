import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/booking.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'sahulat_ghar_tak.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT,
        mobile TEXT,
        address TEXT,
        city TEXT,
        serviceName TEXT,
        serviceDate TEXT,
        serviceTime TEXT,
        notes TEXT
      )
    ''');
  }

  Future<int> insertBooking(Booking booking) async {
    final database = await db;
    return await database.insert('bookings', booking.toMap());
  }

  Future<List<Booking>> getBookings() async {
    final database = await db;
    final maps = await database.query('bookings', orderBy: 'id DESC');
    return maps.map((m) => Booking.fromMap(m)).toList();
  }
}
