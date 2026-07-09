import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';

import '../controller/leads_controller.dart';
import '../model/lead.dart';

/// Add a new lead or edit an existing one. Pass an existing [lead] to edit.
class LeadFormScreen extends StatefulWidget {
  final Lead? lead;
  const LeadFormScreen({super.key, this.lead});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final controller = Get.find<LeadsController>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _company;
  late final TextEditingController _address;
  late final TextEditingController _notes;

  late String _status;
  bool _saving = false;

  bool get _isEditing => widget.lead != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _name = TextEditingController(text: l?.name ?? '');
    _phone = TextEditingController(text: l?.phone ?? '');
    _email = TextEditingController(text: l?.email ?? '');
    _company = TextEditingController(text: l?.company ?? '');
    _address = TextEditingController(text: l?.address ?? '');
    _notes = TextEditingController(text: l?.notes ?? '');
    _status = l?.status ?? 'New';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _company.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a name',
        backgroundColor: AppColors.redColor,
      );
      return;
    }
    setState(() => _saving = true);

    bool ok;
    if (_isEditing) {
      final updated = widget.lead!.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        company: _company.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        status: _status,
      );
      ok = await controller.updateLead(updated);
    } else {
      final created = Lead.create(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        company: _company.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        status: _status,
      );
      ok = await controller.addLead(created);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    // The lead is always kept in memory; ok reflects whether it also persisted
    // to disk. Warn (don't block) if disk storage was unavailable.
    if (!ok) {
      Fluttertoast.showToast(
        msg: 'Saved for now, but on-device storage was unavailable',
        backgroundColor: AppColors.redColor,
      );
    } else {
      Fluttertoast.showToast(
        msg: _isEditing ? 'Lead updated' : 'Lead added',
        backgroundColor: AppColors.greenColor,
      );
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: SubPageAppbarWidget(
                appbarTitle: _isEditing ? 'Edit Lead' : 'Add Lead',
                onPressed: () => Get.back(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextFormWidget(
                      sectionTitle: 'Name *',
                      textEditingController: _name,
                      hintText: 'Full name',
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormWidget(
                      sectionTitle: 'Phone',
                      textEditingController: _phone,
                      hintText: 'Phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormWidget(
                      sectionTitle: 'Email',
                      textEditingController: _email,
                      hintText: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormWidget(
                      sectionTitle: 'Company',
                      textEditingController: _company,
                      hintText: 'Company / organization',
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormWidget(
                      sectionTitle: 'Address',
                      textEditingController: _address,
                      hintText: 'Street address',
                    ),
                    SizedBox(height: 16.h),
                    _statusPicker(),
                    SizedBox(height: 16.h),
                    Text(
                      'Notes',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 16.sp,
                        color: AppColors.greyColor70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    TextField(
                      controller: _notes,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Anything worth remembering…',
                        filled: true,
                        fillColor: AppColors.formBackgroundColor,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 15.h, horizontal: 18.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide:
                              BorderSide(color: AppColors.greyColor70, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide:
                              BorderSide(color: AppColors.greyColor70, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide:
                              BorderSide(color: AppColors.greyColor70, width: 1),
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _saving
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButtonWidget(
                            onTap: _save,
                            buttonText: _isEditing ? 'Save Changes' : 'Add Lead',
                          ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 16.sp,
            color: AppColors.greyColor70,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: kLeadStatuses.map((s) {
            final selected = s == _status;
            return GestureDetector(
              onTap: () => setState(() => _status = s),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryColor
                      : AppColors.formBackgroundColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.primaryColor, width: 1),
                ),
                child: Text(
                  s,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    color: selected ? AppColors.whiteColor : AppColors.greyColor70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
