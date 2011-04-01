package org.ascollada.core {
	import flash.errors.IllegalOperationError;
	
	import org.ascollada.core.ns.collada;

	/**
	 * @author Tim Knip / floorplanner.com
	 */
	public class DaeSource extends DaeElement {
		use namespace collada;
		
		// Notes:
		// * only one of dataFloat, dataString, dataInt, dataBool will be allocated.
		// * the inside Vector will be accessor.stride elements long. this includes 1 stride accessors (which may seem odd)
		public var dataFloat : Vector.<Vector.<Number>>;
		public var dataString : Vector.<Vector.<String>>;
		public var dataInt : Vector.<Vector.<uint>>;
		public var dataBool : Vector.<Vector.<Boolean>>;
		public var dataType : String;
		public var accessor : DaeAccessor;
		public var channels : Vector.<DaeChannel>; // externally assigned in DaeDocument
		
		/**
		 * 
		 */
		public function DaeSource(document : DaeDocument, element : XML = null) {
			super(document, element);
		}

		/**
		 * 
		 */
		override public function destroy() : void {
			super.destroy();
			this.dataFloat = null;
			this.dataString = null;
			this.dataInt = null;
			this.dataBool = null;
			this.dataType = null;
			if(this.accessor) {
				this.accessor.destroy();
				this.accessor = null;
			}
			this.channels = null;
		}

		/**
		 * 
		 */
		override public function read(element : XML) : void {
			super.read(element);
			
			this.channels = new Vector.<DaeChannel>();
			this.dataType = "float_array";
			
			var list : XMLList = element[this.dataType];
			var stringData : Array;
			
			// read in the raw data
			if(list.length()) {
				stringData = readStringArray(list[0]);
			} else {
				this.dataType = "Name_array";
				list = element[this.dataType];
				if(list.length()) {
					stringData = readStringArray(list[0]);
				} else {
					this.dataType = "IDREF_array";
					list = element[this.dataType];
					if(list.length()) {
						stringData = readStringArray(list[0]);
					} else {
						this.dataType = "int_array";
						list = element[this.dataType];
						if(list.length()) {
							stringData = readStringArray(list[0]);
						} else {
							this.dataType = "bool_array";
							list = element[this.dataType];
							if(list.length()) {
								stringData = readStringArray(list[0]);
							} else {
								throw new IllegalOperationError("DaeSource : no data found!");
							}
						}
					}
				}
			}
			
			// read the accessor
			if(element..accessor[0]) {
				this.accessor = new DaeAccessor(this.document, element..accessor[0]);
			} else {
				throw new Error("[DaeSource] could not find an accessor!");
			}
			
			var i:int;
			
			// interleave data
			switch (this.dataType)
			{
				case "IDREF_array":
				case "Name_array":
					this.dataString = new Vector.<Vector.<String>>();
					for(i = 0; i < this.accessor.count; i++) {
						pushStringValues(stringData, i);
					}
					break;
				case "bool_array":
					this.dataBool = new Vector.<Vector.<Boolean>>();
					for(i = 0; i < this.accessor.count; i++) {
						pushBoolValues(stringData, i);
					}
					break;
				case "float_array":
					this.dataFloat = new Vector.<Vector.<Number>>();
					for(i = 0; i < this.accessor.count; i++) {
						pushFloatValues(stringData, i);
					}
					break;
				case "int_array":
					this.dataInt = new Vector.<Vector.<uint>>();
					for(i = 0; i < this.accessor.count; i++) {
						pushIntValues(stringData, i);
					}
					break;
			}
		}
		
		/**
		 * 
		 */ 
		private function pushStringValues(stringData:Array, index:int):void {
			var values : Vector.<String> = new Vector.<String>(); 
			var start : int = index * this.accessor.stride;
			var i : int;
			
			for(i = 0; i < this.accessor.stride; i++) {
				var value : String = stringData[start + i];
				values.push(value);
			}
			
			this.dataString.push(values);
		}
		
		private function pushBoolValues(stringData:Array, index:int):void {
			var values : Vector.<Boolean> = new Vector.<Boolean>(); 
			var start : int = index * this.accessor.stride;
			var i : int;
			
			for(i = 0; i < this.accessor.stride; i++) {
				var value : String = stringData[start + i];
				values.push((value == "true" || value == "1" ? true : false));
			}
			
			this.dataBool.push(values);
		}
		
		private function pushFloatValues(stringData:Array, index:int):void {
			var values : Vector.<Number> = new Vector.<Number>(); 
			var start : int = index * this.accessor.stride;
			var i : int;
			
			for(i = 0; i < this.accessor.stride; i++) {
				var value : String = stringData[start + i];
				if(value.indexOf(",") != -1) 
				{
					value = value.replace(/,/, ".");
				}
				values.push(parseFloat(value));
			}
			
			this.dataFloat.push(values);
		}

		private function pushIntValues(stringData:Array, index:int):void {
			var values : Vector.<uint> = new Vector.<uint>(); 
			var start : int = index * this.accessor.stride;
			var i : int;
			
			for(i = 0; i < this.accessor.stride; i++) {
				var value : String = stringData[start + i];
				values.push(parseInt(value, 10));
			}
			
			this.dataInt.push(values);
		}
	}
}
