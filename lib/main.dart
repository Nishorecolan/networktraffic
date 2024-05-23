import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_extend/share_extend.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaseLine 1',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Baseline - 1'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String _strGetAPICall = 'Call GET API';
  String _strDummyGetAPICall = 'Call Dummy GET API';
  String _strPostAPICall = 'Call POST API';
  Dio objDio = Dio();
  static Map<String, dynamic> harTemplate2 =  Map<String, dynamic>();

  @override
  void initState() {
    super.initState();
     objDio.interceptors.add(DioInterceptor());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed:() async {
              print('share clicked');
              shareHARFile();
            },
            icon:const Icon(Icons.share,
            size: 25),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Test - Network Traffic',
              style: TextStyle(fontSize: 20,fontWeight: FontWeight.w500),
            ),

            SizedBox(height: 50,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (){
                    changeButtonStatus(true,'Loading...');
                    callGetAPI();
                  },
                  child: Text(_strGetAPICall),
                ),
                SizedBox(width: 5,),
                ElevatedButton(onPressed: (){
                  changeButtonStatus(false,'Loading...');
                  callPostAPI();
                },
                  child: Text(_strPostAPICall),
                )
              ],
            ),
            ElevatedButton(

              onPressed: (){
                changeButtonStatus(false,'Loading...', isDummyGetCall: true);
                callDummyGetAPI();
              },
              child: Text( _strDummyGetAPICall),
            ),
            SizedBox(height: 50,),


          ],
        ),
      ),
    );
  }

  shareHARFile() async {
    if(harTemplate2.isNotEmpty) {
      String harJson = jsonEncode(harTemplate2);
      Directory directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/network_log15.har';
      File file = File(filePath);
      if (!await file.exists()) {
        await file.create(recursive: true);
        file.writeAsStringSync(harJson);
      }
      ShareExtend.share(file.path, "Shared HAR file");
    }
  }

  void callGetAPI() async{

    try{
      var response = await objDio.get('https://mdl.beta1mynyl.newyorklife.com/VSCRegWebApp/mobile/config');
      print('Get API response :==>$response');
      showToastMessage('Get API - Status code :==> ${response.statusCode}\n response :==>$response');
      changeButtonStatus(true,'Call GET API');
    }catch(ex){
      print('Exception :==> $ex');
      showToastMessage('Get API - exception :==> ${ex}');
      changeButtonStatus(true,'Call GET API');
    }

  }
  void callDummyGetAPI() async{
    try{
      var response = await objDio.get('https://reqres.in/api/users?page=2');
      print('Get API response :==>$response');
      showToastMessage('Get API - Status code :==> ${response.statusCode}\n response :==>$response');
      changeButtonStatus(false,'Call Dummy GET API', isDummyGetCall: true);
    }catch(ex){
      print('Exception :==> $ex');
      showToastMessage('GET Dummy API - exception :==> ${ex}');
      changeButtonStatus(false,'Call Dummy GET API', isDummyGetCall: true);
    }

  }

  void callPostAPI() async{
    try {
      var response = await objDio.post(
        'https://mdl.beta1mynyl.newyorklife.com/VSCRegWebApp/mobile/registration/verifyPersonalInfo',
        data: {
          "ssn": "6156",
          "dateOfBirth": "1962-10-16",
          "lastName": "Piittman",
          "clientId": ""
        },
        options: Options(
            headers: {Headers.contentTypeHeader: Headers.jsonContentType}),
      );
      print('POST API response :==>$response');
      showToastMessage('POST API response :==>${response
          .statusCode}\n response :==>$response');
      changeButtonStatus(false, 'Call POST API');
    }catch(ex){
      showToastMessage('POST API - exception :==> ${ex}');
      changeButtonStatus(false, 'Call POST API');
    }
  }

  changeButtonStatus(isGetCall, String msg, {bool isDummyGetCall = false}){
    setState(() {
      if(isGetCall)
        _strGetAPICall = msg;
      else if(isDummyGetCall)
        _strDummyGetAPICall = msg;
      else
        _strPostAPICall = msg;

    });
  }

  showToastMessage(String msg){
    ScaffoldMessenger.of(context).showSnackBar( SnackBar(
      content: Text(msg),
    ));
  }
}


class HarEntry {
  final String request;
  final String response;
  final int time;

  HarEntry(this.request, this.response, this.time);
}

class DioInterceptor extends Interceptor {
  final List<HarEntry> entries = [];
  var startTime,request;
  late List<Map<String, dynamic>> logEntries2 = [];
  Map<String, String> getHeadersAsMap(Headers headers) {
    final map = <String, String>{};
    headers.forEach((key, value) => map[key] = value.first);
    return map;
  }
  Headers convertIterableToHeaders(Iterable<MapEntry<String, dynamic>> entries) {
    final headers = Headers();
    for (final entry in entries) {
      headers.add(entry.key, entry.value);
    }
    return headers;
  }
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    startTime = DateTime.now();
    request= {
    "method": options.method.toString(),
    "url": options.uri.toString(),
    "httpVersion": "HTTP/1.1",
  // "headers": [getHeadersAsMap(convertIterableToHeaders(options.headers.entries))],
     "headers":  [{"name":"Content-Type","value":"application/json"}],
    "queryString": [],
    "cookies": [],
    "headersSize": -1,
    "bodySize": -1,
    "postData": {
    "mimeType": "application/json",
    "text": jsonEncode(options.data)
    }
    };

    super.onRequest(options, handler);
  }
  @override
  void onResponse(Response res, ResponseInterceptorHandler handler) {
    final endTime = DateTime.now();
    final time = endTime.difference(startTime).inMilliseconds;
    var  response =   {
      "status": 200,
    "statusText": "OK",
    "httpVersion": "HTTP/1.1",
    "headers": [
     {"name": "Content-Type", "value": "application/json"}
    ],
    "cookies": [],
    "content": {
    "size": 500,
    "mimeType": "application/json",
    "text": jsonEncode(res.data)
  },
    "redirectURL": "",
    "headersSize": -1,
    "bodySize": -1,
      "cache": {},
      "timings": {
        "send": 50,
        "wait": 100,
        "receive": 50
      }
  };
    entries.add( HarEntry(jsonEncode(request), jsonEncode(response), time));



    logEntries2.add({
      "startedDateTime": "2023-05-21T12:00:00.000Z",
      "time": 200,
      "request": request,
      "response": response,
    }, );
    saveHarFile();


    return super.onResponse(res, handler);
  }

  void onError(DioException err, ErrorInterceptorHandler handler) async {
    handler.next(err);
  }

  List<Map<String, dynamic>> convertHarEntriesToJson(List<HarEntry> entries) {
    final jsonData = entries.map((entry) => {
      'request': jsonDecode(entry.request),
      'response': jsonDecode(entry.response),
      'time': entry.time,
    }).toList();
    return jsonData;
  }
  Future<void> saveHarFile() async {

    MyHomePageState.harTemplate2 = {
      "log": {
        "version": "1.2",
        "creator": {
          "name": "Custom Logger",
          "version": "1.0"
        },
        "entries": logEntries2
      }
    };
  }
}
