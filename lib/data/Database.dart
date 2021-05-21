import 'package:moor/moor.dart';

import 'dao/GroupDao.dart';
import 'dao/NicknameDao.dart';
import 'dao/SettingsDao.dart';
import 'dao/ViveBaseStationDao.dart';
import 'tables/GroupTable.dart';
import 'tables/LastSeenDevicesTable.dart';
import 'tables/NicknameTable.dart';
import 'tables/SimpleSettingsTable.dart';
import 'tables/ViveBaseStationIdTable.dart';

export 'shared/shared.dart';

part 'Database.g.dart';

class NicknamesLastSeenJoin {
  NicknamesLastSeenJoin(this.macAddress, this.nickname, this.lastSeen);

  final String macAddress;
  final String nickname;
  final DateTime? lastSeen;
}

// This file required generated files.
// Use `flutter packages pub run build_runner build`
// or `flutter packages pub run build_runner watch` to generate these files.

@UseMoor(tables: [
  Nicknames,
  LastSeenDevices,
  SimpleSettings,
  ViveBaseStationIds,
  Groups,
  GroupEntries,
], daos: [
  NicknameDao,
  SettingsDao,
  ViveBaseStationDao,
  GroupDao,
])
class LighthouseDatabase extends _$LighthouseDatabase {
  LighthouseDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (Migrator m) {
        return m.createAll();
      }, onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && (to >= 2 && to <= 3)) {
          await m.renameColumn(simpleSettings, 'id', simpleSettings.settingsId);
        }
        if ((from >= 1 && from <= 2) && (to == 3)) {
          await m.createTable(groups);
          await m.createTable(groupEntries);
        }
      }, beforeOpen: (details) async {
        await this.customStatement('PRAGMA foreign_keys = ON');
      });
}
