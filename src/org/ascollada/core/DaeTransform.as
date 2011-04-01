package org.ascollada.core {
	import org.ascollada.core.ns.collada;
	
	/**
	 * @author Tim Knip / floorplanner.com
	 */
	public class DaeTransform extends DaeElement {
		use namespace collada;
		
		/**
		 * 
		 */
		public var data : Vector.<Number>;
		
		/**
		 * 
		 */
		public function DaeTransform(document : DaeDocument, element : XML = null) {
			this.data = new Vector.<Number>();
			super(document, element);
			// this.nodeName contains the transform type (rotate, scale, translate, matrix, lookat, skew)
		}
		
		/**
		 * 
		 */
		override public function destroy() : void {
			super.destroy();
			this.data = null;
		}

		/**
		 * 
		 */
		override public function read(element : XML) : void {
			super.read(element);
			
			var stringData:Array = readStringArray(element);
			
			for(var i : int = 0; i < stringData.length; i++) {
				this.data[i] = parseFloat(stringData[i]);
			}
		}
	}
}
