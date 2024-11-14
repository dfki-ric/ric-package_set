# dfki.ric package set

This package set defines public [DFKI RIC](https://robotik.dfki-bremen.de/)
[rock](https://www.rock-robotics.org/) packages that are not part of other
package sets. In an
[autoproj](http://rock-robotics.org/documentation/autoproj)
bootstrap, this package set is selected by adding the following in the
`package_sets` section of `autoproj/manifest`:

```
package_sets:
    - github: dfki-ric/ric-package_set
```

If you want to build all of the packages in the `dfki.ric` package set, you
would add `dfki.ric` to the layout section:
```
layout:
    - dfki.ric
```
