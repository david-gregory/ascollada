package org.ascollada.core {	import org.ascollada.core.DaeElement;
	import org.ascollada.core.ns.collada;		/**	 * @author Tim Knip / floorplanner.com	 */	public class DaeAnimationClip extends DaeElement {		use namespace collada;					/** */		public var start : Number;				/** */		public var end : Number;				/** */		public var instances : Vector.<String>;				/** */		private var _instanceUrls : Object;				/**		 * 		 */		private static var _newID : int = 0;				/**		 * 		 */		public function DaeAnimationClip(document : DaeDocument, element : XML = null) {			super(document, element);		}		/**		 * 		 */		override public function destroy() : void {			super.destroy();			this.instances = null;		}		/**		 * 		 */		override public function read(element : XML) : void {			super.read(element);						this.id = (this.id && this.id.length) ? this.id : "animation_clip" + (_newID++);			this.name = (this.name && this.name.length) ? this.name : this.id;						this.start = parseFloat(readAttribute(element, "start"));			this.end = parseFloat(readAttribute(element, "end"));			this.instances = new Vector.<String>();						_instanceUrls = new Object();						var animation : DaeAnimation;			var list : XMLList = element["instance_animation"];			var child : XML;			var num : int = list.length();			var i : int;						for(i = 0; i < num; i++) {				child = list[i];								var url : String = readAttribute(child, "url");								if(url.charAt(0) == "#") {					url = url.substr(1);					}								this.instances.push(url);								_instanceUrls[url] = i;								animation = this.document.animations[url];								if(animation) {					if(animation.clips.indexOf(this) == -1) {						animation.clips.push(this);					}				}			}		}
	}}