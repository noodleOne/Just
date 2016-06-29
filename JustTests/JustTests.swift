//
//  JustTests.swift
//  Just
//
//  Created by Daniel Duan on 6/17/16.
//  Copyright © 2016 JustHTTP. All rights reserved.
//

import XCTest
import Just

final class JustQueryStringTests: XCTestCase {
    func testDownloadingFileWithProgress() {
        var count = 0
        let expectation = self.expectation(withDescription: "download a large file")
        _ = Just.get("http://www.math.mcgill.ca/triples/Barr-Wells-ctcs.pdf", asyncProgressHandler:{ p in
            count += 1
        }) { _ in
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: 10) { error in
            if let _ = error {
                XCTFail("downloading error")
            } else {
                XCTAssert(count > 0)
            }
        }
    }

    func testSendSimpleQueryStringWithGet() {
        let r = Just.get("http://httpbin.org/get", params:["a": 1])
        XCTAssert(r.json != nil)
        if let jsonData = r.json as? [String:AnyObject] {
            XCTAssert(jsonData["args"] != nil)
            if let args = jsonData["args"] as? [String: String] {
                XCTAssertEqual(args, ["a":"1"])
            }
        }
    }

    func testSendCompoundQueryStringWithGet() {
        let r = Just.get("http://httpbin.org/get", params:["a":[1,2]])
        XCTAssert(r.json != nil)
        if let jsonData = r.json as? [String:AnyObject] {
            XCTAssert(jsonData["args"] != nil)
            if let args = jsonData["args"] as? [String: String] {
                XCTAssertEqual(args, ["a": ["1", "2"]])
            }
        }
    }

    func testSendSimpleQueryStringWithPost() {
        let r = Just.post("http://httpbin.org/post", params:["a": 1])
        XCTAssert(r.json != nil)
        if let jsonData = r.json as? [String:AnyObject] {
            XCTAssert(jsonData["args"] != nil)
            if let args = jsonData["args"] as? [String: String] {
                XCTAssertEqual(args, ["a":"1"])
            }
        }
    }

    func testSendCompoundQueryStringWithPost() {
        let r = Just.post("http://httpbin.org/post", params:["a":[1,2]])
        XCTAssertNotNil(r.json)
        if let jsonData = r.json as? [String:AnyObject] {
            XCTAssert(jsonData["args"] != nil)
            if let args = jsonData["args"] as? [String: String] {
                XCTAssertEqual(args, ["a": ["1", "2"]])
            }
        }
    }
}


final class JustSimpleRequestTests: XCTestCase {
    func testSimpleRequestWithDifferentMethods() {
        var r = Just.delete("http://httpbin.org/delete")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.request?.httpMethod, "DELETE")

        r = Just.get("http://httpbin.org/get")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.request?.httpMethod, "GET")

        r = Just.head("http://httpbin.org/get")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.request?.httpMethod, "HEAD")

        r = Just.options("http://httpbin.org")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.request?.httpMethod, "OPTIONS")

        r = Just.patch("http://httpbin.org/patch")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.request?.httpMethod, "PATCH")

        r = Just.post("http://httpbin.org/post")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.request?.httpMethod, "POST")

        r = Just.put("http://httpbin.org/put")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.request?.httpMethod, "PUT")
    }
}

final class JustSendURLQueryAsHTTPBody: XCTestCase {
    func testAddFormHeaderWhenBodyIsInURLFormat() {
        let r = Just.post("http://httpbin.org/post", data:["a": 1])
        XCTAssertNotNil(r.json)
        if let jsonData = r.json as? [String:AnyObject] {
            XCTAssertNotNil(jsonData["headers"])
            if let headers = jsonData["headers"] as? [String: String] {
                XCTAssertNotNil(headers["Content-Type"])
                if let contentType = headers["Content-Type"] {
                    XCTAssertEqual(contentType, "application/x-www-form-urlencoded")
                }
            }
        }
    }

    func testSendSimpleFormURLQueryByDemand() {
        let r = Just.post("http://httpbin.org/post", data: ["a": 1])
        XCTAssertNotNil(r.json)
        if let jsonData = r.json as? [String:AnyObject] {
            XCTAssertNotNil(jsonData["form"])
            if let form = jsonData["form"] as? [String:String] {
                XCTAssertEqual(form, ["a": "1"])
            }
        }
    }

    func testSendCompoundFormURLQueryByDemand() {
        let r = Just.post("http://httpbin.org/post", data: ["a": [1, 2]])
        XCTAssertNotNil(r.json)
        if let jsonData = r.json as? [String: AnyObject] {
            XCTAssertNotNil(jsonData["form"])
            if let form = jsonData["form"] as? [String: String] {
                XCTAssertEqual(form, ["a": ["1", "2"]])
            }
        }
    }
}

final class JustRedirections: XCTestCase {
    func testRedirectByDefault() {
        let r = Just.get("http://httpbin.org/redirect/2")
        XCTAssertNotEqual(r.statusCode, 302)
        XCTAssertEqual(r.statusCode, 200)
    }

    func testRedirectByDemand() {
        let r = Just.get("http://httpbin.org/redirect/2", allowRedirects: true)
        XCTAssertNotEqual(r.statusCode, 302)
        XCTAssertEqual(r.statusCode, 200)
        XCTAssertFalse(r.isRedirect)
        XCTAssertFalse(r.isPermanentRedirect)
    }

    func testNoRedirectByDemand() {
        let r = Just.get("http://httpbin.org/redirect/2", allowRedirects: false)
        XCTAssertNotEqual(r.statusCode, 200)
        XCTAssertEqual(r.statusCode, 302)
        XCTAssertTrue(r.isRedirect)
        XCTAssertFalse(r.isPermanentRedirect)
    }

    func testPermanantRedirect() {
        var r = Just.get("http://httpbin.org/status/302", allowRedirects:false)
        XCTAssertTrue(r.isRedirect)
        XCTAssertFalse(r.isPermanentRedirect)

        r = Just.get("http://httpbin.org/status/301", allowRedirects:false)
        XCTAssertTrue(r.isRedirect)
        XCTAssertTrue(r.isPermanentRedirect)
    }
}

final class JustSendingJSON: XCTestCase {
    func testNoJSONHeaderIfNoJSONIsSupplied() {
        let r = Just.post("http://httpbin.org/post", data:["A":"a"])
        XCTAssertNotNil(r.json)
        if let jsonData = r.json as? [String: AnyObject] {
            XCTAssertNotNil(jsonData["headers"])
            if let headers = jsonData["headers"] as? [String :String] {
                XCTAssertNotNil(headers["Content-Type"])
                if let contentType = headers["Content-Type"] {
                    XCTAssertNotEqual(contentType, "application/json")
                }
            }
        }
    }

    func testShouldAddJSONHeaderForEvenEmptyJSONArgument() {
        let r = Just.post("http://httpbin.org/post", json:[:])
        XCTAssertNotNil(r.json)
        if let jsonData = r.json as? [String: AnyObject] {
            XCTAssertNotNil(jsonData["headers"])
            if let headers = jsonData["headers"] as? [String :String] {
                XCTAssertNotNil(headers["Content-Type"])
                if let contentType = headers["Content-Type"] {
                    XCTAssertEqual(contentType, "application/json")
                }
            }
        }
    }

    func testSendingFlatJSONData() {
        let r = Just.post("http://httpbin.org/post", json:["a": 1])
        XCTAssertNotNil(r.json)
        if let data = r.json as? [String:AnyObject] {
            XCTAssertNotNil(data["json"])
            if let JSONInData = data["json"] as? [String: Int] {
                XCTAssertEqual(JSONInData, ["a": 1])
            }
        }
    }

    func testSendingNestedJSONData() {
        let r = Just.post("http://httpbin.org/post", json:["a": [1, "b"]])
        XCTAssertNotNil(r.json)
        if let data = r.json as? [String:AnyObject] {
            XCTAssertNotNil(data["json"])
            if let JSONInData = data["json"] as? [String: Int] {
                XCTAssertEqual(JSONInData, ["a": [1, "b"]])
            }
        }
    }

    func testJSONArgumentShouldOverrideDataArgument() {
        let r = Just.post("http://httpbin.org/post", data:["b":2], json:["a":1])
        XCTAssertNotNil(r.json)
        if let data = r.json as? [String: AnyObject] {
            XCTAssertNotNil(data["json"])
            if let JSONInData = data["json"] as? [String: Int] {
                XCTAssertEqual(JSONInData, ["a":1])
                XCTAssertNotEqual(JSONInData, ["b":2])
            }
            XCTAssertNotNil(data["data"])
            if let dataInData = data["data"] as? [String: Int] {
                XCTAssertEqual(dataInData, ["a": 1])
                XCTAssertNotEqual(dataInData, ["b": 2])
            }
            XCTAssertNotNil(data["headers"])
            if let headersInData = data["headers"] as? [String: String] {
                XCTAssertNotNil(headersInData["Content-Type"])
                if let contentType = headersInData["Content-Type"] {
                    XCTAssertEqual(contentType, "application/json")
                }
            }
        }
    }
}

final class JustSendingFiles: XCTestCase {
    func testNotIncludeMultipartHeaderForEmptyFiles() {
        let r = Just.post("http://httpbin.org/post", files:[:])
        XCTAssertNotNil(r.json)
        if let data = r.json as? [String: AnyObject] {
            XCTAssertNotNil(data["headers"])
            if let headersInData = data["headers"] as? [String: String] {
                if let contentType = headersInData["Content-Type"] {
                    XCTAssertFalse(contentType.hasPrefix("multipart/form-data; boundary="))
                }
            }
        }
    }

    func testSendingAFileSpecifiedByURLWithoutMimetype() {
        if let elonPhotoURL = Bundle(for: JustSendingFiles.self)
            .urlForResource("elon",  withExtension:"jpg")
        {
            let r = Just.post("http://httpbin.org/post", files:["elon":.url(elonPhotoURL,nil)])
            XCTAssertNotNil(r.json)
            if let data = r.json as? [String: AnyObject] {
                XCTAssertNotNil(data["files"])
                if let files = data["files"] as? [String: String] {
                    XCTAssertNotNil(files["elon"])
                }
            }
        } else {
            XCTFail("resource needed for this test can't be found")
        }
    }

    func testSendingAFileSpecifiedByURLWithMimetype() {
        if let elonPhotoURL = Bundle(for: JustSendingFiles.self)
            .urlForResource("elon",  withExtension:"jpg")
        {
            let r = Just.post("http://httpbin.org/post", files:["elon":.url(elonPhotoURL, "image/jpeg")])
            XCTAssertNotNil(r.json)
            if let data = r.json as? [String: AnyObject] {
                XCTAssertNotNil(data["files"])
                if let files = data["files"] as? [String: String] {
                    XCTAssertNotNil(files["elon"])
                }
            }
        } else {
            XCTFail("resource needed for this test can't be found")
        }
    }

    func testSendingAFileSpecifiedByDataWithoutMimetype() {
        if let dataToSend = "haha not really".data(using: String.Encoding.utf8) {
            let r = Just.post("http://httpbin.org/post",
                              files:["elon":.data("JustTests.swift", dataToSend, nil)])
            XCTAssertNotNil(r.json)
            if let data = r.json as? [String: AnyObject] {
                XCTAssertNotNil(data["files"])
                if let files = data["files"] as? [String:String] {
                    XCTAssertNotNil(files["elon"])
                }
            }
        } else {
            XCTFail("can't encode text as data")
        }
    }

    func testSendingAFileSpecifiedByDataWithMimetype() {
        if let dataToSend = "haha not really".data(using: String.Encoding.utf8) {
            let r = Just.post("http://httpbin.org/post",
                              files:["elon":.data("JustTests.swift", dataToSend, "text/plain")])
            XCTAssertNotNil(r.json)
            if let data = r.json as? [String: AnyObject] {
                XCTAssertNotNil(data["files"])
                if let files = data["files"] as? [String:String] {
                    XCTAssertNotNil(files["elon"])
                }
            }
        } else {
            XCTFail("can't encode text as data")
        }
    }

    func testSendAFileSpecifiedByTextWithoutMimetype() {
        let r = Just.post("http://httpbin.org/post",
                          files:["test":.text("JustTests.swift", "haha not really", nil)])
        XCTAssertNotNil(r.json)
        if let data = r.json as? [String: AnyObject] {
            XCTAssertNotNil(data["files"])
            if let files = data["files"] as? [String: String] {
                XCTAssertNotNil(files["test"])
            }
        }
    }

    func testSendAFileSpecifiedByTextWithMimetype() {
        let r = Just.post("http://httpbin.org/post",
                          files:["test":.text("JustTests.swift", "haha not really", "text/plain")])
        XCTAssertNotNil(r.json)
        if let data = r.json as? [String: AnyObject] {
            XCTAssertNotNil(data["files"])
            if let files = data["files"] as? [String: String] {
                XCTAssertNotNil(files["test"])
            }
        }
    }

    func testSendingMultipleFilesSpecifiedTheSameWay() {
        let r = Just.post(
            "http://httpbin.org/post",
            files:[
                "elon1": .text("JustTests.swift", "haha not really", nil),
                "elon2": .text("JustTests.swift", "haha not really", nil),
                "elon3": .text("JustTests.swift", "haha not really", nil),
                ]
        )
        XCTAssertNotNil(r.json)
        if let data = r.json as? [String: AnyObject] {
            XCTAssertNotNil(data["files"])
            if let files = data["files"] as? [String: String] {
                XCTAssertNotNil(files["elon1"])
                XCTAssertNotNil(files["elon2"])
                XCTAssertNotNil(files["elon3"])
            }
        }
    }

    func testSendingMultipleFilesSpecifiedInDifferentWays() {
        if let dataToSend = "haha not really".data(using: String.Encoding.utf8) {
            let r = Just.post(
                "http://httpbin.org/post",
                files: [
                    "elon1": .text("JustTests.swift", "haha not really", nil),
                    "elon2": .data("JustTests.swift", dataToSend, nil)
                ]
            )
            XCTAssertNotNil(r.json)
            if let data = r.json as? [String: AnyObject] {
                XCTAssertNotNil(data["files"])
                if let files = data["files"] as? [String: String] {
                    XCTAssertNotNil(files["elon1"])
                    XCTAssertNotNil(files["elon2"])
                }
            }
        } else {
            XCTFail("can't encode text as data")
        }
    }

    func testSendingAFileAlongWithSomeData() {
        let r = Just.post(
            "http://httpbin.org/post",
            data:["a":1, "b":2],
            files:["elon1": .text("JustTests.swift", "haha not really", nil)]
        )
        XCTAssertNotNil(r.json)
        if let data = r.json as? [String: AnyObject] {
            XCTAssertNotNil(data["files"])
            if let files = data["files"] as? [String: String] {
                XCTAssertNotNil(files["elon1"])
            }
            XCTAssertNotNil(data["form"])
            if let form = data["form"] as? [String: String] {
                XCTAssertEqual(form, ["a":"1", "b":"2"])
            }
        }
    }

    func testSendingMultipleFilesWithSomeData() {
        if let dataToSend = "haha not really".data(using: String.Encoding.utf8) {
            let r = Just.post(
                "http://httpbin.org/post",
                data:["a":1, "b":2],
                files: [
                    "elon1": .text("JustTests.swift", "haha not really", nil),
                    "elon2": .data("JustTests.swift", dataToSend, nil)
                ]
            )
            XCTAssertNotNil(r.json)
            if let data = r.json as? [String: AnyObject] {
                XCTAssertNotNil(data["files"])
                if let files = data["files"] as? [String: String] {
                    XCTAssertNotNil(files["elon1"])
                    XCTAssertNotNil(files["elon2"])
                }
                XCTAssertNotNil(data["form"])
                if let form = data["form"] as? [String: String] {
                    XCTAssertEqual(form, ["a":"1", "b":"2"])
                }
            }
        } else {
            XCTFail("can't encode text as data")
        }
    }

    func testSendingFilesOveridesJSON() {
        if let dataToSend = "haha not really".data(using: String.Encoding.utf8) {
            let r = Just.post(
                "http://httpbin.org/post",
                json:["a": 1, "b": 2],
                files: [
                    "elon1": .text("JustTests.swift", "haha not really", nil),
                    "elon2": .data("JustTests.swift", dataToSend, nil)
                ]
            )
            XCTAssertNotNil(r.json)
            if let data = r.json as? [String: AnyObject] {
                XCTAssertNotNil(data["json"])
                XCTAssertTrue(data["json"] is NSNull)

                XCTAssertNotNil(data["files"])
                if let files = data["files"] as? [String: String] {
                    XCTAssertNotNil(files["elon1"])
                    XCTAssertNotNil(files["elon2"])
                }
                XCTAssertNotNil(data["form"])
                if let form = data["form"] as? [String:String] {
                    XCTAssertEqual(form, [:])
                }
            }
        } else {
            XCTFail("can't encode text as data")
        }
    }
}

final class Result: XCTestCase {
    func testResultShouldContainURLFromResponse() {
        let targetURLString = "http://httpbin.org/get"
        let r = Just.get(targetURLString)
        XCTAssertNotNil(r.url)
        if let urlString = r.url?.absoluteString {
            XCTAssertEqual(urlString, targetURLString)
        }
    }

    func testOkayWithNonErrorStatusCode() {
      XCTAssertTrue(Just.get("http://httpbin.org/status/200").ok)
      XCTAssertTrue(Just.get("http://httpbin.org/status/299").ok)
      XCTAssertTrue(Just.get("http://httpbin.org/status/302", allowRedirects:false).ok)
    }

    func testNotOkayWith4xxCodes() {
      XCTAssertFalse(Just.get("http://httpbin.org/status/400").ok)
      XCTAssertFalse(Just.get("http://httpbin.org/status/401").ok)
      XCTAssertFalse(Just.get("http://httpbin.org/status/404").ok)
      XCTAssertFalse(Just.get("http://httpbin.org/status/499").ok)
    }

    func testNotOkayWith5xxCodes() {
      XCTAssertFalse(Just.get("http://httpbin.org/status/500").ok)
      XCTAssertFalse(Just.get("http://httpbin.org/status/501").ok)
      XCTAssertFalse(Just.get("http://httpbin.org/status/599").ok)
    }

    func testStatusCodeMatching() {
      XCTAssertEqual(Just.get("http://httpbin.org/status/200").statusCode, 200)
      XCTAssertEqual(Just.get("http://httpbin.org/status/302", allowRedirects:false).statusCode, 302)
      XCTAssertEqual(Just.get("http://httpbin.org/status/404").statusCode, 404)
      XCTAssertEqual(Just.get("http://httpbin.org/status/501").statusCode, 501)
    }
}

final class SendingHeader: XCTestCase {
  func testAcceptingEmptyHeaders() {
    XCTAssertTrue(Just.get("http://httpbin.org/get", headers:[:]).ok)
  }

  func testSendingSingleConventionalHeaderAsProvided() {
    let r = Just.get("http://httpbin.org/get", headers:["Content-Type":"application/json"])
    XCTAssertNotNil(r.json)
    if let responseData = r.json as? [String: AnyObject] {
      XCTAssertNotNil(responseData["headers"])
      if let receivedHeaders = responseData["headers"] as? [String:String] {
        XCTAssertEqual(receivedHeaders["Content-Type"], "application/json")
      }
    }
  }

  func testSendingMultipleConventionalHeaderAsProvided() {
    let r = Just.get("http://httpbin.org/get",
                     headers:["Accept-Language":"*", "Content-Type":"application/json"])
    XCTAssertNotNil(r.json)
    if let responseData = r.json as? [String: AnyObject] {
      XCTAssertNotNil(responseData["headers"])
      if let receivedHeaders = responseData["headers"] as? [String:String] {
        XCTAssertEqual(receivedHeaders["Content-Type"], "application/json")
        XCTAssertEqual(receivedHeaders["Accept-Language"], "*")
      }
    }
  }

  func testSendingMultipleUnconventionalHeaderAsProvided() {
    let r = Just.get("http://httpbin.org/get",
                     headers:["Winter-is":"coming", "things-know-by-Jon-Snow":"Just42awesome"])
    XCTAssertNotNil(r.json)
    if let responseData = r.json as? [String: AnyObject] {
      XCTAssertNotNil(responseData["headers"])
      if let receivedHeaders = responseData["headers"] as? [String:String] {
        XCTAssertEqual(receivedHeaders["Winter-Is"], "coming")
        XCTAssertEqual(receivedHeaders["Things-Know-By-Jon-Snow"], "Just42awesome")
      }
    }
  }
}

final class BasicAuthentication: XCTestCase {
  func testFailingAtAChallengeWhenAuthIsMissing() {
    let r = Just.get("http://httpbin.org/basic-auth/dan/pass")
    XCTAssertFalse(r.ok)
  }

  func testSucceedingWithCorrectAuthInfo() {
    let username = "dan"
    let password = "password"
    let r = Just.get("http://httpbin.org/basic-auth/\(username)/\(password)", auth:(username, password))
    XCTAssertTrue(r.ok)
  }

  func testFailingWithWrongAuthInfo() {
    let username = "dan"
    let password = "password"
    let r = Just.get("http://httpbin.org/basic-auth/\(username)/\(password)x", auth:(username, password))
    XCTAssertFalse(r.ok)
    XCTAssertEqual(r.statusCode, 401)
  }
}

class DigestAuthentication: XCTestCase {
  func testFailingAtAChallengeWhenAuthIsMissing() {
    let r = Just.get("http://httpbin.org/digest-auth/auth/dan/pass")
    XCTAssertFalse(r.ok)
  }

  func testSucceedingWithCorrectAuthInfo() {
    let username = "dan"
    let password = "password"
    let r = Just.get("http://httpbin.org/digest-auth/auth/\(username)/\(password)",
                     auth: (username, password))
    XCTAssertTrue(r.ok)
  }

  func testFailingWithWrongAuthInfo() {
    let username = "dan"
    let password = "password"
    let r = Just.get("http://httpbin.org/digest-auth/auth/\(username)/\(password)x",
                     auth: (username, password))
    XCTAssertFalse(r.ok)
    XCTAssertEqual(r.statusCode, 401)
  }
}

final class Cookies: XCTestCase {
  func testCookiesFromResponse() {
    let r = Just.get("http://httpbin.org/cookies/set/test/just", allowRedirects:false)
    XCTAssertFalse(r.cookies.isEmpty)
    XCTAssertTrue(Array(r.cookies.keys).contains("test"))
    if let cookie = r.cookies["test"] {
      XCTAssertEqual(cookie.value, "just")
    }
  }

  func testCookiesSpecifiedInRequest() {
    _ = Just.get("http://httpbin.org/cookies/delete?test")
    let r = Just.get("http://httpbin.org/cookies", cookies:["test":"just"])

    XCTAssertNotNil(r.json)
    if let jsonData = r.json as? [String: AnyObject] {
      XCTAssertNotNil(jsonData["cookies"] as? [String:String])
      if let cookieValue = (jsonData["cookies"] as? [String:String])?["test"] {
        XCTAssertEqual(cookieValue, "just")
      }
    }
  }
}

final class RequestMethods: XCTestCase {
  func testOPTIONS() {
    XCTAssertTrue(Just.options("http://httpbin.org/get").ok)
  }

  func testHEAD() {
    XCTAssertTrue(Just.head("http://httpbin.org/get").ok)
  }

  func testGET() {
    XCTAssertTrue(Just.get("http://httpbin.org/get").ok)
  }

  func testPOST() {
    XCTAssertTrue(Just.post("http://httpbin.org/post").ok)
  }

  func testPUT() {
    XCTAssertTrue(Just.put("http://httpbin.org/put").ok)
  }

  func testPATCH() {
    XCTAssertTrue(Just.patch("http://httpbin.org/patch").ok)
  }

  func testDELETE() {
    XCTAssertTrue(Just.delete("http://httpbin.org/delete").ok)
  }
}

final class Timeout: XCTestCase {
  func testTimeoutWhenRequestTakesLonger() {
    XCTAssertFalse(Just.get("http://httpbin.org/delay/10", timeout:0.2).ok)
  }

  func testShouldNotTimeoutWhenResponseComesInSooner() {
    XCTAssertTrue(Just.get("http://httpbin.org/", timeout:2).ok)
  }
}


final class LinkHeader: XCTestCase {
  func testShouldContainLinkInfoForAppropriateEndPoint() {
    var auth: (String, String)? = nil
    if let username = ProcessInfo.processInfo().environment["GITHUB_USERNAME"],
        token = ProcessInfo.processInfo().environment["GITHUB_TOKEN"]
    {
        auth = (username, token)
    }
    let r = Just.get("https://api.github.com/users/dduan/repos?page=1&per_page=10", auth: auth)
    XCTAssertTrue(r.ok)
    XCTAssertNotNil(r.links)
    XCTAssertNotNil(r.links["next"])
    XCTAssertNotNil(r.links["last"])
    XCTAssertNotNil(r.links["next"]?["url"])
    XCTAssertNotNil(r.links["last"]?["url"])
  }
}


final class Configurations: XCTestCase {
  func testSendingDefaultHeadersWhenAnyIsSpecified() {
    let sessionDefaults = JustSessionDefaults(headers: ["Authorization": "WUT"])
    let session = JustOf<HTTP>(defaults: sessionDefaults)
    let r = session.post("http://httpbin.org/post")
    XCTAssertTrue(r.ok)
    XCTAssertNotNil(r.json)
    if let data = r.json as? [String: AnyObject] {
      XCTAssertNotNil(data["headers"])
      if let headersInData = data["headers"] as? [String: String] {
        XCTAssertNotNil(headersInData["Authorization"])
        if let authorization = headersInData["Authorization"] {
          XCTAssertEqual(authorization, "WUT")
        }
      }
    }
  }
}
