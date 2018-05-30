/*
 viewport.js
 Client
 
 Created by Mahmoud Adam on 6/14/16.
 Copyright © 2016 CLIQZ. All rights reserved.
 */


// view port meta tag

var element = document.getElementById("viewport-tag", document.head);
element && element.parentNode.removeChild(element);

var meta = document.createElement('meta');
meta.setAttribute('name', 'viewport');
meta.setAttribute('id', 'viewport-tag');
meta.setAttribute('content', 'height=device-height, width=device-width,minimum-scale=1.0001, user-scalable=no');
document.head.appendChild(meta);