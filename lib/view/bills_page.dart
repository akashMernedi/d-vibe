import 'package:bill_splitter/model/user.dart';
import 'package:bill_splitter/viewModel/checkPhoneNumber.dart';
import 'package:bill_splitter/viewModel/firebaseDatabase.dart';
import 'package:bill_splitter/view/bill_detail.dart';
import 'package:flutter/material.dart';
import 'package:get_phone_number/get_phone_number.dart';
import '../model/bill.dart';
import '../viewModel/strNumber.dart';

class BillsPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return BillsPageState();
  }
  const BillsPage({super.key});
}

class BillsPageState extends State<BillsPage> {
  @override
  List<Bill>? _billList;
  String phoneNumber = "";

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  Future _fetchData() async {
    phoneNumber = await GetPhoneNumber().get();
    phoneNumber = PhoneChecker().formatPhoneNumber(phoneNumber);
    FirebaseDatabase api = new FirebaseDatabase();
    final usersBill = await api.getBills();
    setState(() => _billList = usersBill);
  }

  Widget build(BuildContext context) {
    if (_billList == null) return Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: _billList!.length,
      itemBuilder: (context, i) =>
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            title: _renderOneBill(_billList![i]),
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (BuildContext) {
                        return BillDetailPage(_billList![i]);
                      }
                  )
              );
            },
          ),
    );
  }

  Widget _renderOneBill(Bill bill) {
    bool iMustSendMoney = phoneNumber == PhoneChecker().formatPhoneNumber(bill.from!.phoneNumber);
    UserApp other = bill.from!;
    if (iMustSendMoney) {
      other = bill.to!;
    }
    String comment = bill.comment;
    if (bill.comment.length > 30) {
      comment = comment.substring(0, 30);
    } else if (bill.comment.length == 0) {
      comment = "...";
    }

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: sendOrReceive(iMustSendMoney),
            title: Row(
              children: [
                Text(other.name),
                Expanded(child: Text("")),
                Text(strNumber().formatNumber(bill.amount.toStringAsFixed(2)), style: TextStyle(fontWeight: FontWeight.bold),)
              ],//
            ),
            subtitle: Text(comment),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const SizedBox(width: 8),
              paidUnpaid(bill.isPay),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8)
        ],
      ),
    );
  }

  Icon sendOrReceive(bool iMustSendMoney) {
    if (!iMustSendMoney) {
      return Icon(Icons.file_open, );
    }
    return Icon(Icons.file_copy, );
  }
  Text paidUnpaid(bool isPay){
    if(isPay){
      return Text("paid",style: TextStyle(color: Colors.grey),);
    }
    return Text("unpaid", style: TextStyle(color: Colors.redAccent.shade200),);
  }
}