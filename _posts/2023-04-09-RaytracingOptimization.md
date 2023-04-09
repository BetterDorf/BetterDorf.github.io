---
layout: post
title: Optimizing a basic cpu raytracer
---
# Context

The third years at the SAE in games programming are creating SubCaleo, a
pod racing game in 3D using unreal engine. We (the 2nd year) were
tasked to develop tools and features to assist them.

My group was tasked with doing a minimap and tools to help use it. In
this project the minimap is a stylized drawing of the map in a similar
fashion as the minimaps of mario kart (*Fig. 1*).

![](/images/Blog1.png)<br/>
*Figure 1 Minimaps for Mario Kart DS, Nintendo, 2005*

To produce the minimap, the artists need a reference that is in the same
perspective and of the same size as the desired minimap. In my group, I
was tasked with making the tool that would take a picture of the level
and export it as an image while a colleague would make the user
interface that would call my implementation.

# Inputs and outputs
