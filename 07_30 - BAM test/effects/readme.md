# Overview

A BAM (Brightness Assignment Map), is a 2D map in a particular view space where the value per pixel in the map represents the total available brightness per unit area on the geometry surface seen by that BAM pixel.

This iteration of BAM technology is not fully optimised for speed (e.g. calculations are often repeated), but is a verbose prototype of a BAM technique.

# Terminology

* BAM View = Sweet Spot View = View onto the scene, from which brightness is evenly distributed
* Projector View

# Stages

## Generate

## Lookup

We render each pixel for each projector.


# Possible issues

## Gamma

Is this performed at ...?

* On factor (we presume this)
* On all colour values
* On colour values post factor