/// Aggregated metrics for the admin dashboard (from `admin_overview()` RPC).
library;

class NamedCount {
  final String name;
  final int total;
  const NamedCount({required this.name, required this.total});

  factory NamedCount.fromJson(Map<String, dynamic> j) => NamedCount(
        name: (j['name'] as String?) ?? '—',
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

class AdminOverview {
  final int usersTotal;
  final int usersVerified;
  final int usersNew7d;
  final int productsTotal;
  final int productsActive;
  final int productsSold;
  final int productsDraft;
  final int verifPending;
  final int verifApproved;
  final int verifRejected;
  final int ordersTotal;
  final List<NamedCount> byCategory;
  final List<NamedCount> topSellers;

  const AdminOverview({
    required this.usersTotal,
    required this.usersVerified,
    required this.usersNew7d,
    required this.productsTotal,
    required this.productsActive,
    required this.productsSold,
    required this.productsDraft,
    required this.verifPending,
    required this.verifApproved,
    required this.verifRejected,
    required this.ordersTotal,
    required this.byCategory,
    required this.topSellers,
  });

  /// % of users that are verified (0..100).
  double get verifiedRate =>
      usersTotal == 0 ? 0 : (usersVerified / usersTotal) * 100;

  static int _i(Map<String, dynamic> j, String k) =>
      (j[k] as num?)?.toInt() ?? 0;

  static List<NamedCount> _list(Map<String, dynamic> j, String k) =>
      ((j[k] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(NamedCount.fromJson)
          .toList();

  factory AdminOverview.fromJson(Map<String, dynamic> j) => AdminOverview(
        usersTotal: _i(j, 'users_total'),
        usersVerified: _i(j, 'users_verified'),
        usersNew7d: _i(j, 'users_new_7d'),
        productsTotal: _i(j, 'products_total'),
        productsActive: _i(j, 'products_active'),
        productsSold: _i(j, 'products_sold'),
        productsDraft: _i(j, 'products_draft'),
        verifPending: _i(j, 'verif_pending'),
        verifApproved: _i(j, 'verif_approved'),
        verifRejected: _i(j, 'verif_rejected'),
        ordersTotal: _i(j, 'orders_total'),
        byCategory: _list(j, 'by_category'),
        topSellers: _list(j, 'top_sellers'),
      );
}
