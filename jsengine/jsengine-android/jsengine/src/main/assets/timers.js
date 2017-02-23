var __nativeST__ = setTimeout;

setTimeout = function (vCallback, nDelay /*, argumentToPass1, argumentToPass2, etc. */) {
    var aArgs = Array.prototype.slice.call(arguments, 2);
    return __nativeST__(vCallback instanceof Function ? function () {
                        vCallback.apply(null, aArgs);
                        } : vCallback, nDelay);
};

var __nativeSI__ = setInterval;

setInterval = function (vCallback, nDelay /*, argumentToPass1, argumentToPass2, etc. */) {
    var aArgs = Array.prototype.slice.call(arguments, 2);
    return __nativeSI__(vCallback instanceof Function ? function () {
  vCallback.apply(null, aArgs);
                        } : vCallback, nDelay);
};
