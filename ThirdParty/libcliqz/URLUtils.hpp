//
//  utils.hpp
//  libcliqz
//
//  Created by Stefano Pacifici on 28/02/17.
//  Copyright © 2017 Stefano Pacifici. All rights reserved.
//

#ifndef utils_h
#define utils_h

#include <string>

namespace cliqz {
    
    struct UrlDetails {
        const std::string scheme;
        const std::string name;
        const std::string domain;
        const std::string tld;
        const std::string subdomains;
        const std::string path;
        const std::string query;
        const std::string fragment;
        const std::string extra;
        const std::string host;
        const std::string cleanHost;
        const bool ssl;
        const short port;
        const std::string friendlyUrl;
    };
    
    UrlDetails getDetailsFromUrl(const std::string& url);
}

#endif /* utils_h */
