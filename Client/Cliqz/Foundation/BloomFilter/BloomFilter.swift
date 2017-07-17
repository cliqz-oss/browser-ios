//
//  BloomFilter.swift
//  BloomFilteriOS
//
//  Created by Tim Palade on 3/13/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

//If there is a problem with the SipHash, tyou can use a SipHash written in C. 

import Foundation

public class BloomFilter: NSObject, NSCoding{
    
    private var array: BitArray
    private var hashFunctions: [(String) -> Int] = []
    private var k : Int = 0 //number of hashfunctions
    
    func sipHasher(string: String, append: Int) -> Int {
        var siphasher = SipHasher(k0: 1200, k1: 1000)
        siphasher.append(string)
        siphasher.append(append)
        return siphasher.finalize()
    }
    
    func hashes(k :Int) -> [(String)->Int] {
        var arrayOfHashFunctions:[(String)->Int] = []
        for i in 0..<k {
            let clojure = {(string:String) in
                self.sipHasher(string: string, append: i*3)
            }
            arrayOfHashFunctions.append(clojure)
        }
        return arrayOfHashFunctions
    }
    
    public init(n: Int, p: Double) {
        
        let sqLog2: Double = (log(2) * log(2))
        
        let _m :Double = -1.0 * Double(n) * log(p) / sqLog2;
        let _k :Double = _m / Double(n) * log(2);
        
        let m = Int(ceil(_m))
        k = Int(ceil(_k))
        
        array = BitArray(count: m)
        
        super.init()
        self.hashFunctions = self.hashes(k: k)
    }
    
    private func computeHashes(_ value: String) -> [Int] {
        return hashFunctions.map() { hashFunc in abs(hashFunc(value) % array.count()) }
    }
    
    public func add(_ element: String) {
        for hashValue in computeHashes(element) {
            //array[hashValue] = true
            array.setValueOfBit(value: true, at: hashValue)
        }
    }
    
    public func insert(_ values: [String]) {
        for value in values {
            add(value)
        }
    }
    
    public func query(_ value: String) -> Bool {
        let hashValues = computeHashes(value)
        
        // Map hashes to indices in the Bloom Filter
        //let results = hashValues.map() { hashValue in array[hashValue] }
        let results = hashValues.map() { hashValue in array.valueOfBit(at: hashValue)}
        
        // All values must be 'true' for the query to return true
        // This does NOT imply that the value is in the Bloom filter,
        // only that it may be. If the query returns false, however,
        // you can be certain that the value was not added.
        let exists = results.reduce(true, { $0 && $1 })
        return exists
    }
    
    //    public func isEmpty() -> Bool {
    //        // As soon as the reduction hits a 'true' value, the && condition will fail.
    //        return array.reduce(true) { prev, next in prev && !next }
    //    }
    
    // MARK: - Archiving / Unarchiving
    
    func archived() -> Data {
        NSKeyedArchiver.setClassName("internalArray", for: BitArray.self)
        NSKeyedArchiver.setClassName("BloomFilter", for: BloomFilter.self)
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    class func unarchived(fromData data: Data) -> BloomFilter? {
        NSKeyedUnarchiver.setClass(BitArray.self, forClassName: "internalArray")
        NSKeyedUnarchiver.setClass(BloomFilter.self, forClassName: "BloomFilter")
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? BloomFilter
    }
    
    // MARK: - <NSCoding>
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.array, forKey: "internalArray")
        aCoder.encode(self.k, forKey: "numberOfHashFunctions")
        debugPrint("It was encoded.")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        array = aDecoder.decodeObject(forKey: "internalArray") as? BitArray ?? BitArray(count: 0)
        
        super.init()
        self.k     = aDecoder.decodeInteger(forKey: "numberOfHashFunctions")
        self.hashFunctions = self.hashes(k: self.k)
        debugPrint("It was decoded.")
    }
    
}
