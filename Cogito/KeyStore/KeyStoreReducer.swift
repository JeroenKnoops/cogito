//  Copyright © 2017 Koninklijke Philips Nederland N.V. All rights reserved.

import ReSwift

func keyStoreReducer(action: Action, state: KeyStoreState?) -> KeyStoreState {
    var state = state ?? initialKeyStoreState
    switch action {
    case let fulfilled as KeyStoreActions.Fulfilled:
        state.keyStore = fulfilled.keyStore
    default:
        break
    }
    return state
}
