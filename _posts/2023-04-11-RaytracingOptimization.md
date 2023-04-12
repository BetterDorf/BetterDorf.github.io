---
layout: post
title: Optimizing a simple cpu raytracer
---
* This will become a table of contents (this text will be scrapped).
{:toc}
# Introduction

In this blogpost, we will look at the implementation and a few optimizations for a CPU raytracer. Our base implementation will be closely following that of [“Ray Tracing In One Weekend”](https://raytracing.github.io/) with some partial optimizations from [“Ray Tracing:The Next Week”](https://raytracing.github.io/) that we’ll talk about later.

# Raytracer ?
Before we talk about the specifics of our raytracer we should first cover what a raytracer even is.

Raytracing is a technique used in computer graphics to generate images by tracing the path of light as it interacts with objects in a scene. In a CPU raytracer, each pixel in the image is rendered by calculating the color value of a ray that intersects with a 3D object in the scene. While raytracing is known for producing high-quality images, it can be computationally expensive, particularly when rendering complex scenes. In short, for each pixel on our screen, we’ll shoot multiple rays into our scene and compute the color they achieve as they bounce on volumes etc…

In this blog post, we'll discuss our implementation of a CPU raytracer, which is based on the popular tutorial "Ray Tracing In One Weekend". We'll also explore some optimizations we made to improve the performance of the raytracer. Specifically, we'll discuss optimizations we implemented from "Raytracing the next week," as well as some additional optimizations we attempted. The performance improvements we made to the raytracer were significant: while the naive version took several minutes to render a simple scene, the more optimized version was able to render the same scene in just a few seconds. This speedup makes it possible to generate high-quality images much more quickly. Although in our particular case our raytracer remains much too slow for real-time applications like video games.

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

# First Implementation
We started by following closely the design of [Ray Tracing In One Weekend](https://raytracing.github.io/). Although we also coded in cpp, we disagreed with some of the design decisions made. For instance, we eliminated most shared_ptr from the codebase as sharing ownership of objects wasn't necessary and we believe that shared_ptr should only be used when other ownerships model fail. Instead we decided to work only with the objects directly rather than holding pointers to where they were created.

Another change was the flattening of the hit function. It used to work by recursion, calling hit again when a ray hit an object which we changed to all be processed in a single hit call. This is typically easier for most compilers to optimize and decrease the amount of overhead induced by growing the call stack unnecessarily.
<style>
table {
  font-family: arial, sans-serif;
  border-collapse: collapse;
  width: 100%;
}

td, th {
  border: 1px solid #dddddd;
  text-align: left;
  padding: 8px;
}

tr:nth-child(even) {
  background-color: #dddddd;
}
</style>

This first implementation had these results :<br>
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
      <td><b>Naive</b></td>
        <td>2&#39;520 ms</td>
        <td>8&#39;063 ms</td>
        <td>100&#39;788 ms</td>
    </tr>
</table>

We will notice with the next few chapter that the performance displayed here is quite alright for small scenes. But as we scale it becomes exponentially worse with the complexity of the scene.

A quick look at a profiling tool reveals that we are currently using most of our render time in the hit function.

![Picture of Tracy profiler that show most of the time being taken by hit functions](/images/TracyCapture.PNG)<br>

Why is that ? The key to the answer is in how our rendering time grows with scene size.

In this naïve implementation, every time a ray asks what it hits it must interrogate each sphere in our scene. This results in massive time costs because we are computing intersections tests between each ray and each sphere. This means 50 x 904 = **45200 tests** at a minimum per pixel and 480 x 360 x 180800 = **7'810'560'000** for the whole screen. More than 7 billion tests without considering that most ray bounce at least once. This makes it by far our most called function and our biggest time sink.

# Bounding volumes Hierarchy
This problem of performing many intersections test is quite reminiscent of physics engine. In that context the problem is typically approached with the concepts of broad phase and narrow phase. We spend some time in the broad phase determining which collisions are possible / likely to occur before performing the check “for real” in the narrow phase between the possible collisions. A common broad phase method is to somehow separate the space into regions so that we can easily tell if objects are too far apart to collision.

Are there some methods that we could analogously use in our raytracer ? Well, yes there is. What we will use is a Bounding Volume Hierarchy (BVH). The structure of the BVH is a tree where each node has a bounding volume in which all its child nodes fit inside. To figure out which sphere we would hit with a ray we would first interrogate the root node, if we hit its bounding volume, we then check its children bounding volumes etc… until we arrive at a leaf node which would be our hit sphere. The tree typically has a similar amount of parent nodes as there are of leaf objects i.e. 904 objects yields around 904 more nodes in our BVH.

The benefit of the BVH is immediately obvious when we consider that we will quickly descend the tree narrowing down on good candidates and far-off spheres will all be eliminated in a few checks if we do not hit their parent nodes. In the worst cases (for instance, if all spheres are tightly bundled together) the time complexity is not improved, remaining **O(n)**. But given a more typical situation the BVH will result in **O(logn)** calculations. Not to mention that most of these calculations are done on ray to bounding volumes intersections rather than ray to sphere (or any more complex collider type) further reducing the time needed to perform all the checks.

A simple BVH implementation can be found at [Ray Tracing:The Next Week](https://raytracing.github.io/books/RayTracingTheNextWeek.html) which divides along the spheres based on the x, y or z axes. Implementing it as-is yields the following results for us : <br>
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
      <td><b>BVH</b></td>
        <td>5&#39;263 ms</td>
        <td>9&#39;386 ms</td>
        <td>25&#39;058  ms</td>
    </tr>
</table>

Which can be compared with our base performances:
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
        <td>Naive</td>
        <td><b>2&#39;520 ms</b></td>
        <td><b>8&#39;063 ms</b></td>
        <td>100&#39;788 ms</td>
    </tr>
    <tr>
        <td><b>BVH</b></td>
        <td>5&#39;263 ms</td>
        <td>9&#39;386 ms</td>
        <td><b>25&#39;058  ms</b></td>
    </tr>
</table>

We can clearly see a net increase in performance for our very large scene but the two other scenes are now slower than before. Why is that ?
Something that we did not consider previously is the quality of the BVH. Simply put, if all bounding volumes are huge / inaccurate to the children they own we will have a BVH where we will have to traverse the whole tree every time we want to perform hit detection. While still in the same complexity domain **O(n)** we are doing twice the work when our BVH structure doesn’t closely resemble the spatial relationships between our spheres.

# Agglomerative Bounding Volumes Hierarchy.
To construct a better BVH we will take an agglomerative approach where we start with the spheres and find their closest neighbor to agglomerate into a new parent node. We then do the same to all those parent nodes and again etc… until we are left with a single parent node. This approach typically yields much BVH that fit their elements much better because it was constructed with the closeness of its elements as its base heuristic. (Ericson, Christer (2005). "Hierarchy Design Issues". Real-Time collision detection. Morgan Kaufmann Series in Interactive 3-D Technology. Morgan Kaufmann. pp. 236–7. ISBN 1-55860-732-3.)

Our implementation for an agglomerative BVH takes inspiration from [this](https://www.cs.cmu.edu/~blelloch/papers/GHFB13.pdf) paper from Carnegie Mellon University. (Gu, Yan; He, Yong; Fatahalian, Kayvon; Blelloch, Guy (2013). "Efficient BVH Construction via Approximate Agglomerative Clustering" (PDF). HPG '13: Proceedings of the 5th High-Performance Graphics Conference.)
With the alteration that we aren’t finding the closest pair each time but simply finding the closest sphere to our current sphere.

Furthermore, to avoid dereferencing pointers and losing time with inheritance we changed the node like so to find nodes and spheres more directly in memory.<br> 
![Bvh node class file showing that it holds indices for the position of the children nodes and spheres in the arrays of the world](/images/codeImage_11.png)<br>

If you are worrying at this point for the growing complexity of the setup phase, don’t. As you can see from these numbers :
<table>
    <tr>
        <td>Method</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
        <td>4100 Spheres</td>
        <td>10&#39;000 Spheres</td>
    </tr>
    <tr>
        <td>Making BVH</td>
        <td>&gt;0,001 ms</td>
        <td>0,011 ms</td>
        <td>1,86 ms</td>
        <td>32,5 ms</td>
        <td>189 ms</td>
    </tr>
</table>

Constructing the BVH takes negligible time in comparison to rendering.

Speaking of time here are the improvements that we see with this new implementation :
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
      <td><b>Aglo BVH</b></td>
        <td>3&#39;190 ms</td>
        <td>6&#39;415 ms</td>
        <td>10&#39;087  ms</td>
    </tr>
</table>

This performs much better in high-complexity scenes without sacrificing as much for the simpler ones as we can see when put side-by-side :
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
        <td>Naive</td>
      <td><b>2&#39;520 ms</b></td>
        <td>8&#39;063 ms</td>
        <td>100&#39;788 ms</td>
    </tr>
    <tr>
        <td>BVH</td>
        <td>5&#39;263 ms</td>
        <td>9&#39;386 ms</td>
        <td>25&#39;058 ms</td>
    </tr>
    <tr>
        <td><b>Aglo BVH</b></td>
        <td>3&#39;190 ms</td>
        <td><b>6&#39;415 ms</b></td>
        <td><b>10&#39;087 ms</b></td>
    </tr>
</table>

From this point on, we will refer with BVH to the agglomerative BVH implementation and will no longer consider the first implementation.

# The low hanging-fruit
The obvious optimization from the start when doing a raytracer is always going to be multithreading.
Since there is no dependence between rays we can always start computing the next one without waiting for results. This makes raytracing a fantastic candidate for multithreading.

In our program we decided to use [OpenMP’s library](https://www.openmp.org/). This provides a very quick way to send tasks to multiple threads without major code refactoring. Simply tacking on this command '#pragma omp parallel for schedule(static)' above our main loop like so :<br>
![Code of the main loop where we send our rays into the scen with the omp command above it](/images/codeImage_12.png)<br>

Yield those results without the BVH :
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
      <td><b>Naive MT</b></td>
        <td>3&#39;195 ms</td>
        <td>3&#39;887 ms</td>
        <td>19&#39;597 ms</td>
    </tr>
</table>

Which performs much better than the single-threaded version in most cases :
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
        <td>Naive</td>
      <td><b>2&#39;520 Ms</b></td>
        <td>8&#39;063 Ms</td>
        <td>100&#39;788 Ms</td>
    </tr>
    <tr>
        <td><b>naive Mt</b></td>
        <td>3&#39;195 Ms</td>
      <td><b>3&#39;887 Ms</b></td>
      <td><b>19&#39;597 Ms</b></td>
    </tr>
</table>

We can observe a slight overhead cost that makes it slower for small scenes but as soon as the complexity increases a little the benefits are immediately obvious.
This leads us to combining both optimizations into one :
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
        <td>Naive</td>
        <td><b>2&#39;520 ms</b></td>
        <td>8&#39;063 ms</td>
        <td>100&#39;788 ms</td>
    </tr>
    <tr>
        <td>Naive MT</td>
        <td>3&#39;195 ms</td>
        <td>3&#39;887 ms</td>
        <td>19&#39;597 ms</td>
    </tr>
    <tr>
        <td><b>MT BVH</b></td>
        <td>3&#39;284 ms</td>
        <td><b>3&#39;773 ms</b></td>
        <td><b>4&#39;746 ms</b></td>
    </tr>
</table>

We can obverse a significant speedup for the complex scene where it's only 22% slower going from 68 to 904 spheres.

This leads us to our final comparison table :
<table>
    <tr>
        <td>Technique</td>
        <td>5 Spheres</td>
        <td>68 Spheres</td>
        <td>904 Spheres</td>
    </tr>
    <tr>
        <td>Naive</td>
      <td><b>2&#39;520 ms</b></td>
        <td>8&#39;063 ms</td>
        <td>100&#39;788 ms</td>
    </tr>
    <tr>
        <td>BVH</td>
        <td>5&#39;263 ms</td>
        <td>9&#39;386 ms</td>
        <td>25&#39;058 ms</td>
    </tr>
    <tr>
        <td>Aglo BVH</td>
        <td>3&#39;190 ms</td>
        <td>6&#39;415 ms</td>
        <td>10&#39;087 ms</td>
    </tr>
    <tr>
        <td>Naive MT</td>
        <td>3&#39;195 ms</td>
        <td>3&#39;887 ms</td>
        <td>19&#39;597 ms</td>
    </tr>
    <tr>
      <td><b>MT BVH</b></td>
        <td>3&#39;284 ms</td>
      <td><b>3&#39;773 ms</b></td>
      <td><b>4&#39;746 ms</b></td>
    </tr>
</table>

For those that prefer graphical comparisons : <br>
![](/images/5Obj.PNG)<br>
![](/images/68Obj.PNG)<br>
![](/images/904Obj.PNG)<br>

# Going further
We will stop there our exploration of optimizations for our CPU raytracer but let us conclude by mentioning a few areas that we could still improve upon.

Firstly, while openMP provides a great utility, simply tacking on a command won't yield the best possible results for a multi-threaded applications. Because we don't need to refactor our code, we aren't removing any race conditions and we can see in a profiler that a significant amount of time is lost waiting. Disentangling these relationships and using a more explicit task scheduler would surely improve our ability to paralellize rays calculations.

Sorting the data in our world could also be a relevant optimization as sorting data typically takes much less time and would allow for fewer cache misses. The sorting would be done so that the left child of a node is always the node right after in our world's array so that a cacheline would always grab a relevant chain of parent / children nodes. This would allow us to have the child cached next to its parent 50% of the time.

Typically, compilation flags can make a big impact on an application's performances. However in our particular case, we didn't find any significant improvement by varying the compilation flags.

Finally, a small hack that was given to us by [Frédéric Dubouchet](https://github.com/anirul) is to bypass the BVH system entirely for the first ray cast of any given ray (that is to say, use the BVH for all subsequent rebounds) and instead compute at startup which spheres intersect with an array of horizontal and vertical planes and store thoses boolean results. Each plane denotes a row or column of pixels so that when we cast a ray for a pixel at coordinate y = 7 and x = 32 we check only the spheres that are intersecting with the 7th horizontal plane and the 32th vertical plane.
Although powerful, this trick wouldn't work as is for us in this implementation because we shoot ray with slight variations in origin to simulate a camera's focal length.

This concludes our small tour of the optimizations we performed on the classic [“Ray Tracing In One Weekend”](https://raytracing.github.io/).

Our code can be found [here](https://github.com/BetterDorf/GPR5204-Raytracing).
