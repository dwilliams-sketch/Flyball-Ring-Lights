import 'package:flutter/material.dart';
class FlyballLamp extends StatelessWidget {
  final Color color; final bool active; final double size;
  const FlyballLamp({super.key,required this.color,required this.active,this.size=84});
  @override Widget build(BuildContext context){ final off=Color.alphaBlend(Colors.black.withValues(alpha:.72),color); return AnimatedContainer(duration:const Duration(milliseconds:70),width:size,height:size,decoration:BoxDecoration(shape:BoxShape.circle,color:active?color:off,border:Border.all(color:active?Colors.white54:Colors.white12,width:active?3:2),boxShadow:active?[BoxShadow(color:color.withValues(alpha:.8),blurRadius:32,spreadRadius:8)]:const []),child:DecoratedBox(decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(center:const Alignment(-.25,-.3),colors:active?[Colors.white70,color,color.withValues(alpha:.7)]:[Colors.white10,off,Colors.black54])))); }
}
