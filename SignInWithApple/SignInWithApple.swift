import AuthenticationServices

public protocol AppleSignInAuthenticationDelegate: class {
    func didCompleteAuthentication(token: Data)
    func didCompleteWith(error: Swift.Error)
}

public class AppleSignInController: NSObject {
    
    public typealias ControllerFactory = (_ requests: [ASAuthorizationRequest]) -> ASAuthorizationController
    
    private let factory: ControllerFactory
    private let delegate: AppleSignInAuthenticationDelegate
    
    private enum Error: Swift.Error {
        case invalidCredentials
    }
    
    public init(factory: @escaping ControllerFactory = ASAuthorizationController.init, delegate: AppleSignInAuthenticationDelegate) {
        self.factory = factory
        self.delegate = delegate
    }
    
    public func authenticate() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        let controller = factory([request])
        controller.delegate = self
        controller.performRequests()
    }
}

public protocol AppleIDCredential {
    var identityToken: Data? { get }
}

extension ASAuthorizationAppleIDCredential: AppleIDCredential {}

protocol Authorization {
    var credential: ASAuthorizationCredential { get }
}

extension AppleSignInController: ASAuthorizationControllerDelegate {
    
    public func completeWith(credential: AppleIDCredential) {
        guard let identityToken = credential.identityToken else {
            delegate.didCompleteWith(error: Error.invalidCredentials)
            return
        }
        delegate.didCompleteAuthentication(token: identityToken)
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credentials = authorization.credential as? AppleIDCredential else {
            return
        }
        completeWith(credential: credentials)
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Swift.Error) {
        delegate.didCompleteWith(error: error)
    }
}

