import { Loader } from "././Loader";
import { URL } from "././URL";
import { EventDispatcher } from "../events/EventDispatcher"
	import { Render } from "../renders/Render"
	import { HTMLCanvas } from "../resource/HTMLCanvas"
	import { Browser } from "../utils/Browser"
	import { Texture2D } from "../resource/Texture2D"
	
	/**
	 * @private
	 * Worker Image加载器
	 */
	export class WorkerLoader extends EventDispatcher {
		
		/**单例*/
		 static I:WorkerLoader;
		/**worker.js的路径 */
		 static workerPath:string = "libs/workerloader.js";
		
		/**@private */
		private static _preLoadFun:Function;
		/**@private */
		private static _enable:boolean = false;
		/**@private */
		private static _tryEnabled:boolean = false;
		
		/**使用的Worker对象。*/
		 worker:Worker;
		/**@private */
		protected _useWorkerLoader:boolean;
		
		constructor(){
			super();
this.worker = new Worker(WorkerLoader.workerPath);
			this.worker.onmessage = function(evt:any):void {
				//接收worker传过来的数据函数
				this.workerMessage(evt.data);
			}
		}
		
		/**
		 * 尝试使用Work加载Image
		 * @return 是否启动成功
		 */
		 static __init__():boolean {
			if (WorkerLoader._preLoadFun != null) return false;
			if (!Worker) return false;
			WorkerLoader._preLoadFun = Loader["prototype"]["_loadImage"];
			Loader["prototype"]["_loadImage"] = WorkerLoader["prototype"]["_loadImage"];
			if (!WorkerLoader.I) WorkerLoader.I = new WorkerLoader();
			return true;
		}
		
		/**
		 * 是否支持worker
		 * @return 是否支持worker
		 */
		 static workerSupported():boolean {
			return Worker ? true : false;
		}
		
		/**
		 * 尝试启用WorkerLoader,只有第一次调用有效
		 */
		 static enableWorkerLoader():void {
			if (!WorkerLoader._tryEnabled) {
				WorkerLoader.enable = true;
				WorkerLoader._tryEnabled = true;
			}
		}
		
		/**
		 * 是否启用。
		 */
		 static set enable(value:boolean) {
			if (WorkerLoader._enable != value) {
				WorkerLoader._enable = value;
				if (value && WorkerLoader._preLoadFun == null) WorkerLoader._enable = WorkerLoader.__init__();
			}
		}
		
		 static get enable():boolean {
			return WorkerLoader._enable;
		}
		
		/**
		 * @private
		 */
		private workerMessage(data:any):void {
			if (data) {
				switch (data.type) {
				case "Image": 
					this.imageLoaded(data);
					break;
				case "Disable": 
					WorkerLoader.enable = false;
					break;
				}
			}
		}
		
		/**
		 * @private
		 */
		private imageLoaded(data:any):void {
			if (!data.dataType || data.dataType != "imageBitmap") {
				this.event(data.url, null);
				return;
			}
			
			//TODO:
			var canvas:HTMLCanvas = new HTMLCanvas(true);
			var ctx:any = canvas.source.getContext("2d");
			
			switch (data.dataType) {
			case "imageBitmap": 
				var imageData:any = data.imageBitmap;
				canvas.size(imageData.width, imageData.height);
				ctx.drawImage(imageData, 0, 0);
				break;
			}
			console.log("load:", data.url);
			//避免被计算两次
			canvas._setGPUMemory(0);
			var tex:Texture2D = new Texture2D();
			tex.loadImageSource(canvas.source);
			//canvas = tex;
			this.event(data.url, tex);
		}
		
		/**
		 * 加载图片
		 * @param	url 图片地址
		 */
		 loadImage(url:string):void {
			this.worker.postMessage(url);
		}
		
		/**
		 * @private
		 * 加载图片资源。
		 * @param	url 资源地址。
		 */
		protected _loadImage(url:string):void {
			var _this:Loader = (<Loader>this );
			if (!this._useWorkerLoader || !WorkerLoader._enable) {
				WorkerLoader._preLoadFun.call(_this, url);
				return;
			}
			url = URL.formatURL(url);
			function clear():void {
				WorkerLoader.I.off(url, _this, onload);
			}
			
			var onload:Function = function(image:any):void {
				clear();
				if (image) {
					_this["onLoaded"](image);
				} else {
					//失败之后使用原版的加载函数加载重试
					WorkerLoader._preLoadFun.call(_this, url);
				}
			};
			WorkerLoader.I.on(url, _this, onload);
			WorkerLoader.I.loadImage(url);
		}
	}
