# gnimag-cli

_gnimag-cli_ is the target which produces the `gnimag` executable. In addition to providing a command-line interface, _gnimag-cli_ provides actual implementations for the interfaces that `Image` and `Tapping` are defining: _gnimag-cli_ contains components that interact with the Mac screen and with the mouse. For example, `WindowInteractor`s let _gnimag-cli_ read content from and perform taps on specific windows, like screen-sharing applications.
