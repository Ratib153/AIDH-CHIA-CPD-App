import 'package:flutter/material.dart';

class CategoryDescription {
  final String title;
  final String? cap;
  final String rate;
  final String overview;
  final List<String> eligibleActivities;
  final List<String> ineligibleActivities;
  final List<PointsGuideEntry> pointsGuide;
  final List<String> notes;
  final String? eligibilityReminder;
  final IconData icon;
  final Color color;

  const CategoryDescription({
    required this.title,
    this.cap,
    required this.rate,
    required this.overview,
    required this.eligibleActivities,
    this.ineligibleActivities = const [],
    required this.pointsGuide,
    this.notes = const [],
    this.eligibilityReminder,
    required this.icon,
    required this.color,
  });
}

class PointsGuideEntry {
  final String label;
  final String points;
  const PointsGuideEntry(this.label, this.points);
}

const Map<int, CategoryDescription> kCategoryDescriptions = {
  1: CategoryDescription(
    title: 'Educational Events',
    cap: null,
    rate: '1 CPD point per hour',
    overview:
        'Attendance at educational events directly related to health informatics '
        'and digital health. Events must be educational in nature — promotional '
        'events such as vendor product demonstrations do not qualify.',
    eligibleActivities: [
      'Conferences (national and international)',
      'Seminars',
      'Workshops',
      'Webinars — live or recorded',
      'Podcasts',
      'Vodcasts',
      'Symposia and forums',
      'AIDH events and summits',
    ],
    ineligibleActivities: [
      'Webinars or events that primarily promote a specific product or technology',
      'Vendor-sponsored product demonstrations',
      'Sales or marketing presentations',
    ],
    pointsGuide: [
      PointsGuideEntry('1 hour of attendance', '1.0 pt'),
      PointsGuideEntry('Half-day event (~4 hrs)', '4.0 pts'),
      PointsGuideEntry('Full-day event (~7 hrs)', '7.0 pts'),
      PointsGuideEntry('2-day conference (~14 hrs)', '14.0 pts'),
    ],
    notes: [
      'This category is uncapped — you may claim as many points as hours attended.',
      'Both in-person and virtual attendance are eligible.',
      'You do not need to attend the full event to claim — claim only the hours attended.',
      'Retain your ticket, registration confirmation, or attendance certificate as evidence.',
    ],
    eligibilityReminder:
        'You must confirm the event was educational, not promotional, before saving.',
    icon: Icons.event,
    color: Color(0xFF0082C8),
  ),
  2: CategoryDescription(
    title: 'Structured Education Courses',
    cap: '30 pts',
    rate: '1.5 pts/hr (credit-bearing) · 1 pt/hr (non-credit)',
    overview:
        'Formal or structured learning undertaken through an accredited or reputable '
        'provider. Two sub-types apply with different point rates. For face-to-face '
        'courses, only contact hours attract CPD (lectures, tutorials, workshops). '
        'For online or hybrid courses, approximate the actual hours of study completed.',
    eligibleActivities: [
      '2.1 Credit-bearing: University subjects and units',
      '2.1 Credit-bearing: Post-secondary vocational courses (e.g. TAFE)',
      '2.1 Credit-bearing: MOOCs attracting academic credit',
      '2.1 Credit-bearing: Microcredentials with formal credit towards a qualification',
      '2.2 Non-credit: Standalone short courses from a reputable provider',
      '2.2 Non-credit: Professional development courses (e.g. Coursera, edX, LinkedIn Learning)',
      '2.2 Non-credit: MOOCs and microcredentials with no formal credit',
      '2.2 Non-credit: AIDH professional development courses',
    ],
    ineligibleActivities: [
      'Self-directed reading not structured as a course',
      'Watching random YouTube videos or informal online content',
      'Courses unrelated to health informatics or the competency framework',
    ],
    pointsGuide: [
      PointsGuideEntry('1 hr credit-bearing course', '1.5 pts'),
      PointsGuideEntry('1 hr non-credit course', '1.0 pt'),
      PointsGuideEntry('10 hr non-credit course', '10.0 pts'),
      PointsGuideEntry('20 hr credit-bearing course', '30.0 pts (at cap)'),
    ],
    notes: [
      'Cap is 30 points total across both sub-types for the entire 3-year cycle.',
      'If a course advertises its own CPD hours, you may use that figure.',
      'Otherwise, estimate the actual hours of study you completed.',
      'Retain your enrolment confirmation, transcript, or certificate of completion.',
    ],
    icon: Icons.school,
    color: Color(0xFF7C3AED),
  ),
  3: CategoryDescription(
    title: 'Reading of Articles, Journals & Textbooks',
    cap: '10 pts',
    rate: '0.25 CPD points per article / chapter / item',
    overview:
        'Self-directed reading of relevant professional publications to stay current '
        'with developments in health informatics, digital health, and related fields. '
        'Content must be over 600 words and published in a professional publication.',
    eligibleActivities: [
      'Peer-reviewed journal articles (e.g. JAMIA, IJMI, Applied Clinical Informatics)',
      'Textbook chapters',
      'Professional newsletter articles',
      'Educational blogs over 600 words published in a professional industry publication',
      'Government or peak body reports and whitepapers (read for learning)',
      'AIDH publications and digital health reports',
    ],
    ineligibleActivities: [
      'Social media posts (LinkedIn, Twitter/X, etc.)',
      'News articles or general media (not professional publications)',
      'Content under 600 words',
      'Marketing or promotional materials',
      'Internal workplace documents not intended as professional publications',
    ],
    pointsGuide: [
      PointsGuideEntry('1 article / chapter', '0.25 pts'),
      PointsGuideEntry('4 articles', '1.0 pt'),
      PointsGuideEntry('20 articles', '5.0 pts'),
      PointsGuideEntry('40 articles (cap)', '10.0 pts'),
    ],
    notes: [
      'Cap is 10 points (equivalent to 40 qualifying items) per 3-year cycle.',
      'You do not need to note every article individually — you can log a batch.',
      'Retain a reading list, screenshots, or PDF copies as evidence if audited.',
      'Content must be relevant to health informatics and the AHICF competency framework.',
    ],
    icon: Icons.menu_book,
    color: Color(0xFF059669),
  ),
  4: CategoryDescription(
    title: 'Presentation',
    cap: '20 pts',
    rate: '2 pts per 15 min (speaker/lecturer) · 2 pts per hour (panel/poster)',
    overview:
        'Preparing for and delivering new, original work to an audience. The focus '
        'is on the effort involved in creating and presenting original content. '
        'Repeated presentations of the same content to different audiences are '
        'NOT eligible — each presentation must be substantively new or updated.',
    eligibleActivities: [
      'Speaker at a conference, seminar, workshop, webinar, podcast or vodcast',
      'Guest lecturer for a university or TAFE course',
      'Panel participant (active speaking contribution)',
      'Chair of a panel or session',
      'Poster presentation at a conference or event',
    ],
    ineligibleActivities: [
      'Repeated presentations of the same content (even to different audiences)',
      'Attendance at a panel without speaking',
      'Exhibiting at a conference or trade show',
      'Internal staff meetings or briefings (use Category 10 instead)',
    ],
    pointsGuide: [
      PointsGuideEntry('15-min conference talk', '2.0 pts'),
      PointsGuideEntry('30-min webinar speaker', '4.0 pts'),
      PointsGuideEntry('1-hr keynote', '8.0 pts'),
      PointsGuideEntry('Panel participant (1 hr)', '2.0 pts'),
      PointsGuideEntry('Poster presentation (1 hr)', '2.0 pts'),
    ],
    notes: [
      'Cap is 20 points per 3-year cycle.',
      'Points are for the presentation time itself, not preparation time.',
      'Retain your conference program, webinar recording link, or invitation as evidence.',
      'Each new or substantially updated presentation is a separate eligible activity.',
    ],
    eligibilityReminder:
        'You must confirm this is new, original content and not a repeat presentation.',
    icon: Icons.present_to_all,
    color: Color(0xFFF59E0B),
  ),
  5: CategoryDescription(
    title: 'Publication, Research or Content Development',
    cap: '30 pts',
    rate: 'Fixed points by publication type (see guide below)',
    overview:
        'Original work created and disseminated to the public or professional '
        'community by written or electronic means. You must be the author, '
        'co-author, editor, or co-editor of the work. Points are fixed by '
        'publication type regardless of length (except education content and exam items).',
    eligibleActivities: [
      'Book or textbook (author/co-author/editor)',
      'Book or textbook chapter',
      'Article published in a peer-reviewed journal',
      'Article published in a professional newsletter, whitepaper, or government report',
      'Article or blog over 600 words published in a professional industry publication',
      'Writing items for the CHIA examination or similar health informatics certification',
      'Primary author for content used in a formal education program',
    ],
    ineligibleActivities: [
      'Works where you are not named as author, co-author, or editor',
      'Internal documents not published externally',
      'Social media posts',
      'Content under 600 words (for blog/article type)',
    ],
    pointsGuide: [
      PointsGuideEntry('Book / textbook', '30 pts'),
      PointsGuideEntry('Book / textbook chapter', '10 pts'),
      PointsGuideEntry('Peer-reviewed journal article', '8 pts'),
      PointsGuideEntry('Professional newsletter / whitepaper / government report', '5 pts'),
      PointsGuideEntry('Article or blog >600w in professional publication', '1 pt'),
      PointsGuideEntry('CHIA exam item (per item written)', '1 pt per item'),
      PointsGuideEntry('Formal education content (primary author)', '10 pts per 100 hrs of content'),
    ],
    notes: [
      'Cap is 30 points per 3-year cycle.',
      'Co-authorship is eligible — you do not need to be the sole author.',
      'Retain a copy of the publication, acceptance email, or ISBN/DOI as evidence.',
      'For exam items, retain confirmation from the exam body.',
    ],
    icon: Icons.article_outlined,
    color: Color(0xFFDC2626),
  ),
  6: CategoryDescription(
    title: 'Professional Service',
    cap: '15 pts',
    rate: '5 CPD points per year of service',
    overview:
        'Volunteer service with a professional organisation or society related to '
        'health informatics, at any level — international, national, state/territory, '
        'or local. Service must be voluntary and related to health informatics or '
        'digital health. Paid employment in an organisation does not count.',
    eligibleActivities: [
      'Board member of a health informatics professional organisation',
      'Committee member (e.g. AIDH committees, HIMAA, HiNZ)',
      'Member of a working group or task force',
      'Member of an advisory panel',
      'CHIA Examination Committee member',
      'Volunteer organiser for a health informatics conference or event',
      'Member of an accreditation or standards body related to health informatics',
    ],
    ineligibleActivities: [
      'Paid roles in professional organisations',
      'Service on committees unrelated to health informatics or digital health',
      'Attending (not participating in) organisation meetings',
    ],
    pointsGuide: [
      PointsGuideEntry('1 year of service in a role', '5 pts'),
      PointsGuideEntry('2 years of service', '10 pts'),
      PointsGuideEntry('3 years of service (cap)', '15 pts'),
      PointsGuideEntry('Multiple roles in same year', 'Claim separately per role'),
    ],
    notes: [
      'Cap is 15 points per 3-year cycle.',
      'You may claim for multiple simultaneous roles — each role is a separate entry.',
      'Partial years can be claimed — round to the nearest 0.5 year.',
      'Retain a letter of appointment, committee terms of reference, or email confirmation.',
      'Example eligible organisations: AIDH, HIMAA, HiNZ, IMIA, HIKM, HIMSS, AMIA, APAMI.',
    ],
    icon: Icons.groups,
    color: Color(0xFF0891B2),
  ),
  7: CategoryDescription(
    title: 'Reviewing Publications',
    cap: '15 pts',
    rate: 'Fixed points by review type (see guide below)',
    overview:
        'Peer review activities for health informatics publications, conferences, '
        'and academic works. The review must be a substantive expert assessment — '
        'not just reading a paper, but providing written feedback and evaluation '
        'to the author or publisher.',
    eligibleActivities: [
      'Review of conference abstract submissions',
      'Review of conference full paper submissions',
      'Review of health informatics journal article submissions',
      'Editorial review (acting as editor) for a health informatics journal',
      "Review of Master's or Doctoral theses",
    ],
    ineligibleActivities: [
      'Reading published papers for your own learning (use Category 3)',
      "Casual or informal feedback on a colleague's draft",
      'Reviews for conferences or journals unrelated to health informatics',
    ],
    pointsGuide: [
      PointsGuideEntry('Conference abstract review (per abstract)', '0.5 pts'),
      PointsGuideEntry('Conference full paper review (per paper)', '1.0 pt'),
      PointsGuideEntry('Health informatics journal article review', '1.5 pts'),
      PointsGuideEntry('Editorial review for a journal (per issue/article)', '2.0 pts'),
      PointsGuideEntry("Master's or Doctoral thesis review", '3.0 pts'),
    ],
    notes: [
      'Cap is 15 points per 3-year cycle.',
      'Eligible organisations include: AIDH, HIMAA, HiNZ, IMIA, HIKM, HIMSS, AMIA.',
      'Retain the review invitation email or confirmation from the editor/chair.',
      'Each review submission is a separate claimable activity.',
    ],
    icon: Icons.rate_review,
    color: Color(0xFF7C3AED),
  ),
  8: CategoryDescription(
    title: 'Mentoring',
    cap: '10 pts',
    rate: '1 CPD point per hour',
    overview:
        'Professional mentoring related to health informatics undertaken through '
        'a structured approach. Both mentors and mentees are eligible to claim '
        'CPD points. The mentoring must have clear learning goals, involve '
        'evaluation of progress, and focus on professional skill development — '
        'informal or casual catch-ups do not qualify.',
    eligibleActivities: [
      'Acting as a mentor in a formal mentoring program (e.g. AIDH mentoring program)',
      'Participating as a mentee in a structured mentoring relationship',
      'Peer mentoring with agreed goals and structured sessions',
      'Mentoring a colleague through a career transition into health informatics',
    ],
    ineligibleActivities: [
      'Informal catch-ups or networking coffees without structured goals',
      'General supervision of staff as part of a management role',
      'Mentoring in areas unrelated to health informatics',
    ],
    pointsGuide: [
      PointsGuideEntry('1-hour mentoring session', '1.0 pt'),
      PointsGuideEntry('Monthly 1-hr sessions over 1 year (12 sessions)', '12.0 pts (capped at 10)'),
      PointsGuideEntry('6 × 1-hr sessions', '6.0 pts'),
      PointsGuideEntry('10 × 1-hr sessions (cap)', '10.0 pts'),
    ],
    notes: [
      'Cap is 10 points per 3-year cycle.',
      'Both mentor and mentee can each claim their own CPD points for the same session.',
      'The mentoring must be structured — document learning goals and outcomes.',
      'Retain a record of sessions (dates, duration, topics) signed by both parties if possible.',
      'Mentoring must relate to health informatics and the AHICF competency framework.',
    ],
    eligibilityReminder:
        'You must confirm this mentoring involved a structured approach with clear learning goals and skill development focus.',
    icon: Icons.people,
    color: Color(0xFF059669),
  ),
  9: CategoryDescription(
    title: 'Discussion Groups',
    cap: '10 pts',
    rate: '1 CPD point per hour',
    overview:
        'Participation in discussion groups that focus on advancing professional '
        'practice in health informatics. Attendance must involve active contribution '
        '— not passive listening. The group must be topic-driven with practical '
        'application to professional practice.',
    eligibleActivities: [
      'Peer-to-peer discussion groups',
      'Communities of practice in health informatics or digital health',
      'Journal clubs focused on health informatics literature',
      'Special interest group meetings with active discussion',
      'Online forum participation in structured, topic-driven discussions',
    ],
    ineligibleActivities: [
      'Passive webinar attendance (use Category 1 instead)',
      'General staff meetings without a specific learning focus',
      'Informal social networking events',
      'Listening to a podcast without active discussion or contribution',
    ],
    pointsGuide: [
      PointsGuideEntry('1 hour of active participation', '1.0 pt'),
      PointsGuideEntry('Monthly 1-hr group over 1 year (12 sessions)', '10.0 pts (at cap)'),
      PointsGuideEntry('Bi-weekly 1-hr group over 6 months', '10.0 pts (at cap)'),
    ],
    notes: [
      'Cap is 10 points per 3-year cycle.',
      'You must actively contribute — passive attendance does not qualify.',
      'Retain a record of attendance, agenda, or meeting notes as evidence.',
      "The group's topics must relate to health informatics or digital health.",
    ],
    eligibilityReminder:
        'You must confirm you actively contributed to the discussion — passive attendance is not eligible.',
    icon: Icons.forum,
    color: Color(0xFFF59E0B),
  ),
  10: CategoryDescription(
    title: 'Workplace Activities',
    cap: '15 pts',
    rate: 'Use Categories 4 & 5 as a guide to calculate points',
    overview:
        'Activities performed within routine job responsibilities that qualify for '
        'CPD because they involve further research, new learning, skill development, '
        'and/or enhance professional practice beyond everyday duties. '
        'Standard job tasks that involve no new learning do NOT qualify. '
        'Use Category 4 (Presentation) and Category 5 (Publication) point rates '
        'as a reference when calculating how many points to claim.',
    eligibleActivities: [
      'Preparation of procedure, policy, or administrative manuals (involving new research)',
      'Preparation for accreditation and licensure surveys (involving new learning)',
      'Development of published materials or presentations',
      'Development of employee or staff training materials',
      'Instructing or teaching a class or course',
      'Teaching an internal workshop for colleagues on a health informatics topic',
      'Developing a new clinical or operational workflow involving digital health',
      'Conducting a literature review or environmental scan for a workplace project',
    ],
    ineligibleActivities: [
      'Attendance at routine staff meetings',
      'Participation in clinical grand rounds (without presenting)',
      'Participation in accreditation surveys (without a development role)',
      'Conducting tours or career days',
      'Exhibiting at a conference or event',
      'Routine data entry or system administration without new learning',
      'Day-to-day job tasks that do not involve new skill development',
    ],
    pointsGuide: [
      PointsGuideEntry('Training manual (similar effort to a whitepaper — Cat 5)', '5 pts'),
      PointsGuideEntry('Internal 30-min workshop presentation — Cat 4 rate', '4 pts'),
      PointsGuideEntry('Policy document requiring substantial research', '5 pts'),
      PointsGuideEntry('Internal 1-hr teaching session — Cat 4 rate', '8 pts'),
    ],
    notes: [
      'Cap is 15 points per 3-year cycle.',
      'You must self-assess how many points to claim using Categories 4 and 5 as a guide.',
      'The key test: did this activity involve NEW learning, research, or skill development?',
      'If unsure whether your activity qualifies, contact the CHIA Program Team at certification@digitalhealth.org.au.',
      'Retain a copy of the materials you developed, or a supervisor endorsement, as evidence.',
    ],
    eligibilityReminder:
        'You must confirm this activity involved new learning or skill development beyond routine job duties.',
    icon: Icons.work,
    color: Color(0xFF0891B2),
  ),
};
