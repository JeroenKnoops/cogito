//  Copyright © 2017 Koninklijke Philips Nederland N.V. All rights reserved.

import ReSwift

func attestationsReducer(action: Action, state: AttestationsState?) -> AttestationsState {
    var state = state ?? initialAttestationsState
    switch action {
    case let action as AttestationActions.Pending:
        state.open[action.nonce] = AttestationInProgress(nonce: action.nonce,
                                                         subject: action.subject,
                                                         identity: action.identity,
                                                         status: .pending,
                                                         error: nil,
                                                         idToken: nil,
                                                         requestedOnChannel: action.requestedOnChannel)
    case let action as AttestationActions.Started:
        state.open[action.nonce]?.status = .started
    case let action as AttestationActions.StartRejected:
        state.open[action.nonce]?.status = .startRejected
        state.open[action.nonce]?.error = action.error
    case let action as AttestationActions.FinishRejected:
        if let nonce = action.nonce {
            state.open[nonce]?.status = .finishRejected
            state.open[nonce]?.error = action.error
        }
    case let action as AttestationActions.Fulfilled:
        state.open[action.nonce]?.status = .fulfilled
        state.open[action.nonce]?.idToken = action.idToken
    case let action as AttestationActions.Provided:
        var tokens = state.providedAttestations[action.channel] ?? [action.idToken]
        if tokens.index(of: action.idToken) == nil {
            tokens.append(action.idToken)
        }
        state.providedAttestations[action.channel] = tokens
    default:
        break
    }
    return state
}
