---
layout: post
title: SubCaleo Minimap tool blogpost
---
# Context

The third years at the SAE in games programming are creating SubCaleo, a
pod racing game in 3D using unreal engine. We (the 2^nd^ year) were
tasked to develop tools and features to assist them.

My group was tasked with doing a minimap and tools to help use it. In
this project the minimap is a stylized drawing of the map in a similar
fashion as the minimaps of mario kart (Fig 1).

![](/images/Blog1.png)
Figure 1 Minimaps for Mario Kart DS, Nintendo, 2005

To produce the minimap, the artists need a reference that is in the same
perspective and of the same size as the desired minimap. In my group, I
was tasked with making the tool that would take a picture of the level
and export it as an image while a colleague would make the user
interface that would call my implementation.

# Inputs and outputs

As input, we have the game level (Fig 2) and user parameters (Fig 3)
which we will use to write a PNG file to the disk. This PNG is a view
from above of the level (FIG 4) at the given coordinates.

![](/images/Blog2.png)
Figure 2 Level view

![](/images/Blog3.png)

Figure 3 Camera parameters

![](/images/Blog4.png)

Figure 4 PNG from above

# Implementation

Because re-inventing the wheel is a waste of time, we will use Unreal
built-in functionalities to render and export our image. As theses
functionalities come packaged within the CaptureComponent2D we will
create an actor prototype that will use this component to capture the
scene onto a render target which we can then export as a PNG to the
disk.

This means that, to create an image, we need to instantiate the actor in
the level then use its render method after which we can delete it.

In Unreal, this means creating a c++ class (Fig. 5) inheriting from actor that
hold a CaptureComponent2D (used for rendering).

![](/images/Blog5.png)

Where, in the constructor (Fig. 6), we need to find the renderTarget and
parameter the CaptureComponent for compatibility with the PNG format.

![](/images/Blog6.png)

Rendering to a PNG is then simply achieved by rendering the
CaptureComponent2D's view to the renderTarget and then calling the
Kismet Rendering Library's conversion on that as shown in Fig. 7.

![](/images/Blog7.png)

The user can then go ahead and destroy the actor as it has served its
purpose. To simplify the workflow, I have created a static method that
take all the relevant parameters and instantiate an Actor, render the
scene to a PNG and destroy the Actor afterwards. This makes calling the
render screenshot much more straightforward as it is all packaged in a
single method.

#  Conclusion

The goal of the tool was to simplify the artist's job and minimize the
time necessary for a developer to integrate minimaps in the game. To
this end, we made we made a tool that could be used to quickly provide
references for artists and that need little to no technical knowledge to
swap with their final versions once those are ready.

Through the development of this tool, I've learned about using Unreal
Editor's API and working as a team to meet demands.
