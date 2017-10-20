//
//  Domain.swift
//  Client
//
//  Created by Sahakyan on 10/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import Shared

open class Domain: Identifiable {

	open var id: Int?
	open var name: String?
	open var lastVisit: MicrosecondTimestamp?

	public init(id: Int?, name: String?, lastVisit: MicrosecondTimestamp?) {
		self.id = id
		self.name = name
		self.lastVisit = lastVisit
	}

}
