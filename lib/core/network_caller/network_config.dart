// ignore_for_file: file_names, constant_identifier_names, non_constant_identifier_names, avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum RequestMethod { GET, POST, PUT, DELETE }

class NetworkConfig {

  NetworkConfig._privateConstructor();
  static final NetworkConfig _instance = NetworkConfig._privateConstructor();
  static NetworkConfig get instance => _instance;


  Future ApiRequestHandler(RequestMethod method, url, json_body,
      {is_auth = false}) async {
    SharedPreferences sh = await SharedPreferences.getInstance();

    if (await InternetConnectionChecker.createInstance().hasConnection) {
      var header = <String, String>{"Content-type": "application/json"};
      if (is_auth == true) {
        header["Authorization"] = "${sh.getString("token")}";
      }

      if (method.name == RequestMethod.GET.name) {
        try {
          var req = await http.get(Uri.parse(url), headers: header);

          print(req.statusCode);
          if (req.statusCode == 200 || req.statusCode == 201) {
            return json.decode(req.body);
          } else {
            throw Exception("Server Error");
          }
        } catch (e) {
          ShowError(e);
        }
      } else if (method.name == RequestMethod.POST.name) {
        try {
          var req = await http.post(Uri.parse(url),
              headers: header,
              body: json_body);

          print(req.body);
          if (req.statusCode == 200) {
            return json.decode(req.body);
          } else if (req.statusCode == 500) {
            throw Exception("Server Error");
          } else {
            throw Exception('try aging after some time');
          }
        } catch (e) {
          ShowError(e);
        }
      } else if (method.name == RequestMethod.PUT.name) {
        try {
          var req =
              await http.put(Uri.parse(url), headers: header, body: json_body);

          print(req.statusCode);
          if (req.statusCode == 200) {
            return json.decode(req.body);
          } else {
            throw Exception("Server Error");
          }
        } catch (e) {
          ShowError(e);
        }
      } else if (method.name == RequestMethod.DELETE.name) {
        try {
          var req = await http.delete(Uri.parse(url), headers: header);

          print(req.statusCode);
          print(req);
          if (req.statusCode == 200) {
            return json.decode(req.body);
          } else {
            throw Exception("Server Error");
          }
        } catch (e) {
          ShowError(e);
        }
      }
    } else {
      Fluttertoast.showToast(msg: "Please Connect Internet");
    }
  }

  ShowError(msg) {
    Fluttertoast.showToast(
        msg: msg.toString(),
        backgroundColor: Colors.red,
        textColor: Colors.white);
  }
}
