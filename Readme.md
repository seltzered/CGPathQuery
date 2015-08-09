## CGPathQuery

CGPathQuery is used for calculating points along a CGPath. This is intended for composing points along the path as part of a more complex graphic (such as a ShapeLayer).

It works by using core animation itself to pre-calculate values along a given range, then can be 'queried' later. Specifically, it makes use of immediately calculating a collection of points by making the animation.speed zero then reading the presentationLayer's position upon completion. If a value in-between two precalculated points is queried, averaging is applied to determine the value.

The classes should be considered experimental 'proof-of-concept' code at this time. 

####What CGPathQuery isn't for  
- Animating layers along a path. Core animation already does a great job of doing this by setting  an animation.path property and an appropriate speed.


####References
CGPathQuery uses the following techniques/libraries: 

- Nick Lockwood's "iOS Core Animation: Advanced Techniques" - Ch. 9 - Manual Animation, which mentions the technique of setting speed to zero to get values immediately.
- CAAnimationBlocks, which is used in this library.
- This advice on creating an opengl context - required in order to get a non-nil presentationLayer: https://stackoverflow.com/questions/3429925/carenderer-never-produces-output/3430544#3430544

####Alternatives
- Creating a dashed line along a path and 
- Using an external library like [Wykobi](http://www.wykobi.com/) (GPL/commercial) or [Claw](http://libclaw.sourceforge.net/index.html) (LGPL) to query a similarly-created path.


###TODO
- Ideally I'd like to get rid of the pre-calculation step, but haven't yet found a way to retrieve animation values with core animation without either causing a deadlock on the main thread.
- Add rotation support. I've been able to grab the rotation angle in other demos from the presentationValue while layers are visible, but haven't been able to see it update in the current code.