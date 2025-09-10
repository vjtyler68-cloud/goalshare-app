import 'package:spanx/core/const/app_icons.dart';

class CommunityProfileModel {
  final String imgPath;
  final String name;
  final String designation;
  final String location;

  CommunityProfileModel({
    required this.imgPath,
    required this.name,
    required this.designation,
    required this.location,
  });

  static List<CommunityProfileModel> profiles = [
    CommunityProfileModel(
      imgPath: 'https://randomuser.me/api/portraits/men/24.jpg',
      name: 'John Doe',
      designation: 'Salesperson',
      location: 'Birmingham,UK',
    ),
    CommunityProfileModel(
      imgPath: 'https://randomuser.me/api/portraits/men/51.jpg',
      name: 'John Doe',
      designation: 'Salesperson',
      location: 'Birmingham,UK',
    ),
    CommunityProfileModel(
      imgPath: 'https://randomuser.me/api/portraits/men/64.jpg',
      name: 'John Doe',
      designation: 'Salesperson',
      location: 'Birmingham,UK',
    ),
    CommunityProfileModel(
      imgPath: 'https://randomuser.me/api/portraits/men/21.jpg',
      name: 'John Doe',
      designation: 'Salesperson',
      location: 'Birmingham,UK',
    ),
  ];
}

class RecentActivityModel{
  final String iconPath;
  final String title;
  final String time;

  RecentActivityModel({required this.iconPath, required this.title, required this.time});
  
  static List<RecentActivityModel> recentActivity = [
    RecentActivityModel(iconPath: AppIcons.success, title: 'Completed session with Emma Wilson', time: '2 Hours Ago'),
    RecentActivityModel(iconPath: AppIcons.notification, title: 'New message from Community', time: '2 Hours Ago'),
    RecentActivityModel(iconPath: AppIcons.target, title: 'Achieved daily sales target', time: '2 Hours Ago'),
  ];
}