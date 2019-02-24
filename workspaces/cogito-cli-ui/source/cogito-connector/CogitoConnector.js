import QRCode from 'qrcode'

class CogitoConnector {
  constructor ({ connectUrl }) {
    this.connectUrl = connectUrl
  }

  show () {
    return QRCode.toString(this.connectUrl, { type: 'terminal' }, function (error, output) {
      if (error) throw error
      return output
    })
  }
}

export { CogitoConnector }
