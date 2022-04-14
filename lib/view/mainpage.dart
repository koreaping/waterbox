import 'dart:async';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:timer_builder/timer_builder.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

late List<SalesData> _PHdata;
late List<SalesData> _RTDdata ;
late List<SalesData> _DOdata;

late ChartSeriesController _DOSalesController;
late ChartSeriesController _RTDSeriesController;
late ChartSeriesController _PHSalesController;

late StreamController<bool> _Heater;
late StreamController<bool> _H2O ;

class _MainPageState extends State<MainPage> {

  late double _Rtd;
  late double _PH;
  late double _DO;
  late IO.Socket socket;
  int time = 8;

  @override
  void initState(){
    _Heater = new StreamController<bool>.broadcast();
    _H2O = new StreamController<bool>.broadcast();
    _H2O.add(false);
    _Heater.add(false);
     socket = IO.io('http://192.168.0.27:9000',
      IO.OptionBuilder().setTransports(['websocket']).build()
    );
    socket.connect();
    setUpSocketListener();
     _RTDdata = getRTDData();
     _PHdata = getPHData();
     _DOdata = getDOData();
    Timer.periodic(const Duration(seconds: 2), (timer) {
      updataPHSource(timer);
      updateRTDsource(timer);
      updataDOSource(timer);
    });
    super.initState();
  }

  void setUpSocketListener(){
    socket.on('RTD' , (data){
      _Rtd = double.parse(data);
    });
    socket.on('PH' , (data){
      _PH = double.parse(data);
    });
    socket.on('DO' , (data){
      _DO = double.parse(data);
    });
    socket.on('Heater' , (data){

      if(data.toString() == "true"){
        _Heater.add(true);
      }else{
        _Heater.add(false);
      }
    });
    socket.on('H2O' , (data){
      if(data.toString() == "true"){
        _H2O.add(true);
      }else{
        _H2O.add(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidthSize = MediaQuery.of(context).size.width;
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 100,
        leading: Image.asset('assets/images/hoseo_logo-re.png' ),
        title: Text(
            screenWidthSize > 450 ? "인공지능 기반 스마트양식 수질 관리시스템" : "인공지능 기반 스마트양식\n수질 관리시스템",
          // screenWidthSize.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidthSize > 450 ? 18 : 14,
              fontWeight: FontWeight.bold
            ),
          // screenWidthSize.toString()
        ),
        actions: [
          Image.asset('assets/images/hcic_logo-re.png' ,width: 100,)
        ],
      ),
      body: screenWidthSize > 865 ? Webpage(context) : Mobilepage(context),
    ));
  }

  void updataPHSource(Timer timer){
    _PHdata.add(SalesData(time++, _PH));
    _PHdata.removeAt(0);
    _PHSalesController.updateDataSource(
        addedDataIndex: _PHdata.length -1 , removedDataIndex: 0
    );
  }

  void updateRTDsource(Timer timer){
    _RTDdata.add(SalesData(time++, _Rtd));
    _RTDdata.removeAt(0);
    _RTDSeriesController.updateDataSource(
        addedDataIndex: _RTDdata.length -1 , removedDataIndex: 0
    );
  }

  void updataDOSource(Timer timer){
    _DOdata.add(SalesData(time++, _DO));
    _DOdata.removeAt(0);
    _DOSalesController.updateDataSource(
        addedDataIndex: _DOdata.length -1 , removedDataIndex: 0
    );
  }

  List<SalesData> getPHData() {
    final List<SalesData> PHdata =[
      SalesData(0, 0),
      SalesData(1, 0),
      SalesData(2, 0),
      SalesData(3, 0),
      SalesData(4, 0),
      SalesData(5, 0),
      SalesData(6, 0),
      SalesData(7, 0),
    ];
    return PHdata;
  }

  List<SalesData> getRTDData(){
    final List<SalesData> RTDdata =[
      SalesData(0, 0),
      SalesData(1, 0),
      SalesData(2, 0),
      SalesData(3, 0),
      SalesData(4, 0),
      SalesData(5, 0),
      SalesData(6, 0),
      SalesData(7, 0),
    ];
    return RTDdata;
  }

  List<SalesData> getDOData() {
    final List<SalesData> DOdata =[
      SalesData(0, 0),
      SalesData(1, 0),
      SalesData(2, 0),
      SalesData(3, 0),
      SalesData(4, 0),
      SalesData(5, 0),
      SalesData(6, 0),
      SalesData(7, 0),
    ];
    return DOdata;
  }
}

class SalesData{
  SalesData(this.x , this.y);
  final int x;
  final double y;
}

Widget Webpage(BuildContext context){

  return Column(
    children: [
      Container(alignment: Alignment.center,height: 50,width:double.infinity , color: Colors.black,
      child: TimerBuilder.periodic(const Duration(seconds: 1), builder: (context){
        return Text(
          formatDate(DateTime.now(), [hh,':' ,nn , ":" , ss]),
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 50
          ),
        );
      }),),
      Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Flexible(
                flex: 1,
                child: PHchart()

                ),
              Flexible(
                flex: 1,
                child: RTDchart(),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Flexible(child: DOchart() , flex: 1,),
              Flexible(child: Container(
                margin: const EdgeInsets.fromLTRB(46, 16, 16, 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        width: 3,
                        color: Colors.blue.withOpacity(0.3)
                    )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: Heater(context)),
                      Expanded(child:  H2o(context))
                    ],
                  ),
                ),
              ), flex: 1,)
            ],
          ),
        ),
      )
    ],
  );
}

Widget Mobilepage(BuildContext context){
  return ListView(
    children: [
      Container(alignment: Alignment.center,height: 50,width:double.infinity , color: Colors.black,
        child: TimerBuilder.periodic(const Duration(seconds: 1), builder: (context){
          return Text(
            formatDate(DateTime.now(), [hh,':' ,nn , ":" , ss ]),
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 40
            ),
          );
        }),),
      RTDchart(),
      PHchart(),
      DOchart(),
      Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
      margin: const EdgeInsets.fromLTRB(46, 16, 16, 16),
      decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
      width: 3,
      color: Colors.blue.withOpacity(0.3)
      )
      ),
      child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
  Flexible( flex:1 , child : Heater(context)),
  Flexible(child: H2o(context) , flex: 1,)
  ],
  ),
  )

  ))
    ],
  );
}

SfCartesianChart RTDchart(){
  return SfCartesianChart(
    title: ChartTitle(
        text: "RTD (수온)"
    ),
    series: <ChartSeries>[
      LineSeries<SalesData,int>(
          onRendererCreated: (ChartSeriesController controller) {
            _RTDSeriesController = controller;
          },
          dataSource: _RTDdata,
          xValueMapper: (SalesData sales , _) => sales.x,
          yValueMapper: (SalesData sales , _) => sales.y,
          markerSettings: MarkerSettings(isVisible: true,
          borderColor: Colors.red,
          borderWidth: 1),
        dataLabelSettings: DataLabelSettings(
          isVisible: true,
        )
      )
    ],
    primaryXAxis: NumericAxis(edgeLabelPlacement: EdgeLabelPlacement.shift , majorGridLines: const MajorGridLines(width: 0 ,color:  Colors.greenAccent)),
    primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(width: 0, color: Colors.greenAccent),
        minimum: 20,
        maximum: 30,
    ),

  );
}

SfCartesianChart PHchart(){
  return SfCartesianChart(
    title: ChartTitle(
        text: "PH (이온 농도)"
    ),
    series: <ChartSeries>[
      LineSeries<SalesData,int>(
          onRendererCreated: (ChartSeriesController controller) {
            _PHSalesController = controller;
          },
          dataSource: _PHdata,
          xValueMapper: (SalesData sales , _) => sales.x,
          yValueMapper: (SalesData sales , _) => sales.y,
      markerSettings: MarkerSettings(
        isVisible: true,
        borderWidth: 1,
        borderColor: Colors.red
      ),
      dataLabelSettings: DataLabelSettings(
        isVisible: true
      ))
    ],
    primaryXAxis: NumericAxis(edgeLabelPlacement: EdgeLabelPlacement.shift , majorGridLines: const MajorGridLines(width: 0)),
    primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(width: 0),
        minimum: 0,
        maximum: 10
    ),
  );
}

SfCartesianChart DOchart(){
  return SfCartesianChart(
    title: ChartTitle(
        text: "DO (용존 산소량)"
    ),
    series: <ChartSeries>[
      LineSeries<SalesData,int>(
          onRendererCreated: (ChartSeriesController controller) {
            _DOSalesController = controller;
          },
          dataSource: _DOdata,
          xValueMapper: (SalesData sales , _) => sales.x,
          yValueMapper: (SalesData sales , _) => sales.y,
      markerSettings: MarkerSettings(
        isVisible: true,
        borderColor: Colors.red,
        borderWidth: 1
      ),
      dataLabelSettings: DataLabelSettings(
        isVisible: true
      ))
    ],
    primaryXAxis: NumericAxis(edgeLabelPlacement: EdgeLabelPlacement.shift , majorGridLines: const MajorGridLines(width: 0)),
    primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(width: 0),
        minimum: 0,
        maximum: 10
    ),
  );
}

Widget Heater(BuildContext context){
  var ScreenSizeWidth = MediaQuery.of(context).size.width;
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: ScreenSizeWidth < 400 ? 120 : 150,
        height: ScreenSizeWidth < 400 ? 120 : 150,
        child: CircleAvatar(
          child: Image.asset("assets/images/HeaterLogo.png"),
        ),
      ),
      SizedBox(height: 15,),
      Text("히터",
        style:TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black
        ),),
      SizedBox(height: 15,),
      StreamBuilder(
    stream: _Heater.stream,
  builder: (BuildContext context , snapshot){
        return Container(
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
  color: snapshot.data.toString() == "true" ? Color(0xff00ff00) : Color(0xffff0000)
  ),
  width: 60,
  height: 30,
  child: Center(
  child: Text(
  snapshot.data.toString() == "true" ? "ON" : "OFF",
  style: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.white
  ),
  ),

  ),
      );})
    ],
  );
}

Widget H2o(BuildContext context){
  var ScreenSizeWidth = MediaQuery.of(context).size.width;
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(child: CircleAvatar(
        child: Image.asset("assets/images/H2OLogo.png"),
      ),
        width: ScreenSizeWidth < 400 ? 120 : 150
        ,height: ScreenSizeWidth < 400 ? 120 : 150
        ,),
      SizedBox(height : 15,),
      Text("산소발생기",
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16
        ),),
      SizedBox(height: 15,),
      StreamBuilder(
        stream: _H2O.stream,
        builder: (BuildContext context , snapshot){
          return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: snapshot.data.toString() == "true" ? Color(0xff00ff00) : Color(0xffff0000)
            ),
            width: 60,
            height: 30,

            child: Center(
              child: Text(
                snapshot.data.toString() == "true" ? "ON" : "OFF",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white
                ),
              ),
            ),
          );
        },
      )
    ],
  );
}