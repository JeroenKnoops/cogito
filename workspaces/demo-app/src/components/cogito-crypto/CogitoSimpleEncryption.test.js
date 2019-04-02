import React from 'react'
import { render, fireEvent } from 'react-testing-library'
import { EncryptionActions } from 'encryption-state'
import { CogitoSimpleEncryptionView } from './CogitoSimpleEncryption'

describe('CogitoSimpleEncryptionView', () => {
  const telepathChannel = 'Some telepath Channel'
  let dispatch

  beforeEach(() => {
    dispatch = jest.fn()
  })

  it('puts the plain text and cipher text in correct fields', () => {
    const plainText = 'This is a plain text message'
    const cipherText = 'This is a cipher text message'

    const { queryByTestId } = render(
      <CogitoSimpleEncryptionView plainText={plainText} cipherText={cipherText} />
    )

    expect(queryByTestId('plain-text').value).toBe(plainText)
    expect(queryByTestId('cipher-text').value).toBe(cipherText)
  })

  it('does not show error box when there is no error', () => {
    const { queryByTestId } = render(
      <CogitoSimpleEncryptionView errorMessage={null} />
    )

    expect(queryByTestId('error-message')).toBeNull()
  })

  it('shows an error message', () => {
    const errorMessage = 'This is an error message'

    const { getByText } = render(
      <CogitoSimpleEncryptionView dispatch={dispatch} telepathChannel={telepathChannel} errorMessage={errorMessage} />
    )

    expect(getByText(errorMessage)).not.toBeNull()
  })

  describe('encryption', () => {
    let original

    beforeEach(() => {
      original = EncryptionActions.encrypt
      EncryptionActions.encrypt = jest.fn(
        ({ telepathChannel }) => ({ type: 'ENCRYPT', telepathChannel })
      )
    })

    afterEach(() => {
      EncryptionActions.encrypt = original
    })

    it('calls the encrypt action', () => {
      const { getByText } = render(
        <CogitoSimpleEncryptionView dispatch={dispatch} telepathChannel={telepathChannel} />
      )
      fireEvent.click(getByText('―Encrypt→'))

      expect(dispatch).toBeCalledWith(EncryptionActions.encrypt({ telepathChannel }))
    })
  })

  describe('decryption', () => {
    let original

    beforeEach(() => {
      original = EncryptionActions.decrypt
      EncryptionActions.decrypt = jest.fn(
        ({ telepathChannel }) => ({ type: 'DECRYPT', telepathChannel })
      )
    })

    afterEach(() => {
      EncryptionActions.decrypt = original
    })

    it('calls the decrypt action', () => {
      const { getByText } = render(
        <CogitoSimpleEncryptionView dispatch={dispatch} telepathChannel={telepathChannel} />
      )
      fireEvent.click(getByText('←Decrypt―'))

      expect(dispatch).toBeCalledWith(EncryptionActions.decrypt({ telepathChannel }))
    })
  })
})