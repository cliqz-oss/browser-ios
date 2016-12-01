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

function modifyWindowOpen() {
	window.open =
	function(url,target,param) {
		if (url && url.length > 0) {
			if (target == '_blank' && url.startsWith("http")) {
				location.href = 'newtab:'+escape(url);
			} else {
				location.href = url;
			}
		}
	}
}

modifyLinkTargets();
modifyWindowOpen();
