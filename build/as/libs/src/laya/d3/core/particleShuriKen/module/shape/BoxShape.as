package laya.d3.core.particleShuriKen.module.shape {
	import laya.d3.core.particleShuriKen.module.shape.BaseShape;
	import laya.d3.math.Rand;
	import laya.d3.math.Vector3;

	/**
	 * <code>BoxShape</code> 类用于创建球形粒子形状。
	 */
	public class BoxShape extends BaseShape {

		/**
		 * 发射器X轴长度。
		 */
		public var x:Number;

		/**
		 * 发射器Y轴长度。
		 */
		public var y:Number;

		/**
		 * 发射器Z轴长度。
		 */
		public var z:Number;

		/**
		 * 创建一个 <code>BoxShape</code> 实例。
		 */

		public function BoxShape(){}

		/**
		 * 用于生成粒子初始位置和方向。
		 * @param position 粒子位置。
		 * @param direction 粒子方向。
		 * @override 
		 */
		override public function generatePositionAndDirection(position:Vector3,direction:Vector3,rand:Rand = null,randomSeeds:Uint32Array = null):void{}

		/**
		 * @param destObject 
		 * @override 
		 */
		override public function cloneTo(destObject:*):void{}

		/**
		 * @override 克隆。
		 * @return 克隆副本。
		 */
		override public function clone():*{}
	}

}
