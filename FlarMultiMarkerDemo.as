package 
{
	//Debug
	import net.hires.debug.Stats;
	// bulkloader
	import br.com.stimuli.loading.BulkLoader;

	// papervision
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.primitives.Cube;
	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
	import org.papervision3d.render.LazyRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;

	// flash
	import flash.display.PixelSnapping;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.net.URLRequest;
	import flash.events.TimerEvent;
	import flash.events.Event;
	//import flash.utils.*;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLLoader;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.media.Sound;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.Timer;
	import flash.ui.Mouse;
	import flash.geom.Matrix;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.DAE;

	// libspark
	import org.libspark.flartoolkit.core.FLARCode;
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import org.libspark.flartoolkit.detector.FLARMultiMarkerDetector;
	import org.libspark.flartoolkit.detector.FLARSingleMarkerDetector;
	import org.libspark.flartoolkit.pv3d.FLARBaseNode;
	import org.libspark.flartoolkit.pv3d.FLARCamera3D;

	// this is the class needed for tweening
	// lightweight and flexible
	// not by anyone of us, it's downloaded from :
	// http://play.visualcondition.com/twease/
	import com.visualcondition.twease.*;

	import flash.system.fscommand;

	public class FlarMultiMarkerDemo extends Sprite
	{
		// flar properties
		private var _camParameters:FLARParam;
		private var _raster:FLARRgbRaster_BitmapData;
		private var _detectors:FLARMultiMarkerDetector;
		private var _flarCam3D:FLARCamera3D;
		//private var _resultMat:FLARTransMatResult;
		private var transMats:Array;

		// flash properties
		private var _cam:Camera;
		private var _vid:Video;
		private var _capture:Bitmap;
		private var _trackcap:Bitmap;
		private var _loader:URLLoader;
		private var _allMarkers:Array;
		private var _allMaterials:Array;
		private var xml:XML;
		private var xmlLoader:URLLoader;

		// papervision3d
		private var _vp:Viewport3D;
		private var _scene:Scene3D;
		private var _renderer:LazyRenderEngine;
		private var _light:PointLight3D;
		private var _bLoader:BulkLoader;
		private var pl:PointLight3D;

		private var AR_path:String = "assets/AR/";
		private var image_path:String = "assets/image/";
		private var _camWidth:Number;
		private var _camHeight:Number;
		//====resize trackiung size====
		private var _trackWidth:Number;
		private var _trackHeight:Number;

		private var _cavWidth:Number;
		private var _cavHeight:Number;
		private var _trackMarkerId:Number;
		private var _count:Number;
		private var _trackLock:Boolean;
		private var _timer:Timer;
		private var _timeout:Number;
		private var _obj_fadeOut:Object;
		private var _obj_fadeIn:Object;
		private var master:MovieClip;
		private var open_snd:Sound;
		public var stats:Stats = new Stats();
		var _sacleMatrix:Matrix = new Matrix();
		var _mirrorMatrix:Matrix = new Matrix();
		[SWF(width = "1360",height = "768",frameRate = "30",backgroundColor = "#FFFFFF")]

		public function FlarMultiMarkerDemo ()
		{
			
			Mouse.hide();
			var e_ob:String = 'easeOutBounce';
			var e_oe:String = 'easeOutElastic';
			var e_l:String = 'linear';
			open_snd = new Sound();
			master = new MovieClip();
			master.name = "master";
			//master.alpha = 0;
			stage.addChild (master);

			this._timer = new Timer(1000,0);
			this._timer.start ();
			this._timer.addEventListener (TimerEvent.TIMER,_timerUpdate);
			_timeout = 3;

			// this is to prevent more than 1 actions to happen in sequence
			// sometimes it's a nice feature, but as a simple case we don't need it here
			Twease.stacking = false;

			// this is needed if you want to use easing type other than linear, 
			// which is most of the case we do
			Twease.register (Easing);
			//==============================================
			// create an action object to tween
			//==============================================
			_obj_fadeOut = ({target:master, alpha:0.0,time:0.5, ease:e_l, func:afterFadeOut});

			//==============================================
			// create an action object to tween
			//==============================================
			_obj_fadeIn = ({target:master, alpha:1,time:1, ease:e_l ,func:afterFadeIn});//var

			initXML ();

			this._trackMarkerId = -1;
			this._trackLock = false;
			_count = 0;

			fscommand ("fullscreen","true");

			loadCamera ();
			if(xml.elements("debug")>0){
			addChild(stats);
			}
		}
		//=====================================================================================================================================
		private function initXML ()
		{
			xml = new XML  ;
			var XML_URL:String = "./assets/configure.xml";
			var myXMLURL:URLRequest = new URLRequest(XML_URL);
			xmlLoader = new URLLoader(myXMLURL);
			xmlLoader.addEventListener (Event.COMPLETE,xmlLoaded);


		}
		//=====================================================================================================================================
		private function xmlLoaded (event:Event):void
		{
			this.xml = XML(xmlLoader.data);
			//trace("Data loaded.");
			//trace(this.xml);
			var numOfObj:Number = xml.elements("ObjectNumber");//
			this._camWidth = xml.elements("Camera").width;
			this._camHeight = xml.elements("Camera").height;
			this._cavWidth = xml.elements("Canvas").width;
			this._cavHeight = xml.elements("Canvas").height;
			this._trackWidth = xml.elements("Track").width;
			this._trackHeight = xml.elements("Track").height;
			//trace(xml.elements("Settings").sound.open);
			open_snd.load (new URLRequest(xml.elements("Settings").sound.open.toString()));
			this._allMarkers = [];
			this._allMaterials = [];
			for (var i=0; i<numOfObj; i++)
			{
				var element:XML = xml.elements("Object")[i];
				trace ("element parttern "+element.pattern);
				trace ("element modelname "+element.model.name);
				trace ("element image "+element.image);
				this._allMarkers[i] = {markerSource:AR_path + element.pattern,segments:16,size:65};
				this._allMaterials[i] = {id:i,modelSource:element.model.name.toString(),scale:element.model.scale,x:element.model.x,y:element.model.y,z:element.model.z,rx:element.model.rotationX,ry:element.model.rotationY,rz:element.model.rotationZ,image:image_path + element.image};
			}
			
		}
		//=====================================================================================================================================
		private function loadCamera ():void
		{
			this._loader = new URLLoader  ;
			this._loader.dataFormat = URLLoaderDataFormat.BINARY;
			this._loader.addEventListener (Event.COMPLETE,onLoadCamParam);
			this._loader.load (new URLRequest(AR_path+"camera_para.dat"));
		}
		//=====================================================================================================================================
		// camera parameters are loaded, load the marker you want to use
		// camera parameters are loaded, load the marker you want to use
		private function onLoadCamParam (event:Event):void
		{
			this._loader.removeEventListener (Event.COMPLETE,onLoadCamParam);

			// setup camera parameters
			this._camParameters = new FLARParam  ;
			this._camParameters.loadARParam (this._loader.data);
			this._camParameters.changeScreenSize (this._trackWidth,this._trackHeight);

			// reset loader
			this._loader = null;

			this._bLoader = new BulkLoader("markerLoader");
			this._bLoader.addEventListener (Event.COMPLETE,markersLoadedHandler);
			// now load multiple markers (for now its 3)
			for (var i:int=0; i<this._allMarkers.length; i++)
			{
				this._bLoader.add (this._allMarkers[i].markerSource,{id:"marker_"+i.toString()});
			}
			this._bLoader.start ();
		}
		//=====================================================================================================================================
		private function markersLoadedHandler (event:Event):void
		{
			var codes:Array = new Array  ;
			var sizes:Array = new Array  ;
			for (var i:int=0; i<this._allMarkers.length; i++)
			{
				var code:FLARCode = new FLARCode(this._allMarkers[i].segments,
												this._allMarkers[i].segments,
												this._allMarkers[i].size,
												this._allMarkers[i].size);
				code.loadARPatt (this._bLoader.getContent("marker_"+i.toString()));
				codes.push (code);
				sizes.push (this._allMarkers[i].size);
				//this._detector = new FLARSingleMarkerDetector (this._camParameters, code, this._allMarkers[i].size) ;
			}

			initWebcam ();

			// create bitmap and bitmapdata where we can draw the webcam into
			var bmd:BitmapData = new BitmapData(this._camWidth,this._camHeight,false,0);
			var tbmd:BitmapData = new BitmapData(this._trackWidth,this._trackHeight,false,0);
			this._capture = new Bitmap(bmd,PixelSnapping.AUTO,false);
			this._capture.width = this._cavWidth;
			this._capture.height = this._cavHeight;
			addChild (this._capture);

			this._trackcap = new Bitmap(tbmd,PixelSnapping.AUTO,false);
			if(xml.elements("debug")>0){
				addChild (this._trackcap);
			}
			
			this._raster = new FLARRgbRaster_BitmapData(this._trackcap.bitmapData);
			//this._raster=new FLARRgbRaster_BitmapData(this._capture.bitmapData);
			this._detectors = new FLARMultiMarkerDetector(this._camParameters,codes,sizes,codes.length);
			
			initFlar ();
			initPV3D ();
			initListeners ();
		}
		//=====================================================================================================================================
		private function initWebcam ():void
		{
			this._cam = Camera.getCamera();
			this._cam.setMode (this._camWidth,this._camHeight,60);
			this._vid = new Video(this._camWidth,this._camHeight);
			this._vid.attachCamera (this._cam);
			_mirrorMatrix.scale(-1,1);
			_mirrorMatrix.translate(this._vid.width,0);
			_sacleMatrix.translate(-_vid.width/2,-_vid.height/2);
			_sacleMatrix.scale(-1,1);
			_sacleMatrix.translate(_vid.width/2,_vid.height/2);
			_sacleMatrix.scale(_trackWidth/_camWidth, _trackHeight/_camHeight);
			//_mirrorMatrix.scale(-1,1);
			
		}
		//=====================================================================================================================================
		private function initFlar ():void
		{
			this._flarCam3D = new FLARCamera3D(this._camParameters);

			this.transMats = [];
			/*  {result: new FLARTransMatResult(), isShow: false},
			  {result: new FLARTransMatResult(), isShow: false},
			  {result: new FLARTransMatResult(), isShow: false},
			  {result: new FLARTransMatResult(), isShow: false},
			  {result: new FLARTransMatResult(), isShow: false},
			  {result: new FLARTransMatResult(), isShow: false},
			  
			  ];*/
			for (var i:Number=0; i<this._allMarkers.length; i++)
			{
				this.transMats[i] = {result:new FLARTransMatResult  ,isShow:false};
			}
		}
		//=====================================================================================================================================
		private function initPV3D ():void
		{

			this._vp = new Viewport3D(this._cavWidth,this._cavHeight);
			addChild (this._vp);

			this._scene = new Scene3D  ;

			this._light = new PointLight3D  ;

			// add a cube or whatever we want to show when pattern is recognised
			// in the basenode (FLARBaseNode, which extends from a DisplayObject3D)
			for (var i:int=0; i<this._allMarkers.length; i++)
			{
				var daeModel:DAE = new DAE(true,null,true);
				var bitmaploader:BitmapDataLoader = new BitmapDataLoader(this._allMaterials[i].image);
				var mc:MovieClip = new MovieClip  ;
				mc.visible = false;
				//bitmaploader.name = "bitmaploader_"+i;
				mc.addChild (bitmaploader);
				mc.name = "bitmaploader_" + i;
				trace("this._allModel["+i+"].modelSource: "+this._allMaterials[i].modelSource);
				var baseNode:FLARBaseNode = new FLARBaseNode  ;
				try
				{
					if (this._allMaterials[i].modelSource != "null")
					{
						daeModel.load (this._allMaterials[i].modelSource);


						daeModel.scale = this._allMaterials[i].scale;
						daeModel.x = this._allMaterials[i].x;
						daeModel.y = this._allMaterials[i].y;
						daeModel.z = this._allMaterials[i].z;
						daeModel.rotationX = this._allMaterials[i].rx;
						daeModel.rotationY = this._allMaterials[i].ry;
						daeModel.rotationZ = this._allMaterials[i].rz;
						var re:RegExp = /(\/)/;
						var results:Array = this._allMaterials[i].modelSource.split(re);
						daeModel.name = results[results.length - 1];

						//var baseNode:FLARBaseNode=new FLARBaseNode  ;
						baseNode.name = "baseNode_" + i;
						//trace("baseNode.name :"+baseNode.name);

						baseNode.addChild (daeModel);
					}
					else
					{
						trace ("Cube");
						pl = new PointLight3D();
						pl.x = 1000;
						pl.y = 1000;
						pl.z = -1000;
						var cubeMats:MaterialsList = new MaterialsList({all:new FlatShadeMaterial(pl,Math.random() * 0xFFFFFF)});
						var cube:Cube = new Cube(cubeMats,50,50,50,10,10,10);


						baseNode.name = "baseNode_" + i;
						baseNode.addChild (cube);
					}
				}
				catch (e:Error)
				{
					trace (e);
				}
				master.addChild (mc);
				this._scene.addChild (baseNode);
			}

			this._renderer = new LazyRenderEngine(this._scene,this._flarCam3D,this._vp);
			
		}
		//=====================================================================================================================================
		private function initListeners ():void
		{
			addEventListener (Event.ENTER_FRAME,render);


		}
		//=====================================================================================================================================
		private function render (event:Event):void
		{
			
			
			this._capture.bitmapData.draw (this._vid,_mirrorMatrix);
			//var bmp:Bitmap = new Bitmap(this._capture.bitmapData);
			//bmp.width = _trackWidth/_camWidth;
			//bmp.height = _trackHeight/_camHeight;
			
			this._trackcap.bitmapData.draw(_vid,_sacleMatrix);
			//this._trackcap.bitmapData.draw(_vid,_sacleMatrix);
			var markerId:int = -1;
			var i:int = 0;

			//var curr_count:int = -1;
			if (! _trackLock)
			{//frist step to track the fisrt tracked marker
				//trace("Multi track marker**********");
				for (i=0; i<this._allMarkers.length; i++)
				{
					if (this._detectors.detectMarkerLite(this._raster,65) && this._detectors.getConfidence(i) > .5)
					{
						markerId = this._detectors.getARCodeIndex(i);
						//trace("in Multi tracek routine markerId: "+markerId+"&&& i = "+i);
						this._detectors.getTransmationMatrix (i,this.transMats[markerId].result);
						this.transMats[markerId].isShow = true;
						this._trackMarkerId = markerId;
						_trackLock = true;
						this._timer.start ();
						this._timer.reset ();

						Twease.tween ( _obj_fadeIn );
						master.getChildByName("bitmaploader_" + this._trackMarkerId).visible = true;

						open_snd.play ();
						break;
					}
				}
			}
			else
			{//second step to keep traking the first tracked marker
				//trace("single marker track");
				for (i=0; i<this._allMarkers.length; i++)
				{
					if (this._detectors.detectMarkerLite(this._raster,65) && this._detectors.getConfidence(i) > .5)
					{
						markerId = this._detectors.getARCodeIndex(i);
						if (this._trackMarkerId == markerId)
						{//if the firsttrack marker is equal to the tracked marker
							//trace("in single tracek routine markerId: "+markerId+"&&& i = "+i);
							this._detectors.getTransmationMatrix (i,this.transMats[markerId].result);
							this.transMats[markerId].isShow = true;
							this._timer.reset ();
							this._timer.start ();
							//trace("_timer reset &&&&& track target marker");

						}

					}
				}
			}

			//apply the transform matricies to the basenodes
			for (var j:Number=0; j<this._allMarkers.length; j++)
			{
				//var j = markerId;
				var tflartransmatresult:FLARTransMatResult = this.transMats[j].result;
				if (this.transMats[j].isShow)
				{
					FLARBaseNode(this._scene.getChildByName("baseNode_" + j)).setTransformMatrix (tflartransmatresult);
					this._scene.getChildByName("baseNode_" + j).visible = true;
					//master.getChildByName("bitmaploader_"+trackMarkerId).visible=true;

				}
				else
				{
					this._scene.getChildByName("baseNode_" + j).visible = false;
					//master.getChildByName("bitmaploader_"+j).visible=false;
				}
				this.transMats[j].isShow = false;

			}

			this._renderer.render ();

		}
		//==============================================================================================
		public function _timerUpdate (event:TimerEvent):void
		{
			//trace("timerupdate :this._timer.currentCount :"+ this._timer.currentCount);
			if (this._timer.currentCount >= this._timeout)
			{
				this._timer.stop ();
				this._timer.reset ();

				Twease.tween ( _obj_fadeOut );

				//trace("_timer reset &&&&&& _trackLock NOT LOCK");
			}

		}
		
		private function afterFadeIn (to,po,q):void
		{
			//setChildIndex(stats,numChildren-1);
			trace("after fade in");
		}
		
		private function afterFadeOut (to,po,q):void
		{
			if (this._trackMarkerId > -1)
			{
				master.getChildByName("bitmaploader_" + this._trackMarkerId).visible = false;
			}
			this._trackLock = false;
		}

	}
}