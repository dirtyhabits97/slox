//
//  File.swift
//  
//
//  Created by user on 29/08/21.
//

import Foundation

struct Instance: CustomStringConvertible {

    private let klass: Class

    var description: String {
        "\(klass) instance "
    }

    init(klass: Class) {
        self.klass = klass
    }
}
