import 'dart:convert';

import 'package:bill_splitter/model/sharedBill.dart';
import 'package:bill_splitter/model/sharedBillParticipant.dart';
import 'package:bill_splitter/model/transaction.dart';
import 'package:bill_splitter/model/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../viewModel/checkPhoneNumber.dart';
import 'bill.dart';

class Api{
  String firebaseUrl = "https://d-vibe-default-rtdb.europe-west1.firebasedatabase.app/";

  Future<int> getTransactionId() async {
    var response = await http.get(Uri.parse(this.firebaseUrl+'/countTransaction.json'));
    return json.decode(response.body);
  }
  Future<http.Response> createNewTransaction(Transaction transaction, String URL) async {
    // first, we get the bill id
    // but, because bill can be null, we need to check if bill exist
    int billId = -1; //-1 mean that bill is null
    if(transaction.bill != null){
      billId = transaction.bill!.id;
    }
    //then we send a request
    final http.Response response = await http.patch(
      Uri.parse(this.firebaseUrl+URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        transaction.id.toString(): {
          'amount': transaction.amount,
          'billId': billId,
          'comment': transaction.comment,
          'from': PhoneChecker().formatPhoneNumber(transaction.from!.phoneNumber),
          'to': PhoneChecker().formatPhoneNumber(transaction.to!.phoneNumber),
          'timestamp': transaction.dateOfTransaction!.millisecondsSinceEpoch
        }
      }),
    );
    return response;
  }
  Future<http.Response> updateCountTransaction(int newCount) async {
    final http.Response response = await http.patch(
      Uri.parse(this.firebaseUrl+".json"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "countTransaction":newCount
      }),
    );
    return response;
  }
  Future<int> getBillId() async {
    var response = await http.get(Uri.parse(this.firebaseUrl+'/countBill.json'));
    return json.decode(response.body);
  }
  Future<http.Response> updateCountBill(int newCount) async {
    final http.Response response = await http.patch(
      Uri.parse(this.firebaseUrl+".json"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "countBill":newCount
      }),
    );
    return response;
  }
  Future<http.Response> putBill(Bill bill, String URL) async {

    //then we send a request
    final http.Response response = await http.patch(
      Uri.parse(this.firebaseUrl+URL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        bill.id.toString(): {
          'from':PhoneChecker().formatPhoneNumber(bill.from!.phoneNumber),
          'to':PhoneChecker().formatPhoneNumber(bill.to!.phoneNumber),
          'amount':bill.amount,
          'comment':bill.comment,
          'isPay':bill.isPay,
          'timestamp':bill.dateOfCreation!.millisecondsSinceEpoch,
          'sharedbillid':(bill.isSharedBill())?bill.sharedBill!.id:-1,
        }
      }),
    );
    return response;
  }


  Future<List<Transaction>> fetchTransaction(String phoneNumber) async {
    var response = await http.get(Uri.parse(this.firebaseUrl+'users/'+phoneNumber+'/transactions.json'));
    debugPrint(response.body);
    var transactionJson = json.decode(response.body);
    List<Transaction> allTransaction = [];
    if(transactionJson is List){
      transactionJson.forEach((rawTransaction) {
        if(rawTransaction != null){
          double amount = double.parse(rawTransaction["amount"].toString());
          String comment = rawTransaction["comment"].toString();
          //I will update this code to add the name
          UserApp from = UserApp(rawTransaction["from"].toString(), rawTransaction["from"].toString());
          UserApp to = UserApp(rawTransaction["to"].toString(), rawTransaction["to"].toString());
          debugPrint(rawTransaction["timestamp"].toString());
          //final DateTime date = DateTime.fromMicrosecondsSinceEpoch(int.parse(rawTransaction["timestamp"].toString()));
          final DateTime date = DateTime.fromMillisecondsSinceEpoch(1672736467481);
          Transaction transaction = Transaction(from, to, amount, comment, date);
          allTransaction.add(transaction);
        }
      });
    }else{
      transactionJson.forEach((key, rawTransaction) {
        if(rawTransaction != null){
          double amount = double.parse(rawTransaction["amount"].toString());
          String comment = rawTransaction["comment"].toString();
          //I will update this code to add the name
          UserApp from = UserApp(rawTransaction["from"].toString(), rawTransaction["from"].toString());
          UserApp to = UserApp(rawTransaction["to"].toString(), rawTransaction["to"].toString());
          debugPrint(rawTransaction["timestamp"].toString());
          //final DateTime date = DateTime.fromMicrosecondsSinceEpoch(int.parse(rawTransaction["timestamp"].toString()));
          final DateTime date = DateTime.fromMillisecondsSinceEpoch(1672736467481);
          Transaction transaction = Transaction(from, to, amount, comment, date);
          if(rawTransaction["billId"] != -1){
            Bill bill = Bill(to,from,amount,comment,date,true); //Unfortunately, we don't fetch real bill data :(
            bill.id = rawTransaction["billId"];
            transaction.bill = bill;
          }
          allTransaction.add(transaction);
        }
      });
    }

    return allTransaction;
  }
  Future<List<Bill>> fetchBills(String phoneNumber) async {
    var response = await http.get(Uri.parse(this.firebaseUrl+'users/'+phoneNumber+'/bills.json'));
    debugPrint(response.body);
    var billJson = json.decode(response.body);
    print(billJson);
    List<Bill> allBill = [];

    if(billJson is List){
      billJson.forEach((rawBill) {
        if(rawBill != null){
          UserApp from = UserApp(rawBill["from"].toString(), rawBill["from"].toString());
          UserApp to = UserApp(rawBill["to"].toString(), rawBill["to"].toString());
          double amount = double.parse(rawBill["amount"].toString());
          String comment = rawBill["comment"].toString();
          bool isPay = rawBill["isPay"];
          DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(rawBill["timestamp"].toString()));
          Bill bill = Bill(from,to,amount,comment,date,isPay);
          if(rawBill["sharedbillid"] != -1){
            List<SharedBillParticipant> to = [];
            to.add(SharedBillParticipant("","",0,false)); //Unfortunately, we don't fetch sharedBill data :(
            bill.sharedBill = SharedBill(from, to, comment);
            bill.sharedBill!.id = rawBill["sharedbillid"];
          }
          allBill.add(bill);
        }
      });
    }else{
      billJson.forEach((key,rawBill) {
        if(rawBill != null){
          UserApp from = UserApp(rawBill["from"].toString(), rawBill["from"].toString());
          UserApp to = UserApp(rawBill["to"].toString(), rawBill["to"].toString());
          double amount = double.parse(rawBill["amount"].toString());
          String comment = rawBill["comment"].toString();
          bool isPay = rawBill["isPay"];
          DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(rawBill["timestamp"].toString()));
          Bill bill = Bill(from,to,amount,comment,date,isPay);
          if(rawBill["sharedbillid"] != -1){
            List<SharedBillParticipant> to = [];
            to.add(SharedBillParticipant("","",0,false)); //Unfortunately, we don't fetch sharedBill data :(
            bill.sharedBill = SharedBill(from, to, comment);
            bill.sharedBill!.id = rawBill["sharedbillid"];
          }
          allBill.add(bill);
        }
      });
    }

    return allBill;
  }
  Future<http.Response> putSharedBill(SharedBill sharedBill) async {
    //put the list of participant in Map, so that it became easy to add this list on the request
    var participants = Map();
    sharedBill.to!.forEach((participant) {
      var map = {
        'amount':participant.amount,
        'hasPay':participant.hasPay
      };
      participants[PhoneChecker().formatPhoneNumber(participant.user!.phoneNumber)] = map;
    });
    //then we send a request
    final http.Response response = await http.patch(
      Uri.parse(this.firebaseUrl+"/sharedBill.json"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        sharedBill.id.toString(): {
          'from':PhoneChecker().formatPhoneNumber(sharedBill.from!.phoneNumber),
          'comment':sharedBill.comment,
          'to': participants,
        }
      }),
    );
    return response;
  }
  Future<int> getSharedBillId() async {
    var response = await http.get(Uri.parse(this.firebaseUrl+'/countSharedBill.json'));
    return json.decode(response.body);
  }
  Future<http.Response> updateCountSharedBill(int newCount) async {
    final http.Response response = await http.patch(
      Uri.parse(this.firebaseUrl+".json"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "countSharedBill":newCount
      }),
    );
    return response;
  }
  Future<http.Response> paySharedBill(int sharedBillId, String phoneNumber) async {
    final http.Response response = await http.patch(
      Uri.parse(this.firebaseUrl+"/sharedBill/"+sharedBillId.toString()+"/to/"+phoneNumber+".json"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "hasPay":true
      }),
    );
    return response;
  }
}