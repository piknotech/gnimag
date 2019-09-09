# Tapping

Tapping, in contrast to [Image](../Image), defines protocols to execute taps and touches on a mobile device.

Games that are just played via a single tap (which is irrespective of the screen location) use a simple `Tapper`, which has the single capability to perform a tap somewhere (unspecified) on the screen. Games that require more complex actions would use respective protocols: `AnywhereTapper` for taps on specific screen locations, or `Finger` for full control like touch down, finger movement and touch up.
