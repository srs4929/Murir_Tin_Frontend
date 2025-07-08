import 'package:flutter/material.dart';

class LiveMap extends StatefulWidget {
  const LiveMap({super.key});

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Map')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Center(
      child: Text(
        'Live Map Feature Coming Soon!',
        style: TextStyle(fontSize: 24, color: Colors.blue),
      ),
    );
  }
}
