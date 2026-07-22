import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatusPage extends StatelessWidget {
  final String uid;
  const StatusPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {

    final docRef = FirebaseFirestore.instance.collection('logs').doc(uid);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile status'),backgroundColor: Colors.green,foregroundColor: Colors.white,),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snap.data;
          if (doc == null || !doc.exists) return const Center(child: Text('No profile data found'));
          final data = doc.data()!;
          final employee = data['employeeNumber'] ?? '—';
          final id = data['idNumber'] ?? '—';
          final status = data['status'] ?? 'Pending';
          final notes = data['hrNotes'] ?? '';
          final name = data['firstname'] ??'';
          final surname = data['surname'] ??'';


          return Padding(
            padding: const EdgeInsets.all(16.0),
            child:Center(
              child: Container(
                decoration:BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color:  Colors.green,
                ),
                width: 400,
                height: 450,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
               
                      Center(child: Image.asset("images/DefaultPic.png",height: 200,width: 200,)),
                       
                        Text('Employee name     : $name',style: TextStyle(color: Colors.white,fontSize: 20,)),
                                    SizedBox(height: 8),

                Text('Employee surname : $surname',style: TextStyle(color: Colors.white,fontSize: 20,)),
                  SizedBox(height: 8),

                    Text('Employee number   : $employee',style: TextStyle(color: Colors.white,fontSize: 20,)),
                    const SizedBox(height: 8),
                    Text('ID number  : $id',style: TextStyle(color: Colors.white,fontSize: 20),),
                    const SizedBox(height: 16),
                    Row(children: [ Center(child: Text('Status: ',style: TextStyle(color: Colors.white),)), 
                    const SizedBox(width: 8),
                     Center(child: Chip(label: Text(status.toString())))]),
                    if (notes.isNotEmpty) ...[const SizedBox(height: 12), const Text('Notes:'), Text(notes)],
                    
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
