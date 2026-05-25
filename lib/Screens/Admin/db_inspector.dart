// firestore_auto_inspector.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreAutoInspector extends StatefulWidget {
  const FirestoreAutoInspector({super.key});

  @override
  State<FirestoreAutoInspector> createState() => _FirestoreAutoInspectorState();
}

class _FirestoreAutoInspectorState extends State<FirestoreAutoInspector> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  bool loading = false;
  String jsonOutput = "";
  String error = "";

  @override
  void initState() {
    super.initState();
    loadCollection();
  }

  Future<void> loadCollection() async {
    setState(() {
      loading = true;
      error = "";
      jsonOutput = "";
    });

    try {
      final snapshot = await db.collection("recruiter_requests").get();

      Map<String, dynamic> result = {};

      for (var doc in snapshot.docs) {
        result[doc.id] = sanitize(doc.data());
      }

      final jsonString = const JsonEncoder.withIndent("  ").convert(result);

      setState(() {
        jsonOutput = jsonString;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }

    setState(() {
      loading = false;
    });
  }

  dynamic sanitize(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is GeoPoint) {
      return {"lat": value.latitude, "lng": value.longitude};
    }

    if (value is DocumentReference) {
      return value.path;
    }

    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), sanitize(v)));
    }

    if (value is List) {
      return value.map(sanitize).toList();
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firestore Inspector"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadCollection,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonOutput,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
    );
  }
}
