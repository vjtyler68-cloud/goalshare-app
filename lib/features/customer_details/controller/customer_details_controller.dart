import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/features/customer_details/model/customer_details_model.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class CustomerDetailsController extends GetxController{
  final RxBool isLoading = false.obs;

  final Rxn<CustomerDetailsModel> customerDetails = Rxn<CustomerDetailsModel>();


  @override
  void onInit() {
    super.onInit();
    final customerID = Get.arguments;
    fetchMission(customerID);
  }

  Future<void> fetchMission(String customerID) async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      '${Urls.customerDetails}/$customerID',
      jsonEncode({}),
      is_auth: true,
    );

    try {
      if(response != null && response['success']==true){
        customerDetails.value = CustomerDetailsModel.fromJson(response['data']);
        isLoading.value =false;
      }
      else{
        Get.snackbar('Failed', 'Customer Fetching Failed', backgroundColor: AppColors.redColor);
      }
    } catch (e) {
      log("Customer fetching error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }
}