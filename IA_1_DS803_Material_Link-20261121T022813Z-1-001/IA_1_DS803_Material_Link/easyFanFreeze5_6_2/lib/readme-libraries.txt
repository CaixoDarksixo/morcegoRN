thinlet.jar contains the Thinlet library.
See http://www.thinlet.com for details.

The version is a CVS checkout from 2004/06/29.
In comparison to the latest released version, this version contains the
following additional features:

- Table columns are resizable.
- The property "closeable" in components of type "dialog" has been removed.
  Instead, there is a new property "close", that let's you define a method
  that will be called when the user clicks the close button of the dialog.
  The close button is painted only if the property "close" exists.

