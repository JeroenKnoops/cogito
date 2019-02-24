import { CogitoConnector } from './CogitoConnector'

describe('CogitoConnector', () => {
  describe('when constructed with a small argument', () => {
    const cogitoConnector = new CogitoConnector({ connectUrl: 'blurk' })

    it('has connectUrl', () => {
      expect(cogitoConnector.connectUrl).toBeDefined()
    })

    it('returns small qrcode', () => {
      expect(cogitoConnector.show()).toHaveLength(5842)
    })
  })

  describe('when constructed with a large argument', () => {
    const cogitoConnector = new CogitoConnector({ connectUrl: 'blusdflksajdflklk fsld fsdsjdflkasdlf asdl kjsda lkasjdfrk' })
    it('returns large qrcode', () => {
      expect(cogitoConnector.show()).toHaveLength(13510)
    })
  })
})
