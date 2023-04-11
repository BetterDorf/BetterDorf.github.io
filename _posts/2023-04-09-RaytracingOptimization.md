---
layout: post
title: Optimizing a simple cpu raytracer
---
# Context
In this blogpost, we will look at the implementation and a few optimizations for a CPU raytracer. Our base implementation will be closely following that of [“Raytracing in a weekend”](https://raytracing.github.io/) with some partial optimizations from [“Raytracing the next week”](https://raytracing.github.io/) that we’ll talk about later.

# Raytracer ?
Before we talk about the specifics of our raytracer we should first cover what a raytracer even is.

Raytracing is a technique used in computer graphics to generate images by tracing the path of light as it interacts with objects in a scene. In a CPU raytracer, each pixel in the image is rendered by calculating the color value of a ray that intersects with a 3D object in the scene. While raytracing is known for producing high-quality images, it can be computationally expensive, particularly when rendering complex scenes. In short, for each pixel on our screen, we’ll shoot multiple rays into our scene and compute the color they achieve as they bounce on volumes etc…

In this blog post, we'll discuss our implementation of a CPU raytracer, which is based on the popular tutorial "Raytracing in a weekend." We'll also explore some optimizations we made to improve the performance of the raytracer. Specifically, we'll discuss optimizations we implemented from "Raytracing the next week," as well as some additional optimizations we attempted. The performance improvements we made to the raytracer were significant: while the naive version took several minutes to render a simple scene, the more optimized version was able to render the same scene in just a few seconds. This speedup makes it possible to generate high-quality images much more quickly. Although in our particular case our raytracer remains much too slow for real-time applications like video games.

# Optimization philosophy
Our goal in this experiment is to improve the performances of a CPU raytracer on a variety of scene complexities without altering the behavior of the raytracer.

We will measure only the time taken to construct the scene (as some optimizations require more setup time to construct a scene hierarchy in a specific way) and to make the render and not the time used to export the data to an image or the screen.

Using less rays and applying upscaling technology and / or a denoiser would yield similar qualities of images at a lesser computing cost but this would represent too grand a departure from the behavior of our initial raytracer and are therefore not acceptable optimizations.

We will not remove arguably unnecessary features from the original implementation such as simulating the behavior of a camera lens or doing antialiasing through the randomization of the direction of the rays.

Finally, we will consider only optimizations in regards to a CPU workload and won’t discuss GPU implementations.

# The Testing Scene
In order to provide meaningful tests and benchmarks, we used a consistent set of scenes throughout our performance testing.
![Scene with 5 spheres](/images/Scene1.png)<br> ![Scene with 68 spheres](/images/Scene8.png)<br> ![Scene with 904 spheres](/images/Scene30.png)<br>

These scenes include five spheres (one for the ground and three larger spheres, plus an additional stray sphere), 68 spheres, and 904 spheres respectively. The location of the stray spheres determined by a seeded random distribution. By benchmarking on scenes of varying sizes and complexity, we were able to evaluate how well our optimizations scaled with the number of objects in the scene. In all cases we will be working with 50 samples per pixels and a depth of 30 on a resolution of 480 by 360 pixels. In this context, samples per pixels mean the number of rays for a given pixel while depth refers to how many rebounds we allow a ray to have before we decide that it is “lost”.
