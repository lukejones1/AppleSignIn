import XCTest
import AuthenticationServices
import SignInWithApple

class AppleSingInTests: XCTestCase {

    func test_init_doesNotPerformRequests() {
        let (_, controller, _) = makeSUT()
        XCTAssertEqual(controller.performRequestsCallCount, 0)
    }

    func test_authenticate_performsRequestOnce() {
        let (sut, controller, _) = makeSUT()
        sut.authenticate()
        XCTAssertEqual(controller.performRequestsCallCount, 1)
    }
    
    func test_authenticate_receivedRequests() {
        let (sut, controler, _) = makeSUT()
        sut.authenticate()
        XCTAssertEqual(controler.requests.count, 1)
        XCTAssertTrue(controler.requests.first is ASAuthorizationAppleIDRequest)
        XCTAssertEqual((controler.requests.first as? ASAuthorizationAppleIDRequest)?.requestedScopes,  [.email, .fullName])
    }
    
    func test_authenticate_setsDelegate() {
        let (sut, controller, _) = makeSUT()
        sut.authenticate()
        XCTAssertTrue(controller.delegate === sut)
    }
    
    func test_didCompleteWithError_firesDelegateMethodWithError() {
        let (sut, controller, delegate) = makeSUT()
        let anyError = NSError(domain: "", code: 0, userInfo: nil)
        
        sut.authorizationController(controller: controller, didCompleteWithError: anyError)
        
        XCTAssertEqual(delegate.messages, [.error])
    }
    
    func test_completeWithCredential_withInvalidToken_firesDelegateMethodWithInvalidCredentialsError() {
        let (sut, _, delegate) = makeSUT()
        
        sut.completeWith(credential: Credential(identityToken: nil))

        XCTAssertEqual(delegate.messages, [.error])
    }
    
    func test_completeWithCredential_withValidToken_firesDelegateMethodWithToken() {
        let (sut, _, delegate) = makeSUT()

        let token = Data("any token".utf8)
        sut.completeWith(credential: Credential(identityToken: token))
        
        XCTAssertEqual(delegate.messages, [.authentication(token)])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (AppleSignInController, ASAuthorizationController.Spy, AppleSignInAuthenticationDelegateSpy) {
        let controller = ASAuthorizationController.spy
        let delegate = AppleSignInAuthenticationDelegateSpy()
        
        let sut = AppleSignInController(factory: { requests in
            controller.requests.append(contentsOf: requests)
            return controller
        },
        delegate: delegate)
        trackForMemoryLeaks(controller, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(delegate, file: file, line: line)
        return (sut, controller, delegate)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, file: file, line: line)
        }
    }
}

extension ASAuthorizationController {
    
    static var spy: Spy {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        return Spy(authorizationRequests: [request])
    }
    
    class Spy: ASAuthorizationController {
        
        var performRequestsCallCount = 0
        var requests: [ASAuthorizationRequest] = []
        
        override func performRequests() {
            performRequestsCallCount += 1
        }
    }
}

class AppleSignInAuthenticationDelegateSpy: AppleSignInAuthenticationDelegate {
    
    enum Message: Equatable {
        case error, authentication(Data)
    }
    
    var messages: [Message] = []

    func didCompleteAuthentication(token: Data) {
        messages.append(.authentication(token))
    }

    func didCompleteWith(error: Swift.Error) {
        messages.append(.error)
    }
}

private struct Credential: AppleIDCredential {
    let identityToken: Data?
}
