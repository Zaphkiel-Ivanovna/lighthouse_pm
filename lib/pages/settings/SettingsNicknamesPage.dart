import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lighthouse_pm/bloc.dart';
import 'package:lighthouse_pm/data/Database.dart';
import 'package:lighthouse_pm/lighthouseProvider/ble/DeviceIdentifier.dart';
import 'package:lighthouse_pm/widgets/ContentContainerWidget.dart';
import 'package:lighthouse_pm/widgets/NicknameAlertWidget.dart';
import 'package:toast/toast.dart';

import '../BasePage.dart';

class SettingsNicknamesPage extends BasePage {
  @override
  Widget buildPage(BuildContext context) {
    return _SettingsNicknamesPageContent();
  }
}

class _SettingsNicknamesPageContent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NicknamesPageState();
  }
}

class _NicknamesPageState extends State<_SettingsNicknamesPageContent> {
  final Set<LHDeviceIdentifier> selected = Set();

  void _selectItem(String deviceId) {
    setState(() {
      this.selected.add(LHDeviceIdentifier(deviceId));
    });
  }

  void _deselectItem(String deviceId) {
    setState(() {
      this.selected.remove(LHDeviceIdentifier(deviceId));
    });
  }

  bool _isSelected(String deviceId) {
    return this.selected.contains(LHDeviceIdentifier(deviceId));
  }

  Future _deleteItem(String deviceId) {
    return blocWithoutListen.nicknames.deleteNicknames([deviceId]);
  }

  Future _updateItem(Nickname nickname) {
    return blocWithoutListen.nicknames.insertNickname(nickname);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NicknamesLastSeenJoin>>(
      stream: bloc.nicknames.watchSavedNicknamesWithLastSeen(),
      builder: (BuildContext _,
          AsyncSnapshot<List<NicknamesLastSeenJoin>> snapshot) {
        Widget body = Center(
          child: CircularProgressIndicator(),
        );
        final data = snapshot.data;
        if (data != null) {
          data.sort((a, b) {
            return a.deviceId.compareTo(b.deviceId);
          });
          if (data.isEmpty) {
            body = _EmptyNicknamePage();
          } else {
            body = ContentContainerWidget(
              builder: (context) {
                return _DataNicknamePage(
                  nicknames: data,
                  selecting: selected.isNotEmpty,
                  selectItem: _selectItem,
                  deselectItem: _deselectItem,
                  isSelected: _isSelected,
                  deleteItem: _deleteItem,
                  updateItem: _updateItem,
                );
              },
            );
          }
        }

        if (snapshot.hasError) {
          print(snapshot.error.toString());
          body = Center(
            child: Container(
              color: Colors.red,
              child: ListTile(
                title: Text('Error'),
                subtitle: Text(snapshot.error.toString()),
              ),
            ),
          );
        }

        final Color? scaffoldColor =
            selected.isNotEmpty ? Theme.of(context).selectedRowColor : null;
        final List<Widget> actions = selected.isEmpty
            ? const []
            : [
                IconButton(
                  icon: Icon(Icons.delete),
                  tooltip: 'Delete selected',
                  onPressed: () async {
                    await blocWithoutListen.nicknames
                        .deleteNicknames(selected.map((e) => e.id).toList());
                    setState(() {
                      selected.clear();
                    });
                    Toast.show('Nicknames have been removed!', context);
                  },
                )
              ];
        final Widget? leading = selected.isEmpty
            ? null
            : IconButton(
                tooltip: 'Cancel selection',
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    this.selected.clear();
                  });
                },
              );

        return Scaffold(
            appBar: AppBar(
              title: Text('Nicknames'),
              backgroundColor: scaffoldColor,
              actions: actions,
              leading: leading,
            ),
            body: body);
      },
    );
  }
}

typedef void _SelectItem(String deviceId);
typedef bool _IsSelected(String deviceId);
typedef void _DeselectItem(String deviceId);
typedef Future _DeleteItem(String deviceId);
typedef Future _UpdateItem(Nickname nickname);

class _DataNicknamePage extends StatelessWidget {
  _DataNicknamePage(
      {Key? key,
      required this.selecting,
      required this.nicknames,
      required this.selectItem,
      required this.isSelected,
      required this.deselectItem,
      required this.deleteItem,
      required this.updateItem})
      : super(key: key);

  final bool selecting;
  final List<NicknamesLastSeenJoin> nicknames;
  final _SelectItem selectItem;
  final _IsSelected isSelected;
  final _DeselectItem deselectItem;
  final _DeleteItem deleteItem;
  final _UpdateItem updateItem;

  Future _changeNickname(
      BuildContext context, NicknamesLastSeenJoin oldNickname) async {
    final newNickname = await NicknameAlertWidget.showCustomDialog(context,
        deviceId: oldNickname.deviceId, nickname: oldNickname.nickname);
    if (newNickname != null) {
      if (newNickname.nickname == null) {
        await deleteItem(newNickname.deviceId);
      } else {
        await updateItem(newNickname.toNickname()!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final item = nicknames[index];
        final selected = isSelected(item.deviceId);
        final lastSeen = item.lastSeen;
        return Column(
          children: [
            Container(
              color: selected
                  ? Theme.of(context).selectedRowColor
                  : Colors.transparent,
              child: ListTile(
                title: Text(item.nickname),
                subtitle: Text(
                    '${item.deviceId}${lastSeen != null ? ' | last seen: ' + DateFormat.yMd(Intl.systemLocale).format(lastSeen) : ''}'),
                onLongPress: () {
                  if (!selecting) {
                    selectItem(item.deviceId);
                  } else {
                    _changeNickname(context, item);
                  }
                },
                onTap: () {
                  if (selecting) {
                    if (selected) {
                      deselectItem(item.deviceId);
                    } else {
                      selectItem(item.deviceId);
                    }
                  } else {
                    _changeNickname(context, item);
                  }
                },
              ),
            ),
            Divider()
          ],
        );
      },
      itemCount: nicknames.length,
    );
  }
}

class _EmptyNicknamePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EmptyNicknameState();
  }
}

class _EmptyNicknameState extends State<_EmptyNicknamePage> {
  static const int _TAP_TOP = 10;
  int tapCounter = 0;

  @override
  Widget build(BuildContext context) {
    final Widget blockIcon = kReleaseMode
        ? Icon(Icons.block, size: 120.0)
        : GestureDetector(
            onTap: () {
              if (tapCounter < _TAP_TOP) {
                tapCounter++;
              }
              if (tapCounter < _TAP_TOP && tapCounter > _TAP_TOP - 3) {
                Toast.show(
                    'Just ${_TAP_TOP - tapCounter} left until a fake nicknames are created',
                    context);
              }
              if (tapCounter == _TAP_TOP) {
                //TODO: change the default ids based on the platform!
                blocWithoutListen.nicknames.insertNickname(Nickname(
                    deviceId: "FF:FF:FF:FF:FF:FF",
                    nickname: "This is a test nickname1"));
                blocWithoutListen.nicknames.insertNickname(Nickname(
                    deviceId: "FF:FF:FF:FF:FF:FE",
                    nickname: "This is a test nickname2"));
                blocWithoutListen.nicknames.insertNickname(Nickname(
                    deviceId: "FF:FF:FF:FF:FF:FD",
                    nickname: "This is a test nickname3"));
                blocWithoutListen.nicknames.insertNickname(Nickname(
                    deviceId: "FF:FF:FF:FF:FF:FC",
                    nickname: "This is a test nickname4"));
                Toast.show('Fake nickname created!', context,
                    duration: Toast.lengthShort);
                tapCounter++;
              }
            },
            child: Icon(Icons.block, size: 120.0),
          );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          blockIcon,
          Text(
            'No nicknames given (yet).',
            style: Theme.of(context).textTheme.headline6,
          )
        ],
      ),
    );
  }
}
