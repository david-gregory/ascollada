package org.ascollada.core {
	import org.ascollada.core.ns.collada;

	/**
	 * @author Tim Knip / floorplanner.com
	 */
	public class DaePrimitive extends DaeElement {
		use namespace collada;
		
		/**
		 * 
		 */
		public var material : String;
		
		/**
		 * 
		 */
		public var vertices : DaeVertices;
		
		/**
		 * 
		 */
		public var count : int;
		
		/**
		 * 
		 */
		public var triangles : Vector.<Vector.<uint>>;
		
		/**
		 * 
		 */
		public var normals : Vector.<Vector.<uint>>;

		/**
		 *
		 */
		public var normalInput : DaeInput;
		
		/**
		 * Use the interface getTexCoordInput(setNum) to access the proper DaeInput.  See Note below as to why.
		 */
		private var texCoordInputs : Vector.<DaeInput>; // looked up via input_set
		
		/**
		 * Use the interface getUVSet(setNum) to access the proper uv's.
		 * This structure is private because looking up by set number isn't always the correct way to look up uv's.
		 * When there is only one set, the Collada spec says that set num may not be specified.  We've seen examples
		 * of Collada exported that contained an input_set=1 reference when there was only one set of uv's.
		 */
		private var uvSets : Object; // adhoc dict - setNum -> Vector.<Vector.<uint>>
		
		/**
		 * 
		 */
		public function DaePrimitive(document : DaeDocument, vertices :DaeVertices, element : XML = null) {
			this.vertices = vertices;
			super(document, element);
		}

		/**
		 * 
		 */
		override public function destroy() : void {
			super.destroy();
			
			var element : DaeElement;
			if(this.texCoordInputs) {
				while(this.texCoordInputs.length) {
					element = this.texCoordInputs.pop() as DaeElement;
					element.destroy();
					element = null;
				}
				this.texCoordInputs = null;
			}

			this.uvSets = null;
			this.normalInput = null;
			this.normals = null;
			this.triangles = null;
			this.vertices = null;
			this.material = null;
		}

		/**
		 * 
		 */
		override public function read(element : XML) : void {
			super.read(element);
			
			this.material = readAttribute(element, "material", true);
			this.count = parseInt(readAttribute(element, "count"), 10);
			this.triangles = new Vector.<Vector.<uint>>();
			this.normals = new Vector.<Vector.<uint>>();
			this.uvSets = new Object();
			this.texCoordInputs = new Vector.<DaeInput>();
			
			var list : XMLList = element["input"];
			var child : XML;
			var inputs : Vector.<DaeInput> = new Vector.<DaeInput>();
			var maxOffset : int = 0;
			
			for each(child in list) {
				var input : DaeInput = new DaeInput(this.document, child);		
				switch(input.semantic) {
					case "VERTEX":
						input.source = this.vertices.source.id;
						break;
					case "TEXCOORD":
						this.uvSets[input.setnum] = new Vector.<Vector.<uint>>();
						this.texCoordInputs.push(input);
						break;
					case "NORMAL":
						this.normalInput = input;
						break;
					default:
						break;
				}
				maxOffset = Math.max(maxOffset, input.offset);
				inputs.push(input);
			}
			
			var primitives : XMLList = element["p"];
			var vc : XML = element["vcount"][0];
			var vcount : Array = vc ? readStringArray(vc) : null;
			
			switch(this.nodeName) {
				case "triangles":
					buildTriangles(primitives, inputs, maxOffset + 1);
					break;
				case "polylist":
					buildPolylist(primitives[0], vcount, inputs, maxOffset + 1);
					break;
				default:
					//trace("don't know how to process primitives of type : " + this.nodeName);
					break;
			}
		}
		
		public function getTexCoordInput(requestedSetNum:int):DaeInput
		{
			// if there's only one DaeInput for uv's, return that one. 
			if (this.texCoordInputs.length == 1)
			{
				return this.texCoordInputs[0];
			}
			else
			{
				return this.texCoordInputs[requestedSetNum];
			}
		}
		
		public function getUVSet(requestedSetNum:int):Vector.<Vector.<uint>>
		{
			var numUVSets : uint;
			for each (var o:* in this.uvSets)
			{
				numUVSets++;
			}
			
			// if there's only one uvIndex vector, return that one. 
			if (numUVSets == 1)
			{
				return this.uvSets[0];
			}
			else
			{
				return this.uvSets[requestedSetNum];
			}
		}
		
		private function buildPolylist(primitive : XML, vcount:Array, inputs : Vector.<DaeInput>, maxOffset : int) : void {
			var input : DaeInput;
			var p : Array = readStringArray(primitive);
			var i : int, j : int, pid : int = 0;

			for(i = 0; i < vcount.length; i++) {
				var numVerts : int = parseInt(vcount[i], 10);
				var poly : Vector.<uint> = new Vector.<uint>();
				var uvs : Object = new Object();
				var normal : Vector.<uint> = new Vector.<uint>();
        
				for(j = 0; j < numVerts; j++) {
					for each(input in inputs) {
						
						uvs[input.setnum] = uvs[input.setnum] || new Vector.<uint>();
						var index : uint = parseInt(p[pid + input.offset], 10);
						
						switch(input.semantic) {
							case "VERTEX":
								poly.push(index);
								break;
							case "TEXCOORD":
								uvs[input.setnum].push(index);
								break;
							case "NORMAL":
								normal.push(index);
							default:
								break;
						}
					}
					pid += maxOffset;	
				}
				
				// simple triangulation
				for(j = 1; j < poly.length - 1; j++) {
					this.triangles.push(new Vector.<uint>([poly[0], poly[j], poly[j+1]]));
					for(var o:String in uvs) {
						this.uvSets[o].push(new Vector.<uint>([uvs[o][0], uvs[o][j], uvs[o][j+1]]));
					}
					this.normals.push(new Vector.<uint>([normal[0], normal[j], normal[j+1]]));
				}
			}
		}
		
		private function buildTriangles(primitives : XMLList, inputs : Vector.<DaeInput>, maxOffset : int) : void {
			var input : DaeInput;
			var primitive : XML;
			var index : int;
			var source : DaeSource;
			var i : int;
			
			for each(primitive in primitives) {
				var p : Array = readStringArray(primitive);
				var tri : Vector.<uint> = new Vector.<uint>();
				var tmpUV : Object = new Object();
				var normal : Vector.<uint> = new Vector.<uint>();
				
				for each(input in inputs) {
					if(input.semantic == "TEXCOORD") {
						tmpUV[input.setnum] = new Vector.<uint>();
					}
				}
        
				while(i < p.length) {
					for each(input in inputs) {
						source = this.document.sources[input.source];
						index = parseInt(p[i + input.offset], 10);
						
						switch(input.semantic) {
							case "VERTEX":
								tri.push(index);
								if(tri.length == 3) {
									this.triangles.push(tri);
									tri = new Vector.<uint>();
								}
								break;
							case "TEXCOORD":
								tmpUV[input.setnum].push(index);
								if(tmpUV[input.setnum].length == 3) {
									this.uvSets[input.setnum].push(tmpUV[input.setnum]);
									tmpUV[input.setnum] = new Vector.<uint>();
								}
								break;
							case "NORMAL":
								normal.push(index);
								if(normal.length == 3) {
									this.normals.push(normal);
									normal = new Vector.<uint>();
								}
								break;
							default:
								break;
						}
					}
					i += maxOffset;
				}
			}
		}
	}
}
