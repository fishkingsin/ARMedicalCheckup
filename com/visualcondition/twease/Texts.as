//
//  Twease Extended Texts [AS3]
// 
// 	Copyright (c) 2008 Andrew Fitzgerald - MIT License
//  Original Release: 04/03/08
//  Author: Andrew Fitzgerald
//  Homepage: http://play.visualcondition.com/twease/
//

package com.visualcondition.twease {	
	 public class Texts {
		public static var version:Number = 2.0;
		public static var cl = com.visualcondition.twease.Texts;
		public static var clname:String = 'Texts';
		public static var exfuncs:Array = [];
		public static var exprops:Object = {
			Texts: ['character', 'words'],
			nullhelpers: ['charset']
		};
		public static var charsets:Object = {
			lowercase: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'],
			uppercase: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			numbers: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
			punctuation: [' ', '!', '.', '?', ',', ':', ';', "'", '"', '-', '–', '—'],
			symbols: ['_', '(', ')', '[', ']', '{', '}', '@', '#', '$', '%', '&', '*', '+', '/', '<', '=', '>', '\\', '^', '`', '|', '~'],
			letters: [],
			sentences: [],
			all: []		
		}

		//standard class init
		public static function init():void {
			Extend.initExtended(exprops, exfuncs, clname, cl);
			charsets.letters = charsets.uppercase.concat(charsets.lowercase);
			charsets.all = charsets.punctuation.concat(charsets.symbols).concat(charsets.uppercase).concat(charsets.lowercase).concat(charsets.numbers);
			charsets.sentences = charsets.punctuation.concat(charsets.uppercase).concat(charsets.lowercase);
			charsets.uppercase.splice(0,0," ");
			charsets.lowercase.splice(0,0," ");
			charsets.letters.splice(0,0," ");
		}

		//sets up special tween property and inserts an applier to update the prop
		public static function setup(prop:String, tweenobj:Object):void {
			var masc:Object = {};
			masc.prop = prop;
			var chs:Array = (tweenobj.charset != undefined) ? charsets[tweenobj.charset] : charsets.all;
			var rn:Object;
			switch(prop){
				case 'character':
					masc.charset = chs;
					masc.oldletter = tweenobj.target.text;
					masc.newletter = tweenobj[prop];
					masc.oldlnum = masc.charset.indexOf(masc.oldletter);
					masc.newlnum = masc.charset.indexOf(masc.newletter);
					masc.curlnum = new Number(masc.oldlnum);
					tweenobj.round = true;
					tweenobj.curlnum = new Number(masc.newlnum);
					delete tweenobj[prop];
	                delete tweenobj.charset;
					Extend.createSubtween(tweenobj.target, clname, 'helper', tweenobj, textsupdater, masc);
				break;
				case 'words':
					masc.charset = chs;
					masc.oldword = tweenobj.target.text;
					masc.newword = tweenobj[prop];
					masc.oldwarr = masc.oldword.split("");
					masc.newwarr = masc.newword.split("");
					masc.oldiarr = [];
					masc.newiarr = [];
					masc.curiarr = [];
					for ( var i in masc.oldwarr ){
						masc.oldiarr.push(masc.charset.indexOf(masc.oldwarr[i]));
						masc.curiarr.push(masc.charset.indexOf(masc.oldwarr[i]));
					};
					for ( var j in masc.newwarr ) masc.newiarr.push(masc.charset.indexOf(masc.newwarr[j]));
					var samt:Number;
					if(masc.oldwarr.length < masc.newwarr.length){
						samt = masc.newwarr.length - masc.oldwarr.length;
						for ( var k=0; k<samt; k++ ) {
							masc.oldiarr.push(0);
							masc.curiarr.push(0);
						};
					} else if(masc.oldwarr.length > masc.newwarr.length){
						samt = masc.oldwarr.length - masc.newwarr.length;
						masc.newiarr.reverse();
						for ( var l=0; l<samt; l++ ) masc.newiarr.push(0);
						masc.newiarr.reverse();
					}
					tweenobj.array = masc.newiarr;
					tweenobj.round = true;
					delete tweenobj[prop];
	                delete tweenobj.charset;
					Extend.createSubtween(tweenobj.target, clname, 'curiarr', tweenobj, textsupdater, masc);
				break;
			}
		};

		//this is the function that gets called on the applier update every frame
		public static function textsupdater(ao:Object):void {
			switch(ao.helper.prop){
				case "character":
					ao.target.text = ao.helper.charset[ao.temptweentarget.curlnum];
				break;
				case 'words':
					var nt:String = "";
					for ( var i in ao.temptweentarget ) nt += ao.helper.charset[ao.temptweentarget[i]];
					ao.target.text = nt;
				break;
			}
		};
	}
}



