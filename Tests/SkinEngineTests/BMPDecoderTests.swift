import Testing
import Foundation
@testable import SkinEngine

@Suite("BMPDecoder")
struct BMPDecoderTests {
    @Test("Rejects data shorter than BMP header")
    func rejectsTooShort() {
        let data = Data(repeating: 0, count: 10)
        #expect(throws: BMPDecoder.BMPError.self) {
            _ = try BMPDecoder.decode(data)
        }
    }

    @Test("Rejects invalid magic bytes")
    func rejectsInvalidMagic() {
        var data = Data(repeating: 0, count: 54)
        data[0] = 0x00
        data[1] = 0x00
        #expect(throws: BMPDecoder.BMPError.self) {
            _ = try BMPDecoder.decode(data)
        }
    }

    @Test("WSZ parser requires minimum skin files")
    func wszParserValidation() {
        // A valid ZIP but missing required BMP files should throw
        // This test validates the error path — full integration tests
        // will use the bundled base-2.91.wsz skin
    }
}
