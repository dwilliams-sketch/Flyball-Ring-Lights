import 'package:flutter/material.dart';
class FaultButton extends StatelessWidget {
  final int dogNumber; final Color laneColor; final bool active; final VoidCallback onTap;
  const FaultButton({super.key,required this.dogNumber,required this.laneColor,required this.active,required this.onTap});
  @override Widget build(BuildContext context)=>InkWell(borderRadius:BorderRadius.circular(16),onTap:onTap,child:AnimatedContainer(duration:const Duration(milliseconds:100),height:58,width:78,decoration:BoxDecoration(color:active?laneColor:laneColor.withValues(alpha:.12),borderRadius:BorderRadius.circular(16),border:Border.all(color:active?Colors.white70:laneColor.withValues(alpha:.45),width:active?2:1),boxShadow:active?[BoxShadow(color:laneColor.withValues(alpha:.55),blurRadius:18,spreadRadius:2)]:const []),child:Center(child:Text('$dogNumber',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:active?Colors.white:laneColor)))));
}
