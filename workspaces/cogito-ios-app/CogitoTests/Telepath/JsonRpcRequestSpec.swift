//  Copyright © 2018 Koninklijke Philips Nederland N.V. All rights reserved.

import Quick
import Nimble

class JsonRpcRequestSpec: QuickSpec {
    override func spec() {
        let json = "{" +
            "\"jsonrpc\":\"2.0\"," +
            "\"id\":42," +
            "\"method\":\"test\"," +
            "\"params\":{" +
                "\"a\": 1," +
                "\"b\": 2" +
            "}" +
        "}"

        it("parses the method") {
            let request = JsonRpcRequest(parse: json)
            expect(request?.method) == "test"
        }

        it("parses an id") {
            let request = JsonRpcRequest(parse: json)
            expect(request?.id.int) == 42
        }

        it("parses parameters") {
            let request = JsonRpcRequest(parse: json)
            expect(request?.params["a"].number) == 1
            expect(request?.params["b"].number) == 2
        }
    }
}