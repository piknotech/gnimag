# MacTestingTools

Just as the name would suggest, this library provides tools that are useful for testing and debugging while implementing a game or while implementing methods in ImageAnalysisKit. Because these methods are Mac-specific and tailored to the `Image` class from MacCLI, it is called MacTestingTools.

Just `import MacTestingTools` from either your game or from inside ImageAnalysisKit. Remember to remove these import statements and any testing code after you have finished debugging.

The features are:

- `BitmapCanvas` – a drawing area where you can draw onto existing `Image`s and save them to a file to visualize what's going on in your image analysis.
- `ImageListIO` – instead of using live input from a mobile device, you can record the screen contents once (with `ImageListCreator`) and then replay it (with `ImageListProvider`) to provide the same static stream of images. This is useful for image analysis as you can analyze the exact same image stream over and over again.
- `ScatterPlot` – this provides a simple method to draw a scatter plot with x/y data pairs and save it to a file. This means you can take a `Tracker` and plot its time/value pairs, allowing you to see the exact correlation between two variables.