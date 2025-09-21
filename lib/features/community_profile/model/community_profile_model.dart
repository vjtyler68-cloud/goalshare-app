class SuggestedPeople {
  final String name;
  final String imageUrl;
  bool isSelected;
  SuggestedPeople({
    required this.name,
    required this.imageUrl,
    this.isSelected = false,
  });
}
