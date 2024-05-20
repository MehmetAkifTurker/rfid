import 'package:flutter/material.dart';

SizedBox commonDrawer(BuildContext context) {
  return SizedBox(
    width: 100.0,
    child: Drawer(
      backgroundColor: Colors.red,
      child: Column(
        children: [
          IconButton(
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/main1', (route) => false);
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/list', (route) => false);
            },
            icon: const Icon(Icons.list),
          ),
          IconButton(
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/check', (route) => false);
            },
            icon: const Icon(Icons.check),
          )
        ],
      ),
    ),
  );
}
