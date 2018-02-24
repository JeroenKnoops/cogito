"use strict";

require("regenerator-runtime/runtime");

require("core-js/modules/es6.promise");

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function step(key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } } function _next(value) { step("next", value); } function _throw(err) { step("throw", err); } _next(); }); }; }

function delay(_x) {
  return _delay.apply(this, arguments);
}

function _delay() {
  _delay = _asyncToGenerator(
  /*#__PURE__*/
  regeneratorRuntime.mark(function _callee(milliseconds) {
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            return _context.abrupt("return", new Promise(function (resolve) {
              setTimeout(function () {
                return resolve();
              }, milliseconds);
            }));

          case 1:
          case "end":
            return _context.stop();
        }
      }
    }, _callee, this);
  }));
  return _delay.apply(this, arguments);
}

module.exports = delay;