import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../../Screens/Auth/repository/auth_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Razorpay? _razorpay;
  bool _isLoading = false;
  bool _showTrial = false;
  bool _loadingTrial = false;
  int _selectedPlanIndex = 0;
  bool _isPersonalSegment = true;

  final List<Map<String, dynamic>> _plans = [
    {
      "name": "Premium Monthly",
      "price": 499.00,
      "days": 30,
      "tagline": "Keep charting with expanded commercial access",
      "features": [
        "Unlimited Product Uploads",
        "Priority Support",
        "Advanced Business Analytics",
      ],
    },
    {
      "name": "Premium Yearly",
      "price": 3999.00,
      "days": 365,
      "tagline": "Maximize your structural productivity",
      "features": [
        "Everything in Monthly",
        "Custom Brand Domain Registration",
        "24/7 Dedicated Account Manager",
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initRazorpay();
    }
    _loadTrialStatus();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ---------------- TRIAL ACCESS LOGIC ----------------

  Future<void> _loadTrialStatus() async {
    final repo = context.read<AuthRepository>();
    try {
      final res = await repo.api.get(
        '/merchant/subscription-status',
        headers: {"Authorization": "Bearer ${await repo.getToken()}"},
      );

      if (!mounted) return;
      setState(() {
        _showTrial = res['showTrial'] ?? false;
      });
    } catch (e) {
      debugPrint("Trial status load error: $e");
    }
  }

  Future<void> _startTrial() async {
    if (_loadingTrial) return;
    setState(() => _loadingTrial = true);

    try {
      final repo = context.read<AuthRepository>();
      await repo.api.post(
        '/merchant/start-trial',
        {},
        headers: {"Authorization": "Bearer ${await repo.getToken()}"},
      );

      await repo.loadSubscriptionStatus();
      await _loadTrialStatus();

      if (!mounted) return;
      context.go('/merchant-dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to start trial: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingTrial = false);
    }
  }

  // ---------------- MOBILE SDK PAYMENT CAPTURE ----------------

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final targetPaymentId =
        response.paymentId ?? "pay_${DateTime.now().millisecondsSinceEpoch}";
    await _verifyAndSyncPayment(targetPaymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message ?? 'Cancelled'}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ---------------- UNIFIED INITIATOR & WEB TRANSIT ----------------

  void _startLivePayment() {
    if (_isLoading) return;

    final selectedPlan = _plans[_selectedPlanIndex];
    final repo = context.read<AuthRepository>();

    setState(() => _isLoading = true);

    const razorpayKey = 'rzp_test_SEMaMT8TVnP5xL';
    final amount = (selectedPlan['price'] * 100).toInt();

    _razorpay?.open({
      'key': razorpayKey,
      'amount': amount,
      'name': 'Merchant App',
      'description': 'Subscription Plan Purchase',
      'prefill': {
        'email': repo.email ?? '',
      },
    });
  }

  Future<void> _verifyAndSyncPayment(String paymentId) async {
    final selectedPlan = _plans[_selectedPlanIndex];
    final repo = context.read<AuthRepository>();

    try {
      final token = await repo.getToken();
      await repo.api.post(
        '/merchant/subscription/create',
        {
          "plan": selectedPlan["name"],
          "durationDays": selectedPlan["days"],
          "paymentId": paymentId,
        },
        headers: {"Authorization": "Bearer $token"},
      );

      repo.subscriptionStatus = 'active';
      repo.subscriptionPlan = selectedPlan["name"];
      repo.subscriptionExpiry = DateTime.now().add(
        Duration(days: selectedPlan["days"]),
      );

      await repo.loadSubscriptionStatus();

      if (mounted) {
        context.go('/merchant-dashboard');
      }
    } catch (e) {
      debugPrint("Verification Engine Failure: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment confirmation failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshSubscription() async {
    await context.read<AuthRepository>().loadSubscriptionStatus();
    await _loadTrialStatus();
  }

  // ---------------- DYNAMIC STANDING LAYOUT UI ----------------

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AuthRepository>();
    final status = repo.subscriptionStatus ?? 'none';
    final plan = repo.subscriptionPlan ?? 'No Plan';
    final expiry = repo.subscriptionExpiry;
    final expiryText = expiry != null
        ? DateFormat('dd MMM yyyy').format(expiry)
        : 'N/A';

    return Scaffold(
     // backgroundColor: const Color(0xFF0D0D0D),
      // Matte Black matching background image
      appBar: AppBar(
        title: const Text("Subscription", style: TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
       // backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _refreshSubscription,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(status, plan, expiryText),
            const SizedBox(height: 32),

            const Center(
              child: Text(
                "Choose Your Plan",
                style: TextStyle(color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 32),

            // 🧠 RESPONSIVE HORIZONTAL CARDS ENGINE
            LayoutBuilder(
              builder: (context, constraints) {
                // Count active plans to calculate responsive row spacing blocks
                final totalItems = _plans.length + (_showTrial ? 1 : 0);

                // If screen space is wide enough, put them side-by-side in one row
                if (constraints.maxWidth > 600) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showTrial)
                          Expanded(child: _buildSideBySideTrialCard()),
                        ...List.generate(_plans.length, (index) {
                          return Expanded(
                            child: _buildSideBySidePlanCard(
                              index,
                              _plans[index],
                              _selectedPlanIndex == index,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                } else {
                  // Fallback to crisp vertical stacking for thin mobile hardware layouts
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showTrial) _buildTrialCard(),
                      ...List.generate(_plans.length, (index) {
                        return _buildSideBySidePlanCard(
                          index,
                          _plans[index],
                          _selectedPlanIndex == index,
                        );
                      }),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBySidePlanCard(int index, Map<String, dynamic> plan, bool isSelected) {
    final bool isPremiumYearly = plan["days"] == 365;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan["name"],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPremiumYearly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFF242449),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF5353DE), width: 0.5)),
                    child: const Text("VALUE", style: TextStyle(color: Color(0xFF9696FF), fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "₹${plan["price"].toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: -0.5),
                ),
                Text(
                  " / ${plan["days"]} days",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan["tagline"] ?? "Upgrade to expand your platform usage limits",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _startLivePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: isSelected
                    ? Colors.blue
                    : Colors.grey.shade200,
                foregroundColor: isSelected ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                minimumSize: const Size(double.infinity, 42),
              ),
              child: _isLoading && _selectedPlanIndex == index
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2))
                  : Text(isSelected ? "Pay Active Tier" : "Subscribe", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 16),

            // Unpack layout bullet strings cleanly via mapped iterators
            ...plan["features"].map<Widget>((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.star_border, color: Colors.grey.shade900, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader(String status, String plan, String expiryText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
       // color: const Color(0xFF171717),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Current Status",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: status == 'active' || status == 'trial'
                      ? Colors.green
                      : Colors.amber,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Plan: $plan",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Expires: $expiryText",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🎁 Free Trial Offer",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "FREE",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Unlock 30 days full premium backend dashboard access for ₹0.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadingTrial ? null : _startTrial,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: _loadingTrial
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Start Free Trial",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------- COPIED STANDING CARD ARCHITECTURE ----------------


  Widget _buildSideBySideTrialCard() {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Free Trial", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.shade800, borderRadius: BorderRadius.circular(12)),
                child: const Text("PROMO", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text("₹0", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: -0.5)),
              Text(" / 30 days", style: TextStyle(fontSize: 12, color: Colors.green.shade400)),
            ],
          ),
          const SizedBox(height: 8),
          Text("Test-drive full platform functionality completely free.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3)),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loadingTrial ? null : _startTrial,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: _loadingTrial
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text("Start Trial", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.green.shade900.withOpacity(0.3), height: 1),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.star_border, color: Colors.green.shade700, size: 12),
              const SizedBox(width: 8),
              const Expanded(child: Text("Zero commitment setup", style: TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          ),
        ],
      ),
    );
  }
}
