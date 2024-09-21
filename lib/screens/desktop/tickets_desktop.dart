import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:park_in_web/components/navbar/navbar_desktop.dart';
import 'package:park_in_web/components/theme/color_scheme.dart';
import 'package:intl/intl.dart';

class TicketsDesktopScreen extends StatefulWidget {
  const TicketsDesktopScreen({super.key});

  @override
  State<TicketsDesktopScreen> createState() => _TicketsDesktopScreenState();
}

class _TicketsDesktopScreenState extends State<TicketsDesktopScreen> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List to hold fetched tickets
  List<Map<String, dynamic>> tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenForTicketUpdates(); // Fetch data when the screen is initialized
  }

  // Fetch reports from Firestore
  void _listenForTicketUpdates() {
    _firestore.collection('Violation Ticket').snapshots().listen((snapshot) {
      setState(() {
        tickets = snapshot.docs.map((doc) {
          Map<String, dynamic> ticketData = doc.data() as Map<String, dynamic>;
          ticketData['docID'] = doc.id; // Add docID to the ticket data
          return ticketData;
        }).toList();

        // Sorting tickets by timestamp
        tickets.sort((a, b) {
          DateTime dateA = (a['timestamp'] as Timestamp).toDate();
          DateTime dateB = (b['timestamp'] as Timestamp).toDate();
          return dateA.compareTo(dateB); // Sort in ascending order
        });

        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: ListView(
        children: [
          const NavbarDesktop(),
          const SizedBox(
            height: 28,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            // height: MediaQuery.of(context).size.height * 0.8,
            margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1),
            child: Theme(
              data: Theme.of(context).copyWith(
                dataTableTheme: DataTableThemeData(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: whiteColor,
                  ),
                  dividerThickness: 0.3,
                  headingRowColor:
                      WidgetStateColor.resolveWith((states) => whiteColor),
                  dataRowColor:
                      WidgetStateColor.resolveWith((states) => whiteColor),
                  headingTextStyle: const TextStyle(
                      color: blackColor, fontWeight: FontWeight.w500),
                  dataTextStyle: const TextStyle(color: blackColor),
                ),
              ),
              child: PaginatedDataTable(
                header: const Text(
                  "Tickets Issued",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: blackColor,
                  ),
                ),
                columns: const [
                  DataColumn(label: Text("Ticket ID")),
                  DataColumn(label: Text("Ticketed To")),
                  DataColumn(label: Text("Vehicle Type")),
                  DataColumn(label: Text("Violation")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Date")),
                ],
                source: ReportDataSource(tickets, context),
                rowsPerPage: 11,
                showCheckboxColumn: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportDataSource extends DataTableSource {
  final List<Map<String, dynamic>> tickets;
  final BuildContext context;

  ReportDataSource(this.tickets, this.context);

  @override
  DataRow getRow(int index) {
    final ticket = tickets[index];
    final docID = ticket['docID'] ?? '';
    final ticketedTo = ticket['plate_number'] ?? '';
    final vehicleType = ticket['vehicle_type'] ?? '';
    final violation = ticket['violation'] ?? '';
    final status = ticket['status'] ?? 'Pending';
    final timestamp =
        (ticket['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final imageUrl1 = ticket['close_up_image_url'] ?? '';
    final imageUrl2 = ticket['mid_shot_image_url'] ?? '';
    final imageUrl3 = ticket['wide_shot_image_url'] ?? '';

    final formattedDate = DateFormat('MM/dd/yyyy').format(timestamp);
    final formattedTime =
        DateFormat('hh:mm a').format(timestamp); // 12-hour format
    final formattedDateTime = '$formattedDate at $formattedTime';

    return DataRow(
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(ticketedTo)),
        DataCell(Text(vehicleType)),
        DataCell(Text(violation)),
        DataCell(Text(status)),
        DataCell(Text(formattedDateTime)),
      ],
      onSelectChanged: (selected) {
        if (selected ?? false) {
          _modal(
            context,
            docID,
            ticketedTo,
            vehicleType,
            violation,
            status,
            formattedDateTime,
            imageUrl1,
            imageUrl2,
            imageUrl3,
          );
        }
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => tickets.length;

  @override
  int get selectedRowCount => 0;
}

void _modal(
    BuildContext context,
    String docID,
    String plateNo,
    String vehicleType,
    String violation,
    String status,
    String timestamp,
    String attachmentUrl1,
    String attachmentUrl2,
    String attachmentUrl3) async {
  // query userNumber and mobileNo based on plateNo from Firestore
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userNumber = 'Not available';
  String mobileNo = 'Not available';

  try {
    QuerySnapshot userSnapshot = await _firestore
        .collection('User')
        .where('plateNo', arrayContains: plateNo)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      var userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
      userNumber = userData['userNumber'] ?? 'Not available';
      mobileNo = userData['mobileNo'] ?? 'Not available';
    }
  } catch (e) {
    print('Error fetching user details: $e');
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: whiteColor,
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 0.2, color: blackColor),
            ),
          ),
          child: const Text(
            "Ticket Information",
            style: TextStyle(
              color: blackColor,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 4,
                    children: [
                      const Text(
                        'Ticketed To: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        plateNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '($userNumber)',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 4,
                    children: [
                      const Text(
                        'Phone Number: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        mobileNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    vehicleType,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  const Text(
                    'Violation: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    violation,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 4,
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Attachment/s:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (attachmentUrl1.isNotEmpty)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      width: MediaQuery.of(context).size.width * 0.095,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          attachmentUrl1,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (attachmentUrl2.isNotEmpty)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      width: MediaQuery.of(context).size.width * 0.095,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          attachmentUrl2,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (attachmentUrl3.isNotEmpty)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      width: MediaQuery.of(context).size.width * 0.095,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          attachmentUrl3,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              "Close",
              style: TextStyle(
                color: blueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: status == 'Resolved' ? Colors.grey : blueColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: status == 'Resolved'
                ? null
                : () async {
                    await _firestore
                        .collection('Violation Ticket')
                        .doc(docID)
                        .update({
                      'status': 'Resolved',
                    });

                    Navigator.of(context).pop();
                  },
            child: const Text(
              "Resolve",
              style: TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    },
  );
}
