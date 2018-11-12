import Foundation

extension sourcekitd_variant_t {
    var isArray: Bool {
        return SKApi.sourcekitd_variant_get_type(self) == SOURCEKITD_VARIANT_TYPE_ARRAY
    }

    func getInt( key: sourcekitd_uid_t ) -> Int {
        return Int(SKApi.sourcekitd_variant_dictionary_get_int64( self, key ))
    }

    func getString( key: sourcekitd_uid_t ) -> String? {
        let cstr = SKApi.sourcekitd_variant_dictionary_get_string( self, key )
        if cstr != nil {
            return String( cString: cstr! )
        }
        return nil
    }

    func getUUIDString( key: sourcekitd_uid_t ) -> String {
        let uuid = SKApi.sourcekitd_variant_dictionary_get_uid( self, key )
        return String( cString: SKApi.sourcekitd_uid_get_string_ptr( uuid! )! )// ?: "NOUUID"
    }

    func getDictionaryValue( key: sourcekitd_uid_t ) -> sourcekitd_variant_t {
        return SKApi.sourcekitd_variant_dictionary_get_value(self, key)
    }
    
    func getArrayValue( index: Int ) -> sourcekitd_variant_t {
        return SKApi.sourcekitd_variant_array_get_value(self, index)
    }
    
    func getArrayCount() -> Int {
        let count = sourcekitd_variant_array_get_count(self)
        return Int(count)
    }
}
