//
//  BitArray.swift
//  BuildBloomFilteriOS
//
//  Created by Tim Palade on 3/14/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import Foundation

final class BitArray: NSObject, NSCoding {
    
    //Array of bits manipulation
    typealias wordType = UInt64
    
    private var array: [wordType] = []
    
    init(count:Int) {
        super.init()
        self.array = self.buildArray(count: count)
    }
    
    public func valueOfBit(at index:Int) -> Bool{
        return self.valueOfBit(in: self.array, at: index)
    }
    
    public func setValueOfBit(value:Bool, at index: Int){
        self.setValueOfBit(in: &self.array, at: index, value: value)
    }
    
    public func count() -> Int{
        return self.array.count * intSize - 1
    }
    
    //Archieve/Unarchive
    
    func archived() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    class func unarchived(fromData data: Data) -> BitArray? {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? BitArray
    }
    
    //NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.array, forKey:"internalBitArray")
    }
    
    init?(coder aDecoder: NSCoder) {
        super.init()
        let array:[wordType] = aDecoder.decodeObject(forKey:"internalBitArray") as? [wordType] ?? []
        self.array = array
    }
    
    
    //Private API
    
    private func valueOfBit(in array:[wordType], at index:Int) -> Bool{
        checkIndexBound(index: index, lowerBound: 0, upperBound: array.count * intSize - 1)
        let (_arrayIndex, _bitIndex) = bitIndex(at:index)
        let bit = array[_arrayIndex]
        return valueOf(bit: bit, atIndex: _bitIndex)
    }
    
    private func setValueOfBit(in array: inout[wordType], at index:Int, value: Bool){
        checkIndexBound(index: index, lowerBound: 0, upperBound: array.count * intSize - 1)
        let (_arrayIndex, _bitIndex) = bitIndex(at:index)
        let bit = array[_arrayIndex]
        let newBit = setValueFor(bit: bit, value: value, atIndex: _bitIndex)
        array[_arrayIndex] = newBit
    }
    
    //Constants
    private let intSize = MemoryLayout<wordType>.size * 8
    
    //bit masks
    
    func invertedIndex(index:Int) -> Int{
        return intSize - 1 - index
    }
    
    func mask(index:Int) -> wordType {
        checkIndexBound(index: index, lowerBound: 0, upperBound: intSize - 1)
        return 1 << wordType(invertedIndex(index: index))
    }
    
    func negative(index:Int) -> wordType {
        checkIndexBound(index: index, lowerBound: 0, upperBound: intSize - 1)
        return ~(1 << wordType(invertedIndex(index: index)))
    }
    
    //return (arrayIndex for word containing the bit, bitIndex inside the word)
    private func bitIndex(at index:Int) -> (Int,Int){
        return(index / intSize, index % intSize)
    }
    
    private func buildArray(count:Int) -> [wordType] {
        //words contain intSize bits each
        let numWords = count/intSize + 1
        return Array.init(repeating: wordType(0), count: numWords)
    }
    
    //Bit manipulation
    private func valueOf(bit: wordType, atIndex index:Int) -> Bool {
        checkIndexBound(index: index, lowerBound: 0, upperBound: intSize - 1)
        return (bit & mask(index: index) != 0)
    }
    
    private func setValueFor(bit: wordType, value: Bool,atIndex index: Int) -> wordType{
        checkIndexBound(index: index, lowerBound: 0, upperBound: intSize - 1)
        if value {
            return (bit | mask(index: index))
        }
        return bit & negative(index: index)
    }
    
    //Util
    private func checkIndexBound(index:Int, lowerBound:Int, upperBound:Int){
        if(index < lowerBound || index > upperBound)
        {
            NSException.init(name: NSExceptionName(rawValue: "BitArray Exception"), reason: "index out of bounds", userInfo: nil).raise()
        }
    }
}
