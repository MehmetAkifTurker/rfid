import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rfid_c72_plugin_example/common/menus/drawer.dart';
import 'package:rfid_c72_plugin_example/raw_sql.dart';
import 'package:rfid_c72_plugin_example/rfid_scanner.dart';
import 'package:intl/intl.dart';
import 'package:rfid_c72_plugin_example/common/constants.dart';

class SQLList extends StatefulWidget {
  const SQLList({super.key});

  @override
  State<SQLList> createState() => _SQLListState();
}

class _SQLListState extends State<SQLList> {
  List<String> masterTagList = [];
  String selectedMaster = "";
  bool masterFound = false;
  @override
  void initState() {
    getMasters();
    super.initState();
  }

  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    // Show the date picker dialog
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void getMasters() async {
    masterTagList = await rawSQL.getDBOnlyMastersName();
    masterTagList.insert(0, '');
    if (masterTagList.isNotEmpty) {
      selectedMaster = masterTagList[0];
    }
  }

  final rawSQL = RawSQL();
  int _selectedValue = 1;
  final tagType = [
    {1: 'Master Tag'},
    {2: 'Slave Tag'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DB List'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        // actions: [
        //   IconButton(
        //       onPressed: () async {
        //         rawSQL.deleteTable();
        //       },
        //       icon: const Icon(Icons.delete_forever)),
        // ],
      ),
      drawer: commonDrawer(context),
      body: getFilteredDB(),
    );
  }

  FutureBuilder<List<Map<String, Object?>>> getFilteredDB(
      [List<String>? columnNames, List<String>? values]) {
    return FutureBuilder(
      future: rawSQL.getDBwithFilter(columnNames, values),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              // Access data from the map using column names from your query
              final id = item['id']; // Assuming 'id' is a column name
              final title = item['ad'];
              final type = item[turColumn];
              final master = item['masterTag'];
              final epc = item['epc'];
              final backColor =
                  item['number'] == 1 ? Colors.grey : Colors.white;
              final textColor =
                  item['number'] == 1 ? Colors.white : Colors.black;
              // Assuming 'title' is a column name
              return ListTile(
                tileColor: backColor,
                iconColor: textColor,
                textColor: textColor,
                title: Text(
                  title.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: $id',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Master: $master',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Type: $type',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$epc',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: IconButton(
                    onPressed: () {
                      updateDBMethod(context, item, id);
                    },
                    icon: const Icon(Icons.arrow_right_rounded)),
                leading: IconButton(
                    onPressed: () async {
                      final masters = await rawSQL.getDBOnlyMastersName();
                    },
                    icon: const Icon(Icons.menu_rounded)),
                onLongPress: () {
                  rawSQL.deleteFromDB(id: id);
                  setState(() {});
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<dynamic> updateDBMethod(
      BuildContext context, Map<String, Object?> item, Object? id) {
    bool masterFound = false;
    //sadece ilk açılışta atama yapılabilmesi için buraya taşınmıştır.
    int selectedValue = int.parse(item['number'].toString());
    DateTime? selectedDate;
    selectedDate =
        item[expDateColumn] != null && item[expDateColumn].toString() != ''
            ? DateTime.parse(item[expDateColumn].toString())
            : null;
    String selectedDateString = selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(selectedDate)
        : 'Select expire date';
    TextEditingController adTxtCtrl = TextEditingController();
    TextEditingController epcTxtCtrl = TextEditingController();
    TextEditingController turTxtCtrl = TextEditingController();
    adTxtCtrl.text = '${item['ad']}';
    epcTxtCtrl.text = '${item['epc']}';
    turTxtCtrl.text = '${item['tur']}';
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Return the content of your popup page

          //log('master Tag = ${item['masterTag'].toString()}');

          // Master silindiğinde ona bağlı slavelerin popuplarında hata olmaması için eklenmiştir.
          for (String master in masterTagList) {
            log('master = $master');
            if (master == item['masterTag']) {
              masterFound = true;
              break;
            } else {
              masterFound = false;
            }
          }

          if (masterFound == true) {
            selectedMaster = '${item['masterTag']}';
          } else {
            selectedMaster = '';
          }
          // log('master found = $masterFound');
          // log(selectedMaster);
          return AlertDialog(
            title: const Text('DB Update Item'),
            scrollable: true,
            content: Column(
              children: [
                TextField(
                  controller: adTxtCtrl,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(hintText: 'Ad giriniz'),
                ),
                TextField(
                  controller: epcTxtCtrl,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(hintText: 'EPC'),
                ),
                TextField(
                  controller: turTxtCtrl,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(hintText: 'Tur giriniz'),
                ),
                DropdownButtonFormField(
                  value: selectedValue,
                  items: tagType
                      .map((item) => DropdownMenuItem(
                            value: item.keys.first,
                            child: Text(item.values.first),
                          ))
                      .toList(),
                  onChanged: ((value) {
                    setState(() {
                      selectedValue = value!;

                      if (value == masterTagNo) {
                        selectedMaster = '';
                      }
                    });
                  }),
                ),
                selectedValue != 1
                    ? DropdownButtonFormField<String>(
                        // Assign your text list data to the 'items' property
                        items: masterTagList.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        // Set the initial selected value (optional)
                        value:
                            selectedMaster, // Replace with your initial selection variable
                        // Define a callback function to handle selection changes
                        onChanged: (String? newSelectedValue) {
                          setState(() {
                            selectedMaster = newSelectedValue!;
                          });
                        },
                        // Customize the dropdown button appearance (optional)
                      )
                    : const Text(''),
                TextButton.icon(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2018, 1),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                      selectedDateString =
                          DateFormat('dd/MM/yyyy').format(pickedDate);
                      setState(() {
                        // selectedDate = pickedDate;
                        // _selectedDateText =
                        //     DateFormat('dd/MM/yyyy').format(pickedDate);
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(selectedDate != null
                      ? selectedDateString
                      : 'Select Date'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (selectedValue == masterTagNo) {
                    selectedMaster = '';
                  }
                  final data = Data(
                    ad: adTxtCtrl.text,
                    epc: epcTxtCtrl.text,
                    tur: turTxtCtrl.text,
                    number: selectedValue,
                    master: selectedMaster,
                    expDate: selectedDate != null
                        ? selectedDate!.toIso8601String()
                        : '',
                  );

                  await rawSQL.updateDB(id: id, data: data);

                  getMasters();

                  setState(() {});
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }
}
