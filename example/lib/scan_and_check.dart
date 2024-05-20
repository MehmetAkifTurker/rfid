import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfid_c72_plugin/rfid_c72_plugin.dart';
import 'package:rfid_c72_plugin/tag_epc.dart';
import 'package:rfid_c72_plugin_example/common/menus/drawer.dart';
import 'package:rfid_c72_plugin_example/raw_sql.dart';
import 'package:rfid_c72_plugin_example/common/constants.dart';

class ScanAndCheckView extends StatefulWidget {
  const ScanAndCheckView({Key? key}) : super(key: key);

  @override
  State<ScanAndCheckView> createState() => _ScanAndCheckViewState();
}

class _ScanAndCheckViewState extends State<ScanAndCheckView> {
  final rawSQL = RawSQL();
  String _platformVersion = 'Unknown';
  final bool _isHaveSavedData = false;
  final bool _isStarted = false;
  final bool _isEmptyTags = false;
  bool _isConnected = false;
  bool _isLoading = true;
  int _totalEPC = 0, _invalidEPC = 0, _scannedEPC = 0;
  TextEditingController powerLevel = TextEditingController();
  double iPowerLevel = minPowerLevel;

  @override
  void initState() {
    getAllDB();
    getMasters();
    initPlatformState();
    setPowerLevel();
    super.initState();
  }

  @override
  void dispose() {
    closeAll();
    super.dispose();
  }

  void getMasters() async {
    masterTagList = await rawSQL.getDBOnlyMastersName();
    masterTagList.insert(0, '');
    if (masterTagList.isNotEmpty) {
      selectedMaster = masterTagList[0];
    }
  }

  void setPowerLevel() async {
    final isConnected = await RfidC72Plugin.isConnected;
    log(isConnected.toString());
    final isStarted = await RfidC72Plugin.isStarted;
    log(isStarted.toString());
    await RfidC72Plugin.setPowerLevel('29');
  }

//Hopefully we free memory in the device.
  closeAll() {
    RfidC72Plugin.stopScan;
    RfidC72Plugin.close;
  }

// Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
// Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = (await RfidC72Plugin.platformVersion)!;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    RfidC72Plugin.connectedStatusStream
        .receiveBroadcastStream()
        .listen(updateIsConnected);
    RfidC72Plugin.tagsStatusStream.receiveBroadcastStream().listen(updateTags);
    await RfidC72Plugin.connect;
// await UhfC72Plugin.setWorkArea('2');
// await UhfC72Plugin.setPowerLevel('30');
// If the widget was removed from the tree while the asynchronous platform
// message was in flight, we want to discard the reply rather than calling
// setState to update our non-existent appearance.

    await RfidC72Plugin.connectBarcode; //connect barcode
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _isLoading = false;
    });
  }

  List<TagEpc> data = [];
  final List<String> EPC = [];

  void updateTags(dynamic result) async {
    setState(() {
      data = TagEpc.parseTags(result);
      _totalEPC = data.toSet().toList().length;
    });
  }

  void updateIsConnected(dynamic isConnected) {
//setState(() {
    _isConnected = isConnected;
//});
  }

// getting the DB List
  List<Map<String, Object?>> alldbResult = [];
  void getAllDB() async {
    alldbResult = await rawSQL.getDB();
  }

  bool isMasterResult = false;
  int foundMasterNo = 0;
  List<Map<String, Object?>> dbResult = [];
  String foundMaster = '';
  List<Map<String, Object?>> listOfSlavesForSelectedMaster = [];
  String foundMasterEPC = '';
  int lengthOfSlaves = 0;
  int lengthOfFoundSlaves = 0;
  int expDateNo = 0;

  void isMaster() async {
    isMasterResult = false;
    foundMasterNo = 0;
    foundMaster = '';
    foundMasterEPC = '';
    lengthOfSlaves = 0;
    lengthOfFoundSlaves = 0;
    expDateNo = 0;
    dbResult.clear();
    for (TagEpc item in data) {
      dbResult.addAll(await rawSQL.getDBwithFilter([epcColumn, numberColumn],
          ['"${item.epc.replaceAll(RegExp('EPC:'), '')}"', '1']));
      log('db result = $dbResult');
    }
    if (dbResult != null) {
      if (dbResult.isNotEmpty) {
        foundMasterNo = dbResult.length;
        if (foundMasterNo == 1) {
          if (dbResult[0][numberColumn] == masterTagNo) {
            isMasterResult = true;
            foundMaster = dbResult[0][adColumn].toString();
            foundMasterEPC = dbResult[0][epcColumn].toString();

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$foundMaster bulundu. Slaveler listeleniyor.')));
          }
        }
        if (foundMasterNo != 1) {
          listOfSlavesForSelectedMaster.clear();
          isMasterResult = false;

          if (foundMasterNo > 1) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Birden fazla master bulundu.')));
          }
        }
      }
      if (foundMasterNo == 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Master bulunamadı.')));
      }
    }

    if (isMasterResult == true) {
      listOfSlavesForSelectedMaster =
          await rawSQL.getDBwithFilter([masterColumn], ['"$foundMaster"']);

      listOfSlavesForSelectedMaster.insertAll(0, dbResult);
      lengthOfSlaves = listOfSlavesForSelectedMaster.length;

      for (Map<String, Object?> slaveSelected
          in listOfSlavesForSelectedMaster) {
        for (TagEpc dataSelected in data) {
          if (slaveSelected[epcColumn] ==
              dataSelected.epc.replaceAll(RegExp('EPC:'), '')) {
            lengthOfFoundSlaves += 1;
          }
        }
        final expDate = DateTime.parse(slaveSelected[expDateColumn].toString());
        final nowTime = DateTime.now();
        if (expDate.isBefore(nowTime)) {
          expDateNo += 1;
        }
      }
    } else {
      listOfSlavesForSelectedMaster.clear();
    }
    setState(() {});
    // log('isMasterReult = $isMasterResult');
    // log('foundMaster = $foundMaster');
    // log('foundMasterNo = $foundMasterNo');
    // log('dbResult = $dbResult');
    // log('list of slaves = $listOfSlavesForSelectedMaster');
    // log('length of slaves = $lengthOfSlaves');
    // log('length of found slaves = $lengthOfFoundSlaves');
    // log('exp Date = $expDateNo');
  }

  //String _selectedDateText = '';

  bool _isContinuousCall = false;
  bool _is2dscanCall = false;
  String scanStatus = '';

  List<String> masterTagList = [];
  String selectedMaster = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Tag Add',
          ),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        drawer: commonDrawer(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(scanStatus),
              Card(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        await RfidC72Plugin.startSingle;
                      },
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      onPressed: () async {
                        await RfidC72Plugin.startContinuous;

                        setState(() {
                          scanStatus = 'Tarama yapiliyor.';
                        });
                      },
                      icon: const Icon(Icons.search),
                    ),
                    IconButton(
                      onPressed: () async {
                        await RfidC72Plugin.stop;

                        setState(() {
                          scanStatus = 'Tarama durduruldu.';
                        });
                      },
                      icon: const Icon(Icons.stop),
                    ),
                    IconButton(
                      onPressed: () async {
                        await RfidC72Plugin.clearData;
                        data.clear();
                        listOfSlavesForSelectedMaster.clear();
                        lengthOfFoundSlaves = 0;
                        lengthOfSlaves = 0;
                        expDateNo = 0;
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_all),
                    ),
                    IconButton(
                      onPressed: () {
                        isMaster();
                        setState(() {});
                      },
                      icon: const Icon(Icons.check),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.black,
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.center,
                child: Text(
                  'Scanned Tags : ${data.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              Container(
                color: Colors.black,
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.center,
                child: const Text(
                  'Masters Slaves',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              expDateNo > 0
                  ? Container(
                      color: Colors.black,
                      width: MediaQuery.of(context).size.width,
                      alignment: Alignment.center,
                      child: Text(
                        'Exp Date : $expDateNo',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : const SizedBox.shrink(),
              //selected master list
              Expanded(
                child: ListView.builder(
                  itemCount: listOfSlavesForSelectedMaster.length,
                  itemBuilder: (context, index) {
                    final slave = listOfSlavesForSelectedMaster[index];
                    final now = DateTime.now();
                    final expDate =
                        DateTime.parse(slave[expDateColumn].toString());
                    final expDateExp = expDate.isAfter(now);

                    log(expDateExp.toString());
                    log(expDateNo.toString());

                    return Card(
                      color: expDateExp ? null : Colors.red,
                      child: Card(
                        color: data.any((element) {
                          return element.epc.replaceAll(RegExp('EPC:'), '') ==
                              slave[epcColumn].toString();
                        })
                            ? Colors.green
                            : Colors.white,
                        child: ListTile(
                          leading: expDateExp
                              ? const SizedBox.shrink()
                              : const Icon(Icons.warning, color: Colors.red),
                          title: Text(slave[adColumn].toString()),
                          subtitle: Text('EPC: ${slave[epcColumn].toString()}'),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                color: Colors.black,
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.center,
                child: Text(
                  'Scan Result $lengthOfFoundSlaves / Database Result $lengthOfSlaves',
                  style: TextStyle(
                      color: lengthOfFoundSlaves == lengthOfSlaves
                          ? Colors.green
                          : Colors.red),
                ),
              ),
            ],
          ),
        ));
  }

  Future<dynamic> insertDBMethod(
      BuildContext context, TagEpc item, int selectedValue) {
    selectedMaster = '';
    TextEditingController adTxtCtrl = TextEditingController();
    TextEditingController epcTxtCtrl = TextEditingController();
    TextEditingController turTxtCtrl = TextEditingController();
    String selectedDateString = 'Select date';
    DateTime? selectedDate;
    epcTxtCtrl.text = item.epc.replaceAll(RegExp('EPC:'), '');
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Return the content of your popup page

          return AlertDialog(
            title: const Text('DB Add Item'),
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
                  enabled: false,
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
                Row(
                  children: [
                    const Icon(Icons.date_range),
                    const Text('Expire Date : '),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2018, 1),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            selectedDateString =
                                DateFormat('dd/MM/yyyy').format(pickedDate);
                          });
                        }
                      },
                      child: Text(
                        selectedDate != null
                            ? selectedDateString
                            : 'Select Date',
                        style: const TextStyle(color: Colors.black),
                      ),
                    )
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
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
                  if (selectedValue == slaveTagNo && selectedMaster == '') {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const AlertDialog(
                            title: Text('Uyari!'),
                            content: Column(
                              children: [
                                Text('Slave için bir master tag girin!'),
                              ],
                            ),
                            scrollable: true,
                          );
                        });
                  } else {
                    await rawSQL.insertDB(data);
                    masterTagList = await rawSQL.getDBOnlyMastersName();
                    masterTagList.insert(0, '');
                    if (masterTagList.isNotEmpty) {
                      selectedMaster = masterTagList[0];
                    }
                  }
                  getAllDB();
                  isMaster();

                  setState(() {});
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
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
                Row(
                  children: [
                    const Icon(Icons.date_range),
                    const Text('Expire Date : '),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2018, 1),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            selectedDateString =
                                DateFormat('dd/MM/yyyy').format(pickedDate);
                          });
                        }
                      },
                      child: Text(
                        selectedDate != null
                            ? selectedDateString
                            : 'Select Date',
                        style: const TextStyle(color: Colors.black),
                      ),
                    )
                  ],
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
                  getAllDB();
                  getMasters();
                  isMaster();
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
