package site.view;

import ithril.*;
import ithril.M.*;
using Reflect;
// Top level page wrapper wraps all pages
class HtmlBase extends Component {
#if browser
	override public function oncreate(vnode) setup(vnode);
	override public function onupdate(vnode) setup(vnode);
	function setup(vnode) {
		if (vnode.attrs.title != null) js.Browser.document.title = vnode.attrs.title;
		if (vnode.attrs.link == null) return;
		for (link in (vnode.attrs.links:Array<Dynamic>)) {
			if (link.rel == "icon") {
				var icon = js.Browser.document.head.querySelector('link[rel=icon]');
				icon.setAttribute('href', link.href);
				icon.setAttribute('type', link.type);
				break;
			}
		}
	}
#end

	override public function view(vnode:Vnode) {
		var component:Dynamic = Type.resolveClass(vnode.attrs.component);
		var attrs:Dynamic = vnode.attrs;
		var txt:String = null;
		if (component == null) {
			component = "div";
			attrs = { };
			txt = "Missing Component: " + vnode.attrs.component;
		}
		var head:Dynamic = null;
		if (vnode.attrs.head != null)
			head = Type.resolveClass(vnode.attrs.head);

		return @m[
#if !browser
		(!doctype)
		(html(lang='en'))

		(head)
			(title > vnode.attrs.title)
			(vnode.attrs.html.meta >> data)
				(meta(data))
			(vnode.attrs.html.link >> attributes)
				(link(attributes))
			(vnode.attrs.html.include.css >> css)
				($if (css.attributes.rel == "stylesheet"))
					(link(css.attributes))
				($else)
					(style(css.attributes) > @trust css.content)
			($if (head != null))
				[m(head, attrs)]
		(body)
#end
			($if (component != null))
				[m(component, attrs, txt)]
#if !browser
			(vnode.attrs.html.include.script >> script)
				($if (script.content == null))
					(script(script.attributes))
				($else)
					(script(script.attributes) > @trust script.content)
#end
		];
	}
}
