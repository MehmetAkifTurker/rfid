// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:rfid_c72_plugin/rfid_c72_plugin.dart';
// import 'package:rfid_c72_plugin/tag_epc.dart';
// import 'package:rfid_c72_plugin_example/commons/menus/drawer.dart';
// import 'package:rfid_c72_plugin_example/raw_sql.dart';

// const minPowerLevel = 5.0;
// const maxPowerLevel = 30.0;
// const masterTagNo = 1;
// const slaveTagNo = 2;
// final tagType = [
//   {masterTagNo: 'Master Tag'},
//   {slaveTagNo: 'Slave Tag'},
// ];

// class RfidScanner extends StatefulWidget {
//   const RfidScanner({Key? key}) : super(key: key);

//   @override
//   State<RfidScanner> createState() => _RfidScannerState();
// }

// class _RfidScannerState extends State<RfidScanner> {
//   final rawSQL = RawSQL();
//   String _platformVersion = 'Unknown';
//   final bool _isHaveSavedData = false;
//   final bool _isStarted = false;
//   final bool _isEmptyTags = false;
//   bool _isConnected = false;
//   bool _isLoading = true;
//   int _totalEPC = 0, _invalidEPC = 0, _scannedEPC = 0;
//   TextEditingController powerLevel = TextEditingController();
//   double iPowerLevel = minPowerLevel;

//   @override
//   void initState() {
//     getAllDB();
//     getMasters();

//     super.initState();

//     initPlatformState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     closeAll();
//   }

//   void getMasters() async {
//     masterTagList = await rawSQL.getDBOnlyMastersName();
//     masterTagList.insert(0, '');
//     if (masterTagList.isNotEmpty) {
//       selectedMaster = masterTagList[0];
//     }
//   }

// //Hopefully we free memory in the device.
//   closeAll() {
//     RfidC72Plugin.stopScan;
//     RfidC72Plugin.close;
//   }

// // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlatformState() async {
//     String platformVersion;
// // Platform messages may fail, so we use a try/catch PlatformException.
//     try {
//       platformVersion = (await RfidC72Plugin.platformVersion)!;
//     } on PlatformException {
//       platformVersion = 'Failed to get platform version.';
//     }
//     RfidC72Plugin.connectedStatusStream
//         .receiveBroadcastStream()
//         .listen(updateIsConnected);
//     RfidC72Plugin.tagsStatusStream.receiveBroadcastStream().listen(updateTags);
//     await RfidC72Plugin.connect;
// // await UhfC72Plugin.setWorkArea('2');
// // await UhfC72Plugin.setPowerLevel('30');
// // If the widget was removed from the tree while the asynchronous platform
// // message was in flight, we want to discard the reply rather than calling
// // setState to update our non-existent appearance.

//     await RfidC72Plugin.connectBarcode; //connect barcode
//     if (!mounted) return;

//     setState(() {
//       _platformVersion = platformVersion;
//       _isLoading = false;
//     });
//   }

//   List<TagEpc> _data = [];
//   final List<String> _EPC = [];

//   void updateTags(dynamic result) async {
//     setState(() {
//       _data = TagEpc.parseTags(result);
//       _totalEPC = _data.toSet().toList().length;
//     });
//   }

//   void updateIsConnected(dynamic isConnected) {
// //setState(() {
//     _isConnected = isConnected;
// //});
//   }

// // getting the DB List
//   List<Map<String, Object?>> alldbResult = [];
//   void getAllDB() async {
//     alldbResult = await rawSQL.getDB();
//     print('all db results = $alldbResult');
//   }

//   bool isMasterResult = false;
//   int foundMasterNo = 0;
//   List<Map<String, Object?>> dbResult = [];
//   String foundMaster = '';
//   List<Map<String, Object?>> listOfSlavesForSelectedMaster = [];

//   void isMaster() async {
//     isMasterResult = false;
//     foundMasterNo = 0;
//     foundMaster = '';

//     for (TagEpc item in _data) {
//       dbResult = await rawSQL.getDBwithFilter([epcColumn, numberColumn],
//           ['"${item.epc.replaceAll(RegExp('EPC:'), '')}"', '1']);
//     }
//     if (dbResult != null) {
//       if (dbResult.isNotEmpty) {
//         foundMasterNo = dbResult.length;
//         if (foundMasterNo == 1) {
//           if (dbResult[0][numberColumn] == masterTagNo) {
//             isMasterResult = true;
//           }
//           foundMaster = dbResult[0][adColumn].toString();
//         }
//         if (foundMasterNo != 1) {
//           listOfSlavesForSelectedMaster.clear();
//         }
//       }
//     }

//     if (isMasterResult == true) {
//       listOfSlavesForSelectedMaster =
//           await rawSQL.getDBwithFilter([masterColumn], ['"$foundMaster"']);
//     } else {
//       listOfSlavesForSelectedMaster.clear();
//     }
//     print('isMasterReult = $isMasterResult');
//     print('foundMaster = $foundMaster');
//     print('foundMasterNo = $foundMasterNo');
//     print('dbResult = $dbResult');
//     print('list of slaves = $listOfSlavesForSelectedMaster');
//   }

//   bool _isContinuousCall = false;
//   bool _is2dscanCall = false;
//   String scanStatus = '';
//   List<String> masterTagList = [];
//   String selectedMaster = "";
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: const Text(
//             'Tag Add',
//           ),
//           backgroundColor: Colors.red,
//           foregroundColor: Colors.white,
//         ),
//         drawer: commonDrawer(context),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(10.0, 8.0, 0.0, 5.0),
//                 child: Card(
//                   child: Row(
//                     children: [
//                       const Text(
//                         'RFID Gücü',
//                       ),
//                       Slider(
//                         value: iPowerLevel,
//                         min: minPowerLevel,
//                         max: maxPowerLevel,
//                         onChanged: (newValue) async {
//                           String powerLevelString =
//                               iPowerLevel.toInt().toString();

//                           setState(() {
//                             iPowerLevel = newValue;
//                           });
//                           powerLevelString = iPowerLevel.toInt().toString();
//                           await RfidC72Plugin.setPowerLevel(powerLevelString);
//                         },
//                       ),
//                       Text(iPowerLevel.toInt().toString()),
//                     ],
//                   ),
//                 ),
//               ),
//               Text(scanStatus),
//               Card(
//                 child: Row(
//                   children: [
//                     IconButton(
//                       onPressed: () async {
//                         await RfidC72Plugin.startSingle;
//                       },
//                       icon: const Icon(Icons.add),
//                     ),
//                     IconButton(
//                       onPressed: () async {
//                         await RfidC72Plugin.startContinuous;

//                         setState(() {
//                           scanStatus = 'Tarama yapiliyor.';
//                         });
//                       },
//                       icon: const Icon(Icons.search),
//                     ),
//                     IconButton(
//                       onPressed: () async {
//                         await RfidC72Plugin.stop;

//                         setState(() {
//                           scanStatus = 'Tarama durduruldu.';
//                         });
//                       },
//                       icon: const Icon(Icons.stop),
//                     ),
//                     IconButton(
//                       onPressed: () async {
//                         await RfidC72Plugin.clearData;
//                         _data.clear();
//                         listOfSlavesForSelectedMaster.clear();
//                         setState(() {});
//                       },
//                       icon: const Icon(Icons.clear_all),
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 '${_data.length}',
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: _data.length,
//                   itemBuilder: (context, index) {
//                     final item = _data[index];
//                     final epc = item.epc.replaceAll(RegExp('EPC:'), '');

//                     return Card(
//                       child: FutureBuilder<List<Map<String, Object?>>>(
//                         future: rawSQL.getDBwithEPC(epc),
//                         builder: (context, snapshot) {
//                           final textColor = snapshot.hasData
//                               ? (snapshot.data!.isNotEmpty
//                                   ? Colors.white
//                                   : Colors.black)
//                               : Colors.black;
//                           final tileColor = snapshot.hasData
//                               ? (snapshot.data!.isNotEmpty
//                                   ? Colors.grey
//                                   : Colors.white)
//                               : Colors.black;
//                           if (snapshot.hasError) {
//                             print(
//                                 "Error checking EPC: ${snapshot.error}"); // Handle error appropriately (e.g., display error message)
//                           }

//                           String epcName = '';
//                           int epcID = 0;
//                           if (snapshot.hasData) {
//                             final listData = snapshot.data!;
//                             isMaster();

//                             print('list data = $listData');
//                             if (listData.isNotEmpty) {
//                               epcName = listData[0]['ad'].toString();
//                               epcID = int.parse(listData[0]['id'].toString());
//                             }
//                           }

//                           if (snapshot.hasData) {
//                             if (snapshot.data!.isNotEmpty) {
//                               return ListTile(
//                                 title: Text(epc),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'ID: $epcID',
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     Text(
//                                       'Ad: $epcName',
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ],
//                                 ),
//                                 textColor: textColor,
//                                 iconColor: textColor,
//                                 tileColor: tileColor,
//                                 onTap: () async {
//                                   int _selectedValue = 1;

//                                   updateDBMethod(context, snapshot.data![0],
//                                       _selectedValue);
//                                 },
//                               );
//                             } else {
//                               return ListTile(
//                                 title: Text(epc),
//                                 textColor: textColor,
//                                 iconColor: textColor,
//                                 tileColor: tileColor,
//                                 onTap: () async {
//                                   int _selectedValue = 1;

//                                   insertDBMethod(context, item, _selectedValue);
//                                 },
//                               );
//                             }
//                           } else {
//                             return ListTile(
//                               title: Text(epc),
//                               textColor: textColor,
//                               iconColor: textColor,
//                               tileColor: tileColor,
//                               onTap: () async {
//                                 int _selectedValue = 1;

//                                 insertDBMethod(context, item, _selectedValue);
//                               },
//                             );
//                           }
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               Container(
//                 color: Colors.red,
//                 width: MediaQuery.of(context).size.width,
//                 child: const Text(
//                   'Masters Slaves',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               Expanded(
//                   child: ListView.builder(
//                 itemCount: listOfSlavesForSelectedMaster.length,
//                 itemBuilder: (context, index) {
//                   final slave = listOfSlavesForSelectedMaster[index];

//                   return Card(
//                     child: ListTile(
//                       textColor: _data.any((element) {
//                         return element.epc.replaceAll(RegExp('EPC:'), '') ==
//                             slave[epcColumn].toString();
//                       })
//                           ? Colors.green
//                           : Colors.black,
//                       title: Text(slave[adColumn].toString()),
//                       subtitle: Text('EPC: ${slave[epcColumn].toString()}'),
//                     ),
//                   );
//                 },
//               ))
//             ],
//           ),
//         ));
//   }

//   Future<dynamic> insertDBMethod(
//       BuildContext context, TagEpc item, int _selectedValue) {
//     selectedMaster = '';
//     return showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         // Return the content of your popup page
//         TextEditingController adTxtCtrl = TextEditingController();
//         TextEditingController epcTxtCtrl = TextEditingController();
//         TextEditingController turTxtCtrl = TextEditingController();

//         epcTxtCtrl.text = item.epc.replaceAll(RegExp('EPC:'), '');

//         return AlertDialog(
//           title: const Text('DB Add Item'),
//           scrollable: true,
//           content: Column(
//             children: [
//               TextField(
//                 controller: adTxtCtrl,
//                 keyboardType: TextInputType.multiline,
//                 decoration: const InputDecoration(hintText: 'Ad giriniz'),
//               ),
//               TextField(
//                 controller: epcTxtCtrl,
//                 keyboardType: TextInputType.multiline,
//                 decoration: const InputDecoration(hintText: 'EPC'),
//                 enabled: false,
//               ),
//               TextField(
//                 controller: turTxtCtrl,
//                 keyboardType: TextInputType.multiline,
//                 decoration: const InputDecoration(hintText: 'Tur giriniz'),
//               ),
//               DropdownButtonFormField(
//                 value: _selectedValue,
//                 items: tagType
//                     .map((item) => DropdownMenuItem(
//                           value: item.keys.first,
//                           child: Text(item.values.first),
//                         ))
//                     .toList(),
//                 onChanged: ((value) {
//                   setState(() {
//                     _selectedValue = value!;
//                     if (value == masterTagNo) {
//                       selectedMaster = '';
//                     }
//                   });
//                 }),
//               ),
//               DropdownButtonFormField<String>(
//                 // Assign your text list data to the 'items' property
//                 items: masterTagList.map((String item) {
//                   return DropdownMenuItem<String>(
//                     value: item,
//                     child: Text(item),
//                   );
//                 }).toList(),
//                 // Set the initial selected value (optional)
//                 value:
//                     selectedMaster, // Replace with your initial selection variable
//                 // Define a callback function to handle selection changes
//                 onChanged: (String? newSelectedValue) {
//                   setState(() {
//                     selectedMaster = newSelectedValue!;
//                   });
//                 },
//                 // Customize the dropdown button appearance (optional)
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 final data = Data(
//                   ad: adTxtCtrl.text,
//                   epc: epcTxtCtrl.text,
//                   tur: turTxtCtrl.text,
//                   number: _selectedValue,
//                   master: selectedMaster,
//                 );
//                 if (_selectedValue == slaveTagNo && selectedMaster == '') {
//                   showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return const AlertDialog(
//                           title: Text('Uyari!'),
//                           content: Column(
//                             children: [
//                               Text('Slave için bir master tag girin!'),
//                             ],
//                           ),
//                           scrollable: true,
//                         );
//                       });
//                 } else {
//                   await rawSQL.insertDB(data);
//                   masterTagList = await rawSQL.getDBOnlyMastersName();
//                   masterTagList.insert(0, '');
//                   if (masterTagList.isNotEmpty) {
//                     selectedMaster = masterTagList[0];
//                   }
//                 }

//                 setState(() {});
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<dynamic> updateDBMethod(
//       BuildContext context, Map<String, Object?> item, Object? id) {
//     bool masterFound = false;
//     int _selectedValue;
//     return showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         // Return the content of your popup page
//         TextEditingController adTxtCtrl = TextEditingController();
//         TextEditingController epcTxtCtrl = TextEditingController();
//         TextEditingController turTxtCtrl = TextEditingController();

//         adTxtCtrl.text = '${item['ad']}';
//         epcTxtCtrl.text = '${item['epc']}';
//         turTxtCtrl.text = '${item['tur']}';
//         _selectedValue = int.parse(item['number'].toString());

//         // Master silindiğinde ona bağlı slavelerin popuplarında hata olmaması için eklenmiştir.
//         for (String master in masterTagList) {
//           if (master == item['masterTag']) {
//             masterFound = true;
//           } else {
//             masterFound = false;
//           }
//         }
//         if (masterFound == true) {
//           selectedMaster = '${item['masterTag']}';
//         } else {
//           selectedMaster = '';
//         }

//         return AlertDialog(
//           title: const Text('DB Update Item'),
//           scrollable: true,
//           content: Column(
//             children: [
//               TextField(
//                 controller: adTxtCtrl,
//                 keyboardType: TextInputType.multiline,
//                 decoration: const InputDecoration(hintText: 'Ad giriniz'),
//               ),
//               TextField(
//                 controller: epcTxtCtrl,
//                 keyboardType: TextInputType.multiline,
//                 decoration: const InputDecoration(hintText: 'EPC'),
//               ),
//               TextField(
//                 controller: turTxtCtrl,
//                 keyboardType: TextInputType.multiline,
//                 decoration: const InputDecoration(hintText: 'Tur giriniz'),
//               ),
//               DropdownButtonFormField(
//                 value: _selectedValue,
//                 items: tagType
//                     .map((item) => DropdownMenuItem(
//                           value: item.keys.first,
//                           child: Text(item.values.first),
//                         ))
//                     .toList(),
//                 onChanged: ((value) {
//                   setState(() {
//                     _selectedValue = value!;
//                     if (_selectedValue == 1) {
//                       selectedMaster = '';
//                     }
//                   });
//                 }),
//               ),
//               DropdownButtonFormField<String>(
//                 // Assign your text list data to the 'items' property
//                 items: masterTagList.map((String item) {
//                   return DropdownMenuItem<String>(
//                     value: item,
//                     child: Text(item),
//                   );
//                 }).toList(),
//                 // Set the initial selected value (optional)
//                 value:
//                     selectedMaster, // Replace with your initial selection variable
//                 // Define a callback function to handle selection changes
//                 onChanged: (String? newSelectedValue) {
//                   setState(() {
//                     selectedMaster = newSelectedValue!;
//                   });
//                 },
//                 // Customize the dropdown button appearance (optional)
//               )
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 if (_selectedValue == masterTagNo) {
//                   selectedMaster = '';
//                 }
//                 final data = Data(
//                   ad: adTxtCtrl.text,
//                   epc: epcTxtCtrl.text,
//                   tur: turTxtCtrl.text,
//                   number: _selectedValue,
//                   master: selectedMaster,
//                 );

//                 await rawSQL.updateDB(id: id, data: data);
//                 getMasters();
//                 setState(() {});
//               },
//               child: const Text('Update'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
