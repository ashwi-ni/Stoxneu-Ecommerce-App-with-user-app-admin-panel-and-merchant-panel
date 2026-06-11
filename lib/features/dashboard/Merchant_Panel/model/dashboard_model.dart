class DashboardModel {
  final int totalOrders;
  final double revenue;
  final int totalProducts;
  final int pendingOrders;

  DashboardModel({
    required this.totalOrders,
    required this.revenue,
    required this.totalProducts,
    required this.pendingOrders,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalOrders: json['totalOrders'],
      revenue: double.parse(json['revenue'].toString()),
      totalProducts: json['totalProducts'],
      pendingOrders: json['pendingOrders'],
    );
  }
}