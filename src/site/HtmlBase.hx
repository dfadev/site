package site;

import ithril.*;
import ithril.M.*;
using Reflect;
// Top level page wrapper wraps all pages
class HtmlBase extends Component {
#if browser
	override public function oncreate(vnode) setup(vnode);
	override public function onupdate(vnode) setup(vnode);
	function setup(vnode) {
		js.Browser.document.title = vnode.attrs.title;
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

	override public function view(vnode:Vnode) @m[
#if !browser
		(!doctype)
		(html(lang='en'))

		(head)
			(title > vnode.attrs.title)
			(vnode.attrs.meta >> data)
				(meta(data))
			(vnode.attrs.link >> attributes)
				(link(attributes))
			(vnode.attrs.css >> css)
				(style(css.attributes) > @trust css.content)
		(body)
#end
			[m(Type.resolveClass(vnode.attrs.component), vnode.attrs)]
#if !browser
			(vnode.attrs.script >> script)
				($if (script.content == null))
					(script(script))
				($else)
					(script(script.attributes) > @trust script.content)
#end
	];
}
