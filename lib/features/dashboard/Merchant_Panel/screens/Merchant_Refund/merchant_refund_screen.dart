import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/refund_model.dart';
import 'BLOC/MerchantRefundBloc.dart';
import 'BLOC/MerchantRefundEvent.dart';
import 'BLOC/MerchantRefundState.dart';
import 'merchant_refund_detail_screen.dart';

class MerchantRefundScreen extends StatefulWidget {
  const MerchantRefundScreen({super.key});

  @override
  State<MerchantRefundScreen> createState() => _MerchantRefundScreenState();
}

class _MerchantRefundScreenState extends State<MerchantRefundScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final List<String> tabs = ["Pending", "Approved", "Refunded", "Rejected"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadTabRefunds();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadTabRefunds();
      }
    });
  }

  void _loadTabRefunds() {
    final status = tabs[_tabController.index].toLowerCase();
    context.read<MerchantRefundBloc>().add(LoadRefundRequests(status));
  }

  // STATUS COLOR
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.blue;
      case "refunded":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ICON BUTTON (same as admin)
  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ACTION LOGIC (same as admin)
  Widget _actionButtons(RefundRequest r) {
    final status = r.status.toLowerCase();

    return Row(
      children: [
        // VIEW (always)
        _iconBtn(Icons.visibility, Colors.blue, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RefundDetailScreen(refund: r),
            ),
          );
        }),

        const SizedBox(width: 6),

        // PENDING → APPROVE + REJECT WITH NOTE
        if (status == "pending") ...[
          _iconBtn(Icons.check, Colors.green, () {
            _showNoteDialog(
              title: "Approve Refund",
              color: Colors.green,
              action: "approve",
              refundId: r.id,
            );
          }),

          const SizedBox(width: 6),

          _iconBtn(Icons.close, Colors.red, () {
            _showNoteDialog(
              title: "Reject Refund",
              color: Colors.red,
              action: "reject",
              refundId: r.id,
            );
          }),
        ],

        // APPROVED → only reject
        if (status == "approved") ...[
          _iconBtn(Icons.close, Colors.red, () {
            _showNoteDialog(
              title: "Reject Refund",
              color: Colors.red,
              action: "reject",
              refundId: r.id,
            );
          }),
        ],

        // REJECTED → only approve
        if (status == "rejected") ...[
          _iconBtn(Icons.check, Colors.green, () {
            _showNoteDialog(
              title: "Approve Refund",
              color: Colors.green,
              action: "approve",
              refundId: r.id,
            );
          }),
        ],

        // REFUNDED → NO ACTIONS
      ],
    );
  }

  // TABLE HEADER
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: const [
          Text("Refund Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // TABLE UI (ADMIN STYLE)
  Widget _buildDataTable(List<RefundRequest> refunds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              dataRowMaxHeight: 60,
              columnSpacing: 20,
              headingRowColor:
              WidgetStateProperty.all(const Color(0xffF1F4F9)),
              columns: const [
                DataColumn(label: Text("SL")),
                DataColumn(label: Text("Order ID")),
                DataColumn(label: Text("Qty")),
                DataColumn(label: Text("Amount")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Actions")),
              ],
              rows: refunds.asMap().entries.map((entry) {
                int index = entry.key;
                final r = entry.value;

                return DataRow(cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(Text("#${r.orderId}")),
                  DataCell(Text("${r.quantity}")),
                  DataCell(Text("₹${r.amount.toStringAsFixed(2)}")),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(r.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        r.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(r.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  DataCell(_actionButtons(r)),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: const Text("Refund Requests",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
        ),
      ),
      body: BlocBuilder<MerchantRefundBloc, MerchantRefundState>(
        builder: (context, state) {
          if (state is RefundLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RefundLoaded) {
            return Column(
              children: [
                _buildTableHeader(),
                Expanded(child: _buildDataTable(state.refunds)),
              ],
            );
          } else if (state is RefundError) {
            return Center(child: Text(state.message));
          } else {
            return const Center(child: Text("No Data"));
          }
        },
      ),
    );
  }

  void _showNoteDialog({
    required String title,
    required String action, // approve / reject
    required int refundId,
    required Color color,
  }) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter reason / note...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: () {
        final note = noteController.text.trim();

        if (note.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        content: Text("Note is required"),
        backgroundColor: Colors.red,
        ),
        );
        return;
        }

        Navigator.pop(context);

        _handleRefundAction(
        refundId: refundId,
        action: action,
        note: note,
        );
        },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _handleRefundAction({
    required int refundId,
    required String action,
    required String note,
  }) {
    if (action == "approve") {
      context.read<MerchantRefundBloc>().add(
        ApproveRefundRequest(refundId, note),
      );
    }

    if (action == "reject") {
      context.read<MerchantRefundBloc>().add(
        RejectRefundRequest(refundId, note),
      );
    }

    _loadTabRefunds();
  }
}