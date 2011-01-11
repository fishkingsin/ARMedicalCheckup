/**
 * Hi-ReS! Stats
 * 
 * Released under MIT license:
 * http://www.opensource.org/licenses/mit-license.php
 *
 * How to use:
 * 
 *	element.appendChild( Stats.init(60) );
 * 
 * version log:
 *
 * 	09.06.18		1.1		Mr.doob			+ Firefox support
 * 	09.06.10		1.0		Mr.doob			+ First version
 **/

var Stats =
{
	baseFps: null,
	
	timer: null,
	timerStart: null,
	timerLast: null,
	fps: null,
	ms: null,
	
	container: null,
	fpsText: null,
	msText: null,
	memText: null,
	memMaxText: null,
	
	graph: null,
	graphData: null,
	
	init: function(userfps)
	{
		baseFps = userfps;
		
		timer = 0;
		timerStart = new Date() - 0;
		timerLast = 0; 
		fps = 0;
		ms = 0;
		
		container = document.createElement("div");
		container.style.fontFamily = 'Arial';
		container.style.fontSize = '10px';
		container.style.backgroundColor = '#000033';
		container.style.width = '70px';
		container.style.paddingTop = '2px';
				
		fpsText = document.createElement("div");
		fpsText.style.color = '#ffff00';
		fpsText.style.marginLeft = '3px';
		fpsText.style.marginBottom = '-3px';
		fpsText.innerHTML = "FPS:";
		container.appendChild(fpsText);

		msText = document.createElement("div");
		msText.style.color = '#00ff00';
		msText.style.marginLeft = '3px';
		msText.style.marginBottom = '-3px';
		msText.innerHTML = "MS:";
		container.appendChild(msText);

		memText = document.createElement("div");
		memText.style.color = '#00ffff';
		memText.style.marginLeft = '3px';
		memText.style.marginBottom = '-3px';
		memText.innerHTML = "MEM:";
		container.appendChild(memText);

		memMaxText = document.createElement("div");
		memMaxText.style.color = '#ff0070';
		memMaxText.style.marginLeft = '3px';
		memMaxText.style.marginBottom = '3px';
		memMaxText.innerHTML = "MAX:";
		container.appendChild(memMaxText);
		
		var canvas = document.createElement("canvas");
		canvas.width = 70;
		canvas.height = 50;
		container.appendChild(canvas);
				
		graph = canvas.getContext("2d");
		graph.fillStyle = '#000033';
		graph.fillRect(0, 0, canvas.width, canvas.height );
		
		graphData = graph.getImageData(0, 0, canvas.width, canvas.height);
		
		setInterval(this.update, 1000/baseFps);
		
		return container;
	},
	
	update: function()
	{
		timer = new Date() - timerStart;

		if ((timer - 1000) > timerLast)
		{
			fpsText.innerHTML = "FPS: " + fps + " / " + baseFps;
			timerLast = timer;
		
			graphData = graph.getImageData(0, 0, 69, 50);		
			graph.putImageData(graphData, 1, 0);
			
			graph.fillRect(0,0,1,50);
			graphData = graph.getImageData(0, 0, 1, 50);
			
			var index = ( Math.floor(50 - Math.min(50, (fps / baseFps) * 50)) * 4 );
			graphData.data[index] = graphData.data[index + 1] = 255;
			
			index = ( Math.floor(50 - Math.min(50, (timer - ms) * .5)) * 4 );
			graphData.data[index + 1] = 255;			
			
 			graph.putImageData (graphData, 0, 0);
			
			fps = 0;			
		}
		
		++fps;
		
		msText.innerHTML = "MS: " + (timer - ms);
		ms = timer;
	}
	
}