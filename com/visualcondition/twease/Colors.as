//
//  Twease Extended Colors [AS3]
//  Color Equations From Fuse Kit - http://www.mosessupposes.com/Fuse/
// 
// 	Copyright (c) 2008 Andrew Fitzgerald - MIT License
//  Original Release: 04/03/08
//  Author: Andrew Fitzgerald
//  Homepage: http://play.visualcondition.com/twease/
//

package com.visualcondition.twease {
	import flash.geom.ColorTransform;
	
	 public class Colors {
		public static var version:Number = 2.0;
		public static var cl = com.visualcondition.twease.Colors;
		public static var clname:String = 'Colors';
		public static var exfuncs:Array = ['setColor', 'getColorObject'];
		public static var exprops:Object = {
			Colors: ['brightness', 'brightOffset', 'contrast', 'invertColor', 'tint'],
			nullhelpers: ['tintPercent']
		};
		public static var colorholder:Object = {};

		//standard class init
		public static function init():void {
			Extend.initExtended(exprops, exfuncs, clname, cl);
		}

		//sets up special tween property and inserts an applier to update the prop
		public static function setup(prop:String, tweenobj:Object):void {
			if(colorholder[tweenobj.target] == undefined){
				colorholder[tweenobj.target] = {cc:tweenobj.target.transform.colorTransform, lc:{}};
			}
			var amount:Number = (prop == 'tint') ? (tweenobj.tintPercent == undefined) ? 1 : tweenobj.tintPercent : tweenobj[prop];
			var cc:* = (colorholder[tweenobj.target] == undefined) ? null : colorholder[tweenobj.target].lc;
			var temptween:Object = getColorObject(prop, amount, tweenobj[prop]);
			for ( var i in tweenobj ) if(Twease.compareInObject(i, Twease.baseprops)) temptween[i] = tweenobj[i];
			Extend.createSubtween(tweenobj.target, clname, colorholder[tweenobj.target].cc, temptween, colorupdater);
		};

		//this is the function that gets called on the applier update every frame
		public static function colorupdater(ao:Object):void {
			ao.target.transform.colorTransform = new ColorTransform(ao.temptweentarget.redMultiplier, ao.temptweentarget.greenMultiplier, ao.temptweentarget.blueMultiplier, ao.target.alpha, ao.temptweentarget.redOffset, ao.temptweentarget.greenOffset, ao.temptweentarget.blueOffset);
		};

		//sets a color and sets it up for future tweening
		public static function setColor(target:Object, type:String, amt:Number, rgb:Object, comobj:Object):void {
			var nco:Object = getColorObject(type, amt, rgb, comobj);
			target.transform.colorTransform = nco;
			colorholder[target] = nco;
		}

		//returns the magical object that contains the transformation information
		public static function getColorObject(type:String, amt:Number, rgb:Object, cco:Object = null):Object {
			var cr:Number;
			var cg:Number;
			var cb:Number;
			var cr2:Number;
			var cg2:Number;
			var cb2:Number;
			if(cco != null){
				cr = cco.redOffset;
				cb = cco.blueOffset;
				cg = cco.greenOffset;
				cr2 = int(cr/2);
				cb2 = int(cb/2);
				cg2 = int(cg/2);
			} else {
				cr = cb = cg = 255;
				cr2 = cb2 = cg2 = 128;
			}
			switch (type) {
			 case 'brightness' : //amt:-1=black, 0=normal, 1=white
				var percent:Number = (1-Math.abs(amt));
				var offset:Number = ((amt > 0) ? (255*(amt/1)) : 0);
				return {redMultiplier:percent, redOffset:offset, greenMultiplier:percent, greenOffset:offset, blueMultiplier:percent, blueOffset:offset};
			 case 'brightOffset' : //"burn" effect. amt:-1=black, 0=normal, 1=white
				return {redMultiplier:1, redOffset:(cr*(amt/1)), greenMultiplier:1, greenOffset:(cg*(amt/1)), blueMultiplier:1, blueOffset:(cb*(amt/1))};
			 case 'contrast' : //amt:0=gray, 1=normal, 2=high-contrast, higher=posterized.
				return {redMultiplier:amt, redOffset:(cr2-(cr2/1*amt)), greenMultiplier:amt, greenOffset:(cg2-(cg2/1*amt)), blueMultiplier:amt, blueOffset:(cb2-(cb2/1*amt))};
			 case 'invertColor' : //amt:0=normal,.5=gray,1=photo-negative
				return {redMultiplier:(1-2*amt), redOffset:(amt*(cr/1)), greenMultiplier:(1-2*amt), greenOffset:(amt*(cg/1)), blueMultiplier:(1-2*amt), blueOffset:(amt*(cb/1))};
			 case 'tint' : //amt:0=none,1=solid color (>1=posterized to tint, <0=inverted posterize to tint)
			 	if (rgb != null) {
			 		var rgbnum:Number;
					if (typeof rgb == 'string') {
						if (rgb.charAt(0) == '#') rgb = rgb.slice(1);
						rgb = ((rgb.charAt(1)).toLowerCase()!='x') ? ('0x'+rgb) : (rgb);
					}
					rgbnum = Number(rgb);
					return {redMultiplier:(1-amt), redOffset:(rgbnum >> 16)*(amt/1), greenMultiplier:(1-amt), greenOffset:((rgbnum >> 8) & 0xFF)*(amt/1), blueMultiplier:(1-amt), blueOffset:(rgbnum & 0xFF)*(amt/1)};
				}
			}
			return {redOffset:0, redMultiplier:1, greenOffset:0, greenMultiplier:1, blueOffset:0, blueMultiplier:1}; //full reset
		};
	}
}
