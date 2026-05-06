import '../models/cpd_activity.dart';
import '../models/recertification_cycle.dart';

class CpdCloudMapper {
  const CpdCloudMapper._();

  static Map<String, dynamic> cycleToCloud(RecertificationCycle cycle) {
    return {
      'id': cycle.id,
      'cycleName': cycle.cycleName,
      'startDate': cycle.startDate,
      'endDate': cycle.endDate,
      'targetPoints': cycle.targetPoints,
      'isActive': cycle.isActive,
      'createdAt': cycle.createdAt,
    };
  }

  static Map<String, dynamic> activityToCloud(CpdActivity activity) {
    return {
      'id': activity.id,
      'cycleId': activity.cycleId,
      'dateLogged': activity.dateLogged,
      'categoryId': activity.categoryId,
      'categoryName': activity.categoryName,
      'subcategory': activity.subcategory,
      'activityDescription': activity.activityDescription,
      'providerName': activity.providerName,
      'durationHours': activity.durationHours,
      'pointsClaimed': activity.pointsClaimed,
      'competencyDomain': activity.competencyDomain,
      'evidenceNote': activity.evidenceNote,
      'deletedAt': activity.deletedAt,
      'createdAt': activity.createdAt,
      'updatedAt': activity.updatedAt,
    };
  }
}
