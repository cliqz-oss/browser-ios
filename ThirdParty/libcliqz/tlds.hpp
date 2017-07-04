//
//  tlds.hpp
//  libcliqz
//
//  Created by Stefano Pacifici on 09/05/17.
//  Copyright © 2017 Stefano Pacifici. All rights reserved.
//

#ifndef tlds_h
#define tlds_h

#include <map>
#include <string>

namespace cliqz {
    
    enum TLD_TYPE {
        cc = 0,
        na
    };
    
    extern std::map<std::string, TLD_TYPE> TLDs;
}

#endif /* tlds_h */
