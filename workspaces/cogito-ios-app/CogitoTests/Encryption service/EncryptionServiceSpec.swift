import Quick
import Nimble
import SwiftyJSON
@testable import Cogito

class EncryptionServiceSpec: QuickSpec {
    override func spec() {
        var service: EncryptionService!
        var store: RecordingStore!
        var channel: TelepathChannel!
        var identity: Identity!
        var keyPairCreator: KeyPairCreatorSpy!
        var publicKeyLoader: PublicKeyLoaderSpy!
        var decrypter: DecrypterSpy!

        beforeEach {
            store = RecordingStore()
            service = EncryptionService(store: store)
            channel = TelepathChannelSpy()
            identity = Identity.example
            keyPairCreator = KeyPairCreatorSpy()
            publicKeyLoader = PublicKeyLoaderSpy()
            decrypter = DecrypterSpy()
            service.publicKeyLoader = publicKeyLoader
            service.keyPairCreator = keyPairCreator
            service.decrypter = decrypter
        }

        context("when a create encryption key pair request comes in") {
            let request = JsonRpcRequest(method: "createEncryptionKeyPair")

            beforeEach {
                store.state = appState(
                    diamond: DiamondState(facets: [identity]),
                    telepath: TelepathState(channels: [channel: identity.identifier])
                )
                service.onRequest(request, on: channel)
            }

            it("creates an new key pair in keychain") {
                expect(keyPairCreator.createWasCalled).to(beTrue())
            }

            it("generates unique ids") {
                service.onRequest(request, on: channel)
                let tag1 = keyPairCreator.latestTag
                service.onRequest(request, on: channel)
                let tag2 = keyPairCreator.latestTag
                expect(tag1) != tag2
            }

            it("dispatches StoreEncryptionKeyPair action") {
                let action = store.firstAction(ofType: DiamondActions.StoreEncryptionKeyPair.self)
                expect(action).toNot(beNil())
            }

            it("uses the identity that is associated with the channel") {
                let action = store.firstAction(ofType: DiamondActions.StoreEncryptionKeyPair.self)
                expect(action?.identity) == identity
            }

            it("sends response on Telepath channel") {
                let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                expect(sendPendingAction?.message).to(contain(keyPairCreator.latestTag!))
            }
        }

        context("when a public key is requested") {
            let tag = "1234-5678"
            let publicKey = JSON(["some": "public key"])

            context("when the public key is available") {
                beforeEach {
                    identity.encryptionKeyPairs = [tag]
                    store.state = appState(
                        diamond: DiamondState(facets: [identity]),
                        telepath: TelepathState(channels: [channel: identity.identifier])
                    )
                    publicKeyLoader.jsonWebKeyToReturn = publicKey
                }

                it("loads the public key with the correct tag") {
                    let request = JsonRpcRequest(
                        method: "getEncryptionPublicKey",
                        params: JsonRpcParams(["tag": tag])
                    )
                    service.onRequest(request, on: channel)
                    expect(publicKeyLoader.latestTag).to(equal(tag))
                }

                it("sends response on Telepath channel") {
                    let request = JsonRpcRequest(
                        method: "getEncryptionPublicKey",
                        params: JsonRpcParams(["tag": tag])
                    )
                    service.onRequest(request, on: channel)
                    let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                    expect(sendPendingAction?.message).to(contain("\"some\" : \"public key\""))
                }

                it("sends an error when tag is missing in request") {
                    let request = JsonRpcRequest(method: "getEncryptionPublicKey")
                    service.onRequest(request, on: channel)
                    let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                    expect(sendPendingAction?.message).to(contain("\"code\" : \(EncryptionError.tagMissing.rawValue)"))
                }
            }

            context("when the public key is not available") {
                beforeEach {
                    identity.encryptionKeyPairs = [tag]
                    store.state = appState(
                        diamond: DiamondState(facets: [identity]),
                        telepath: TelepathState(channels: [channel: identity.identifier])
                    )
                }

                it("returns an error") {
                    let request = JsonRpcRequest(
                        method: "getEncryptionPublicKey",
                        params: JsonRpcParams(["tag": tag])
                    )
                    service.onRequest(request, on: channel)
                    let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                    expect(sendPendingAction?.message).to(contain("\"code\" : \(EncryptionError.keyNotFound.rawValue)"))
                }
            }

            context("when the identity does not contain the key pair") {
                beforeEach {
                    identity.encryptionKeyPairs = []
                    store.state = appState(
                        diamond: DiamondState(facets: [identity]),
                        telepath: TelepathState(channels: [channel: identity.identifier])
                    )
                    publicKeyLoader.jsonWebKeyToReturn = publicKey
                }

                it("returns an error") {
                    let request = JsonRpcRequest(
                        method: "getEncryptionPublicKey",
                        params: JsonRpcParams(["tag": tag])
                    )
                    service.onRequest(request, on: channel)
                    let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                    expect(sendPendingAction?.message).to(contain("\"code\" : \(EncryptionError.keyNotFound.rawValue)"))
                }
            }
        }

        context("when decryption is requested") {
            let tag = "1234-5678"
            let cipherText = "some encrypted data".data(using: .utf8)!
            let plainText = "some decrypted data".data(using: .utf8)!
            let request = JsonRpcRequest(
                method: "decrypt",
                params: JsonRpcParams([
                    "tag": tag,
                    "cipherText": cipherText.hexEncodedString()
                ])
            )

            beforeEach {
                identity.encryptionKeyPairs = [tag]
                store.state = appState(
                    diamond: DiamondState(facets: [identity]),
                    telepath: TelepathState(channels: [channel: identity.identifier])
                )
                decrypter.plainTextToReturn = plainText
            }

            it("decrypts the data") {
                service.onRequest(request, on: channel)
                expect(decrypter.latestKeyTag) == tag
                expect(decrypter.latestCipherText) == cipherText
            }

            it("sends response on telepath channel") {
                service.onRequest(request, on: channel)
                let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                expect(sendPendingAction?.message).to(contain(plainText.hexEncodedString()))
            }

            it("sends an error when tag is missing in the request") {
                let wrongRequest = JsonRpcRequest(
                    method: "decrypt",
                    params: JsonRpcParams([
                        "cipherText": cipherText.hexEncodedString()
                    ])
                )
                service.onRequest(wrongRequest, on: channel)
                let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                let expectedError = EncryptionError.tagMissing
                expect(sendPendingAction?.message).to(contain("\"code\" : \(expectedError.rawValue)"))

            }

            it("sends an error when cipherText is missing in the request") {
                let wrongRequest = JsonRpcRequest(
                    method: "decrypt",
                    params: JsonRpcParams([
                        "tag": tag
                    ])
                )
                service.onRequest(wrongRequest, on: channel)
                let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                let expectedError = EncryptionError.cipherTextMissing
                expect(sendPendingAction?.message).to(contain("\"code\" : \(expectedError.rawValue)"))

            }

            it("sends an error when cipherText is invalid") {
                let wrongRequest = JsonRpcRequest(
                    method: "decrypt",
                    params: JsonRpcParams([
                        "tag": tag,
                        "cipherText": "invalid hex string"
                    ])
                )
                service.onRequest(wrongRequest, on: channel)
                let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                let expectedError = EncryptionError.cipherTextInvalid
                expect(sendPendingAction?.message).to(contain("\"code\" : \(expectedError.rawValue)"))

            }

            it("sends an error when decryption fails") {
                decrypter.plainTextToReturn = nil
                service.onRequest(request, on: channel)
                let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                let expectedError = EncryptionError.decryptionFailed
                expect(sendPendingAction?.message).to(contain("\"code\" : \(expectedError.rawValue)"))
            }

            it("sends an error when the identity does not contain the key") {
                identity.encryptionKeyPairs = []
                store.state = appState(
                    diamond: DiamondState(facets: [identity]),
                    telepath: TelepathState(channels: [channel: identity.identifier])
                )
                service.onRequest(request, on: channel)
                let sendPendingAction = store.firstAction(ofType: TelepathActions.SendPending.self)
                let expectedError = EncryptionError.decryptionFailed
                expect(sendPendingAction?.message).to(contain("\"code\" : \(expectedError.rawValue)"))
            }
        }

        context("when another request comes in") {
            it("does not dispatch anything") {
                let actionCountBefore = store.actions.count
                let request = JsonRpcRequest(method: "other")
                service.onRequest(request, on: channel)
                expect(store.actions.count) == actionCountBefore
            }
        }
    }
}
