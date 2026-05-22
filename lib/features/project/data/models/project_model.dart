import 'dart:convert';

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final List<String> labels;
  final String githubRepo;
  final double progress;
  final String category;
  final String date;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.labels,
    required this.githubRepo,
    required this.progress,
    required this.category,
    required this.date,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      labels: json['labels'] is List 
          ? (json['labels'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
      githubRepo: json['github_repo'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      date: json['date_deadline'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'labels': labels,
      'github_repo': githubRepo,
      'progress': progress,
      'category': category,
      'date_deadline': date,
    };
  }

  // toJsonWithId is useful for updates or local database mocks
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'labels': labels,
      'github_repo': githubRepo,
      'progress': progress,
      'category': category,
      'date_deadline': date,
    };
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? labels,
    String? githubRepo,
    double? progress,
    String? category,
    String? date,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      labels: labels ?? this.labels,
      githubRepo: githubRepo ?? this.githubRepo,
      progress: progress ?? this.progress,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}
