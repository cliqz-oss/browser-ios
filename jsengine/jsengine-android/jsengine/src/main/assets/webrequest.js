
var webRequest = {
    onBeforeRequest: {
        listeners: [],
        addListener: function(listener, filter, extraInfo) {
          this.listeners.push({fn: listener, filter: filter, extraInfo: extraInfo});
        },
        removeListener: function(listener) {
          const ind = this.listeners.findIndex(function(l) {
            return l.fn === listener;
          });
          if (ind > -1) {
            this.listeners.splice(ind, 1);
          }
        },

        _triggerJson: function(requestInfoJson) {
          const requestInfo = JSON.parse(requestInfoJson);
          try {
              const response = webRequest.onBeforeRequest._trigger(requestInfo) || {};
              return JSON.stringify(response);
          } catch(e) {
            console.error('webrequest trigger error', e);
          }
        },

        _trigger: function(requestInfo) {
          // getter for request headers
          console.log('webrequest._trigger');
          console.log('webrequest._trigger requestInfo ', requestInfo);
          requestInfo.getRequestHeader = function(header) {
            return requestInfo.requestHeaders[header];
          };
          for (var i=0; i < this.listeners.length; i++) {
            const listener = this.listeners[i];
            const fn = listener.fn;
            const filter = listener.filter;
            const extraInfo = listener.extraInfo;
            const blockingResponse = fn(requestInfo);
            if (blockingResponse && Object.keys(blockingResponse).length > 0) {
                console.log('webrequest._trigger return ', blockingResponse);
                return blockingResponse;
            }
          }
          console.log('webrequest._trigger return empty');
          return {};
        }
      },

      onBeforeSendHeaders: {
        addListener: function(listener, filter, extraInfo) {},
        removeListener: function(listener) {}
      },

      onHeadersReceived: {
        addListener: function(listener, filter, extraInfo) {},
        removeListener: function(listener) {}
      }
}
