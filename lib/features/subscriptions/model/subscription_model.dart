class SubscriptionModel {
  final String title;
  final String price;
  final String save;
  final bool showSave;

  SubscriptionModel({
    required this.title,
    required this.price,
    required this.save,
    required this.showSave,
  });

  static List<SubscriptionModel> subscriptionModelList = [
    SubscriptionModel(
      title: '3-Months Free Trial',
      price: 'Free',
      save: 'Save 5%',
      showSave: false,
    ),
    SubscriptionModel(
      title: 'Monthly Plan',
      price: '\$9.99/month',
      save: 'Save 10%',
      showSave: false,
    ),
    SubscriptionModel(
      title: 'Yearly Plan',
      price: '\$99/year',
      save: 'Save 17%',
      showSave: true,
    ),
  ];
}
