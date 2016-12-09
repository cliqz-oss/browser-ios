function modifyLinkTargets() {
	var allLinks = document.getElementsByTagName('a');
	if (allLinks) {
		var i;
		for (i=0; i<allLinks.length; i++) {
			var link = allLinks[i];
			var target = link.getAttribute('target');
			if (target && target == '_blank') {
				link.setAttribute('target','_self');
				link.href = 'newtab:'+escape(link.href);
			}
		}
	}
}

modifyLinkTargets();
