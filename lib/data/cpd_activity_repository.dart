import '../models/cpd_activity.dart';

class CpdActivityRepository {
  const CpdActivityRepository._();

  static List<CpdActivity> getAllActivities() {
    final createdAt = DateTime.now().toIso8601String();
    return [
      CpdActivity(
        cycleId: 1,
        dateLogged: '2024-10-15',
        categoryId: 1,
        categoryName: 'Educational Events',
        subcategory: 'Conference',
        activityDescription: 'AHIMA Conference 2024',
        providerName: 'AHIMA',
        durationHours: 15,
        pointsClaimed: 15,
        competencyDomain: 'F',
        evidenceNote: 'Attended sessions on clinical informatics and governance.',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      CpdActivity(
        cycleId: 1,
        dateLogged: '2024-09-28',
        categoryId: 2,
        categoryName: 'Structured Education Courses',
        subcategory: '2.2 Non-credit-bearing',
        activityDescription: 'Health Data Analytics Course',
        providerName: 'Online Academy',
        durationHours: 10,
        pointsClaimed: 10,
        competencyDomain: 'B',
        evidenceNote: 'Completed online module with assessment.',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      CpdActivity(
        cycleId: 1,
        dateLogged: '2024-09-10',
        categoryId: 5,
        categoryName: 'Publication, Research or Content Development',
        activityDescription: 'Clinical Documentation Review',
        pointsClaimed: 5,
        competencyDomain: 'C',
        evidenceNote: 'Participated in quality review workshop.',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      CpdActivity(
        cycleId: 1,
        dateLogged: '2024-08-03',
        categoryId: 1,
        categoryName: 'Educational Events',
        subcategory: 'Webinar',
        activityDescription: 'Digital Health Webinar Series',
        providerName: 'AIDH',
        durationHours: 8,
        pointsClaimed: 8,
        competencyDomain: 'D',
        evidenceNote: 'Covered interoperability and data privacy updates.',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      CpdActivity(
        cycleId: 1,
        dateLogged: '2024-07-16',
        categoryId: 8,
        categoryName: 'Mentoring',
        activityDescription: 'Mentoring Junior Analyst',
        durationHours: 6,
        pointsClaimed: 6,
        competencyDomain: 'D',
        evidenceNote: 'Provided monthly mentoring sessions.',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    ];
  }
}
