/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Based on idea from: http://www.icab.de/blog/2010/07/11/customize-the-contextual-menu-of-uiwebview/

(function(x, y) {
 function parseUrl(url) {
 function begins(str, startStr) { // in case no String.startsWith
 return str.indexOf(startStr) == 0
 }
 // Cliqz: encode url to support German characters
 url = encodeURI(url);
 if (begins(url, 'newtab:')) {
 url = unescape(url.substring('newtab:'.length))
 }
 
 if (begins(url, 'http')) {
 return url;
 } else if (begins(url, 'mailto:')) {
 return url;
 } else if (begins(url, '//')) {
 return window.location.protocol + url;
 } else {
 var path = window.location.hostname + '/' + url;
 path = path.replace('//', '/')
 return window.location.protocol + '//' + path;
 }
 }
 
 var e = document.elementFromPoint(x, y);
 var result = {}
 for (var i = 0; e && i < 5; i++)  {
 if (!e.tagName) {
 e = e.parentNode;
 continue;
 }
 
 if (e.tagName === 'A') {
 result['link'] = parseUrl(e.getAttribute('href'));
 result['target'] = e.getAttribute('target');
 break;
 } else if (e.tagName === 'IMG') {
 result['imagesrc'] = parseUrl(e.getAttribute('src'));
 }
 
 e = e.parentNode;
 }
 
 return JSON.stringify(result);
 })


