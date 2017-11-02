## 0.0.1+2

- Allow package:build 0.11.0

## 0.0.1+1

- Fix a deadlock issue around the file descriptor pool, only take control of a
  resource right before actually touching disk instead of also encapsulating
  the `readAsBytes` call from the wrapped `AssetReader`.  

## 0.0.1

- Initial release, adds the `ScratchSpace` class.
