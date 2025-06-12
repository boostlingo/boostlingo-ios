//
//  CustomFormDefaultValueProvider.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 01.08.2023.
//  Copyright © 2023 Boostlingo LLC. All rights reserved.
//

import Foundation
import BoostlingoSDK

struct CustomFieldDefaultValueProvider {
    
    func provideDefaultValue(for field: any CustomField) -> AnyHashable {
        switch field {
        case let field as EditTextCustomField:
            if FieldType.getFieldType(id: field.fieldTypeId) == .editTextSingleLine {
                return "Single line default text value"
            } else {
                return """
                    Multiline
                    default text value
                """
            }
        case let field as ListMultipleCustomField:
            guard let firstOption = field.options.first else {
                return [Int64]()
            }
            return [firstOption.id]
        case let field as CheckBoxCustomField:
            guard let firstOption = field.options.first else {
                return [Int64]()
            }
            return [firstOption.id]
        case let field as ListSingleCustomField:
            guard let firstOption = field.options.first else {
                return Int64(-1)
            }
            return firstOption.id
        case let field as RadioButtonCustomField:
            guard let firstOption = field.options.first else {
                return Int64(-1)
            }
            return firstOption.id
        default:
            return true
        }
    }
}

