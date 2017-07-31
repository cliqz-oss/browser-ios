//
//  utils.cpp
//  libcliqz
//
//  Created by Stefano Pacifici on 21/02/17.
//  Copyright © 2017 Stefano Pacifici. All rights reserved.
//

#include "URLUtils.hpp"
#include <iostream>
#include <sstream>
#include <regex>
#include <algorithm>
#include <vector>
#include <stdexcept>
#include "tlds.hpp"

const std::regex urlRegex(""
    "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?",
    std::regex_constants::icase);

const std::regex authorityRegex(""
    "(([a-z0-9\\-._~%!$&'()*+,;=:]+)@)?([a-z0-9\\-._~%]+|\\[[A-Z0-9\\-._~%!$&'()*+,;=:]+\\])(:([0-9]*))?",
    std::regex_constants::icase);

const std::regex ipv4Regex(""
    "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}"
    "(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$");

const std::regex ipv6Regex(""
    "^(?:(?:(?:[A-F0-9]{1,4}:){6}|(?=(?:[A-F0-9]{0,4}:){0,6}(?:[0-9]{1,3}"
    "\\.){3}[0-9]{1,3}$)(([0-9A-F]{1,4}:){0,5}|:)((:[0-9A-F]{1,4}){1,5}:|:)"
    "|::(?:[A-F0-9]{1,4}:){5})(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|"
    "[1-9]?[0-9])\\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])|"
    "(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}|(?=(?:[A-F0-9]{0,4}:){0,7}"
    "[A-F0-9]{0,4}$)(([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)|"
    "(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7})$",
    std::regex_constants::icase);

const std::regex sslRegex("^(http|ftp)s$", std::regex_constants::icase);

namespace cliqz {

    const std::string extractTLD(const std::string& host) {
        using namespace std;
        
        stringstream iss(host);
        vector<string> v;
        string item;
        while (getline(iss, item, '.')) {
            v.push_back(item);
        }
        // Empty host string
        if (v.size() == 0) {
            return "";
        }
        
        auto it = v.rbegin();
        auto tld = *(it++);
        auto firstLevel = TLDs[tld];
        if (v.size() > 2 && firstLevel == cc) {
            auto itFind = TLDs.find(*it);
            if (itFind != TLDs.end()) {
                tld = string(itFind->first).append(".").append(tld);
            }
        }
        return tld;
    }

    UrlDetails getDetailsFromUrl(const std::string& url) {
        using namespace std;
        
        smatch result;
        if (regex_match(url, result, urlRegex)) {
            const string proto = result.str(2);
            const string authority = result.str(4);
            const string path = result.str(5);
            const string query = result.str(7);
            const string fragment = result.str(9);
            const bool isSSL = regex_match(proto, sslRegex);
            
            string user = "";
            string host = authority;
            short port = isSSL ? 443 : 80;
            
            smatch authsplit;
            if (regex_match(authority, authsplit, authorityRegex)) {
                user = authsplit.str(2);
                host = authsplit.str(3);
                try {
                    port = stoi(authsplit.str(5));
                }catch (const invalid_argument& e) {
                    // Nothing to do here, the default is already there
                }
            }
            
            // lower case host
            transform(host.begin(), host.end(), host.begin(), ::tolower);
            
            const bool isIPv4 = regex_match(host, ipv4Regex);
            const bool isIPv6 =
                regex_match(++host.begin(), --host.end(), ipv6Regex);
            const bool isLocalHost = host.compare("localhost") == 0 ||
                (isIPv4 && host.find("127.") == 0) ||
                (isIPv6 && host.compare("::1") == 0);
            
            string tld;
            string name;
            if (!isIPv4 && !isIPv6 && !isLocalHost) {
                tld = extractTLD(host);
				const string fullDomainName = string(host, 0, host.size() - tld.size() - 1);
				size_t pos = 0;
				if ((pos = fullDomainName.find_last_of(".")) != std::string::npos) {
					name = fullDomainName.substr(pos + 1);
				} else {
					name = fullDomainName;
				}
            } else {
                name = isLocalHost ? "localhost" : "IP";
            }
            
            const auto cleanHost = host.find("www.") == 0 ?
                string(host, 4, host.size()) : host;
            
            auto extra = path;
            if (query.size() != 0) {
                extra.append("?").append(query);
            }
            if (fragment.size() != 0) {
                extra.append("#").append(fragment);
            }
            
            const auto friendlyUrl = string(cleanHost).append(extra);

			/*
            cout << "Protocol: " << proto << endl
                << "Authority: " << authority << endl
                << "User: " << user << endl
                << "Host: " << host << endl
                << "Port: " << port << endl
                << "Path: " << path << endl
                << "Query: " << query << endl
                << "Fragment: " << fragment << endl
                << "Is IPv4: " << isIPv4 << endl
                << "Is IPv6: " << isIPv6 << endl
                << "Is localhost: " << isLocalHost << endl
                << "TLD: " << tld << endl
                << "Name: " << name << endl
                << "Clean Host: " << cleanHost << endl
                << "Extra: " << extra << endl
                << "Friendly Url: " << friendlyUrl << endl << endl;
            */
            return (UrlDetails) {
                proto,      // scheme
                name,       // name
                host,       // domain
                tld,        // tld
                "",         // subdomains
                path,       // path
                query,      // query
                fragment,   // fragment
                extra,      // extra
                host,       // host
                cleanHost,  // cleanHost
                isSSL,      // ssl
                port,       // port
                friendlyUrl // friendly url
            };
        }
        throw invalid_argument("Not a valid URL");
    }
}
