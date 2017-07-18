//
//  CryptoBridge.h
//  Client
//
//  Created by Mahmoud Adam on 7/18/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#ifndef CryptoBridge_h
#define CryptoBridge_h

typedef int32_t CCCryptorStatus;
typedef struct _CCRSACryptor *CCRSACryptorRef;
CCCryptorStatus CCRSACryptorGeneratePair(size_t keysize, uint32_t e, CCRSACryptorRef *publicKey, CCRSACryptorRef *privateKey);
CCCryptorStatus CCRSACryptorExport(CCRSACryptorRef key, void *out, size_t *outLen);
void CCRSACryptorRelease(CCRSACryptorRef key);

#endif /* CryptoBridge_h */
