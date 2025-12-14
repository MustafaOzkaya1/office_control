class RiskAlertPerson {
  final String name;
  final String role;
  final String reason;

  RiskAlertPerson({
    required this.name,
    required this.role,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'reason': reason,
    };
  }

  factory RiskAlertPerson.fromMap(Map<String, dynamic> map) {
    return RiskAlertPerson(
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
    );
  }
}

class StarPerformer {
  final String name;
  final String role;
  final String badge;

  StarPerformer({
    required this.name,
    required this.role,
    required this.badge,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'badge': badge,
    };
  }

  factory StarPerformer.fromMap(Map<String, dynamic> map) {
    return StarPerformer(
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      badge: map['badge'] as String? ?? '',
    );
  }
}

class StrategyMapItem {
  final List<String> kisiler;
  final String neden;
  final String oneri;

  StrategyMapItem({
    required this.kisiler,
    required this.neden,
    required this.oneri,
  });

  Map<String, dynamic> toMap() {
    return {
      'kisiler': kisiler,
      'neden': neden,
      'oneri': oneri,
    };
  }

  factory StrategyMapItem.fromMap(Map<String, dynamic> map) {
    return StrategyMapItem(
      kisiler: (map['kisiler'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      neden: map['neden'] as String? ?? '',
      oneri: map['oneri'] as String? ?? '',
    );
  }
}

class CompanyInsights {
  final List<RiskAlertPerson> riskAlertList;
  final List<StarPerformer> starPerformers;
  final Map<String, StrategyMapItem> strategyMap;
  final List<dynamic> clustersList;
  final int? lastUpdated;

  CompanyInsights({
    required this.riskAlertList,
    required this.starPerformers,
    required this.strategyMap,
    this.clustersList = const [],
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'risk_alert_list': riskAlertList.map((e) => e.toMap()).toList(),
      'star_performers': starPerformers.map((e) => e.toMap()).toList(),
      'strategy_map': strategyMap.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'clusters_list': clustersList,
      'last_updated': lastUpdated,
    };
  }

  factory CompanyInsights.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return CompanyInsights(
        riskAlertList: [],
        starPerformers: [],
        strategyMap: {},
        clustersList: [],
        lastUpdated: null,
      );
    }

    // Parse risk_alert_list
    final riskList = (map['risk_alert_list'] as List<dynamic>?)
            ?.map((e) => RiskAlertPerson.fromMap(
                  Map<String, dynamic>.from(e),
                ))
            .toList() ??
        [];

    // Parse star_performers
    final starList = (map['star_performers'] as List<dynamic>?)
            ?.map((e) => StarPerformer.fromMap(
                  Map<String, dynamic>.from(e),
                ))
            .toList() ??
        [];

    // Parse strategy_map
    final strategyMapData = map['strategy_map'] as Map<dynamic, dynamic>?;
    final strategyMap = <String, StrategyMapItem>{};
    if (strategyMapData != null) {
      strategyMapData.forEach((key, value) {
        strategyMap[key.toString()] = StrategyMapItem.fromMap(
          Map<String, dynamic>.from(value),
        );
      });
    }

    // Parse clusters_list
    final clustersList = map['clusters_list'] as List<dynamic>? ?? [];

    // Parse last_updated
    final lastUpdated = map['last_updated'] as int?;

    return CompanyInsights(
      riskAlertList: riskList,
      starPerformers: starList,
      strategyMap: strategyMap,
      clustersList: clustersList,
      lastUpdated: lastUpdated,
    );
  }
}

