package org.ascollada.core {
	import flash.errors.IllegalOperationError;
	
	import org.ascollada.core.ns.collada;

	/**
	 * @author Tim Knip / floorplanner.com
	 */
	public class DaeSkin extends DaeElement {
		use namespace collada;
		
		/** */
		public var source : String;
		
		/**
		 * 
		 */ 
		public var bind_shape_matrix : DaeTransform;
		
		/**
		 * 
		 */ 
		public var joints : Vector.<Vector.<String>>; // inside Vector is always 1 element long
		
		/**
		 * 
		 */ 
		public var inv_bind_matrix : Vector.<DaeTransform>;
		
		/**
		 * 
		 */ 
		public var vertex_weights : Vector.<Vector.<DaeBlendWeight>>;
		
		/**
		 * 
		 */
		public function DaeSkin(document : DaeDocument, element : XML = null) {
			super(document, element);
		}
		
		/**
		 * 
		 */
		override public function destroy() : void {
			super.destroy();
			
			if(this.bind_shape_matrix) {
				this.bind_shape_matrix.destroy();
				this.bind_shape_matrix = null;
			}
			
			this.joints = null;
			this.inv_bind_matrix = null;
			this.vertex_weights = null;
		}

    /**
     * 
     */
    public function getBlendWeightsForVertexIndex(vertexIndex : int) : Vector.<DaeBlendWeight> {
      var i : int, j: int;
      var result : Vector.<DaeBlendWeight> = new Vector.<DaeBlendWeight>();
      
      for(i = 0; i < this.vertex_weights.length; i++) {
        for(j = 0; j < this.vertex_weights[i].length; j++) {
          var bw : DaeBlendWeight = this.vertex_weights[i][j];
          if(bw.vertexIndex == vertexIndex) {
            result.push(bw);
          }
        }
      }
      
      return result;
    }
    
		/**
		 * 
		 */
		public function getBlendWeightsForJoint(joint : String) : Vector.<DaeBlendWeight> {
			var i : int, j: int;
			var result : Vector.<DaeBlendWeight> = new Vector.<DaeBlendWeight>();
			
			for(i = 0; i < this.vertex_weights.length; i++) {
				for(j = 0; j < this.vertex_weights[i].length; j++) {
					var bw : DaeBlendWeight = this.vertex_weights[i][j];
					if(bw.joint == joint) {
						result.push(bw);
					}
				}
			}
			
			return result;
		}
		
		/**
		 * 
		 */
		override public function read(element : XML) : void {
			super.read(element);
			
			this.source = readAttribute(element, "source", true);
			
			var list : XMLList = element["bind_shape_matrix"];
			
			// bind shape matrix
			if(list[0]) {
				this.bind_shape_matrix = new DaeTransform(this.document, list[0]);
			} else {
				this.bind_shape_matrix = new DaeTransform(this.document);
				this.bind_shape_matrix.data = Vector.<Number>([1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]);
			}
			this.bind_shape_matrix.nodeName = "matrix";
			
			readJoints(element["joints"][0]);
			readWeights(element["vertex_weights"][0]);
		}

		/**
		 * 
		 */ 
		private function readJoints(element:XML):void
		{
			if(!element) {
				throw new IllegalOperationError("DaeSkin expects a single <joints> element!");
			}
			
			var a :XML = element["input"].(@semantic == "JOINT")[0];
			var b :XML = element["input"].(@semantic == "INV_BIND_MATRIX")[0];
			
			if(!a || !b) {
				throw new IllegalOperationError("DaeSkin <joints> element misses a required <input> element!");
			}
			
			var ainput :DaeInput = new DaeInput(null, a);
			var binput :DaeInput = new DaeInput(null, b);
			var asource :DaeSource = this.document.sources[ainput.source];
			var bsource :DaeSource = this.document.sources[binput.source];
			var i :int, j :int;
			
			this.joints = asource.dataString;
			this.inv_bind_matrix = new Vector.<DaeTransform>();
			
			for(i = 0; i < bsource.dataFloat.length; i++) {
				var transform : DaeTransform = new DaeTransform(this.document);

				transform.data = bsource.dataFloat[i];
				transform.nodeName = "matrix";

				this.inv_bind_matrix.push(transform);	
			}
		}
		
		/**
		 * 
		 */ 
		private function readWeights(element:XML):void {
			if(!element) {
				throw new IllegalOperationError("DaeSkin expects a single <vertex_weights> element!");
			}
			
			var a :XML = element["input"].(@semantic == "JOINT")[0];
			var b :XML = element["input"].(@semantic == "WEIGHT")[0];
			
			if(!a || !b) {
				throw new IllegalOperationError("DaeSkin <vertex_weights> element misses a required <input> element!");
			}
			
			var ainput :DaeInput = new DaeInput(null, a);
			var binput :DaeInput = new DaeInput(null, b);
			
			//var asource :DaeSource = document.sources[ainput.source];
			var bsource :DaeSource = document.sources[binput.source];
			var inputCount :uint = element["input"].length();
			var i :int, j:int;

			if(!element["v"][0]) {
				trace("DaeSkin : <vertex_weights> elements does not have a <v> element!");
				return;
			}
			
			if(!element["vcount"][0]) {
				trace("DaeSkin : <vertex_weights> elements does not have a <v> element!");
				return;
			}
			
			var v:Array = readStringArray(element["v"][0]);
			var vcount :Array = readStringArray(element["vcount"][0]);
			var cur :int = 0;
			
			this.vertex_weights = new Vector.<Vector.<DaeBlendWeight>>();
			
			for(i = 0; i < vcount.length; i++) {
				var vc:int = vcount[i];
				
				var tmp:Vector.<DaeBlendWeight> = new Vector.<DaeBlendWeight>();
					
				for(j = 0; j < vc; j++) {
					var jidx:int = v[cur + ainput.offset];
					var widx:int = v[cur + binput.offset];
					
					var weight : Number = bsource.dataFloat[widx][0];
					
					tmp.push(new DaeBlendWeight(i, this.joints[jidx][0], weight));
				
					cur += inputCount;
				}
				
				this.vertex_weights.push(tmp);
			}
		}
	}
}
