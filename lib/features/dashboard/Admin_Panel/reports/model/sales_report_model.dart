class SalesReportData {
  final double totalSales;
  final double totalCommission;
  final double vendorShare;
  final int totalProductsSold;
  final int activeVendors;
  final List<Map<String, dynamic>> chartData;
  final List<Map<String, dynamic>> paymentData;
  final List<Map<String, dynamic>> transactions;


  SalesReportData({
    required this.totalSales,
    required this.totalCommission,
    required this.vendorShare,
    required this.totalProductsSold,
    required this.activeVendors,
    required this.chartData,
    required this.paymentData,
    required this.transactions,
  });

  factory SalesReportData.fromJson(Map<String, dynamic> json) {
    // If Node.js returns summary: { ... }
    final summary = json['summary'] ?? {};

    return SalesReportData(
      totalSales: double.tryParse(summary['totalSales']?.toString() ?? '0') ?? 0.0,
      totalCommission: double.tryParse(summary['totalCommission']?.toString() ?? '0') ?? 0.0,
      vendorShare: double.tryParse(summary['vendorShare']?.toString() ?? '0') ?? 0.0,
      totalProductsSold: int.tryParse(summary['totalProductsSold']?.toString() ?? '0') ?? 0,
      activeVendors: int.tryParse(summary['activeVendors']?.toString() ?? '0') ?? 0,
      chartData: List<Map<String, dynamic>>.from(json['chart'] ?? []),
      paymentData: List<Map<String, dynamic>>.from(json['payments'] ?? []),
      transactions: List<Map<String, dynamic>>.from(json['transactions'] ?? []),
    );
  }

}
