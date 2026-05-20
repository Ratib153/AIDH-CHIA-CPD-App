/// CHIA CPD category definitions (caps and point rates). Source of truth for UI validation.
const List<Map<String, dynamic>> kCpdCategories = [
  {
    'id': 1,
    'name': 'Educational Events',
    'cap': null,
    'rateDescription': '1 CPD point per hour',
  },
  {
    'id': 2,
    'name': 'Structured Education Courses',
    'cap': 30.0,
    'rateDescription': '1.5 pts/hr (credit-bearing) or 1 pt/hr (non-credit)',
  },
  {
    'id': 3,
    'name': 'Reading of Articles, Journals & Textbooks',
    'cap': 10.0,
    'rateDescription': '0.25 CPD points per article',
  },
  {
    'id': 4,
    'name': 'Presentation',
    'cap': 20.0,
    'rateDescription': '2 pts per 15 min (speaker); 2 pts/hr (panel/poster)',
  },
  {
    'id': 5,
    'name': 'Publication, Research or Content Development',
    'cap': 30.0,
    'rateDescription': 'Varies by type (see guide)',
  },
  {
    'id': 6,
    'name': 'Professional Service',
    'cap': 15.0,
    'rateDescription': '5 CPD points per year of service',
  },
  {
    'id': 7,
    'name': 'Reviewing Publications',
    'cap': 15.0,
    'rateDescription': '0.5–3 CPD points per review',
  },
  {
    'id': 8,
    'name': 'Mentoring',
    'cap': 10.0,
    'rateDescription': '1 CPD point per hour',
  },
  {
    'id': 9,
    'name': 'Discussion Groups',
    'cap': 10.0,
    'rateDescription': '1 CPD point per hour',
  },
  {
    'id': 10,
    'name': 'Workplace Activities',
    'cap': 15.0,
    'rateDescription': 'Use Categories 4 & 5 for guidance',
  },
];

const Map<int, double> kHourlyRateCategories = {
  1: 1.0,
  8: 1.0,
  9: 1.0,
};

const List<Map<String, String>> kCompetencyDomains = [
  {'code': 'A', 'name': 'Health Sciences'},
  {'code': 'B', 'name': 'Information Science'},
  {'code': 'C', 'name': 'Information Technology'},
  {'code': 'D', 'name': 'Leadership and Management'},
  {'code': 'E', 'name': 'Social and Behavioural Sciences'},
  {'code': 'F', 'name': 'Core Health Informatics'},
];
