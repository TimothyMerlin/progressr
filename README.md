# progressr: A Unifying API for Progress Updates

![Life cycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)

The **[progressr]** package provides a minimal API for reporting progress updates in [R](https://www.r-project.org/).  The design is to separate the representation of progress updates from how they are presented.  What type of progress to signal is controlled by the developer.  How these progress updates are rendered is controlled by the end user.  For instance, some users may prefer visual feedback such as a horizontal progress bar in the terminal, whereas others may prefer auditory feedback.


<img src="incl/three_in_chinese.gif" alt="Three strokes writing three in Chinese" style="float: right; margin-right: 1ex; margin-left: 1ex;"/>

Design motto:

> The developer is responsible for providing progress updates but it's only the end user who decides if, when, and how progress should be presented. No exceptions will be allowed.


## Two Minimal APIs

 | Developer's API       | End-user's API              |
 |-----------------------|-----------------------------|
 | `p <- progressor(n)`  | `with_progress(expr)`       |
 | `p(msg, ...)`         | `handlers(...)`             |
 |                       | `options(progressr.*=...)`  |



## A simple example

Assume that we have a function `slow_sum()` for adding up the values in a vector.  It is so slow, that we like to provide progress updates to whoever might be interested in it.  With the **progressr** package, this can be done as:

```r
slow_sum <- function(x) {
  progress <- progressr::progressor(length(x))
  sum <- 0
  for (kk in seq_along(x)) {
    Sys.sleep(0.1)
    sum <- sum + x[kk]
    progress(message = sprintf("Added %g", x[kk]))
  }
  sum
}
```

Note how there are _no_ arguments in the code that specifies how progress is presented.  The only task for the developer is to decide on where in the code it makes sense to signal that progress has been made.  As we will see next, it is up to the end user of this code to decide whether they want to receive progress updates or not, and, if so, in what format.


### Without reporting progress

When calling this function as in:
```r
> y <- slow_sum(1:10)
> y
[1] 55
>
```
it will behave as any function and there will be no progress updates displayed.


### Reporting progress

To get progress updates, we can call it as:
```r
> library(progressr)
> with_progress(y <- slow_sum(1:10))
  |=====================                                |  40%
```


## Customizing how progress is reported

The default is to present progress via `utils::txtProgressBar()`, which is available on all R installations.  To change the default, to, say, `progress_bar()` by the **[progress]** package, set:

```r
handlers("progress")
```
This progress handler will present itself as:
```r
> with_progress(y <- slow_sum(1:10))
[==================>---------------------------]  40% Added 4
```

To set the default progress handler(s) in all your R sessions, call `progressr::handlers(...)` in your <code>~/.Rprofile</code> file.  An alternative, which avoids loading the **progressr** package if never used, is to set `options(progressr.handlers = progress_handler)`.



### Auditory progress updates

Note all progress updates have to be presented visually. This can equally well be done auditory. For example, using:

```r
handlers("beepr")
```
will present itself as sounds played at the beginning, while progressing, and at the end (using different **[beepr]** sounds).  There will be _no_ output written to the terminal;
```r
> with_progress(y <- slow_sum(1:10))
> y
[1] 55
>
```


### Concurrent auditory and visual progress updates

It is possible to have multiple progress handlers presenting progress updates at the same time.  For example, to get both visual and auditory updates, use:
```r
handlers("txtprogressbar", "beepr")
```


## Support for progressr elsewhere

### The plyr package

The functions in the [**plyr**](https://cran.r-project.org/package=plyr) package take argument `.progress`, which can be used to produce progress updates.  To have them generate **progressr** 'progression' updates, use `.progress = "progressr"`. For example,
```r
library(progressr)
with_progress({
  y <- plyr::l_ply(1:5, function(x, ...) {
    Sys.sleep(1)
    sqrt(x)
  }, .progress = "progressr")
})
## |=====================                                |  40%
```


### The future framework

The **[future]** framework has built-in support for the kind of progression updates produced by the **progressr** package.  Here is an example that uses `future_lapply()` of the **[future.apply]** package to parallelize on the local machine while at the same time signaling progression updates:

```r
library(future.apply)
plan(multisession)

library(progressr)
handlers("progress", "beepr")

with_progress({
  p <- progressr::progressor(5)
  y <- future_lapply(1:5, function(x, ...) {
    p(sprintf("x=%g", x))
    Sys.sleep(1)
    sqrt(x)
  })
})
## [=================>-----------------------------]  40% x=2
```



## Roadmap

Because this project is under active development, the progressr API is currently kept at a very minimum.  This will allow for the framework and the API to evolve while minimizing the risk for breaking code that depends on it.  The roadmap for developing the API is roughly:

1. Provide minimal API for producing progress updates, i.e. `progressor()` and `with_progress()`
   
2. Add support for nested progress updates

3. Add API to allow users and package developers to design additional progression handlers

For a more up-to-date view on what features might be added, see <https://github.com/HenrikBengtsson/progressr/issues>.


## Appendix

### Under the hood

When using the **progressr** package, progression updates are communicated via R's condition framework, which provides methods for creating, signaling, capturing, muffling, and relaying conditions.  Progression updates are of classes `progression` and `immediateCondition`(\*).  The below figure gives an example how progression conditions are created, signaled, and rendered.

(\*) The `immediateCondition` class of conditions are relayed as soon as possible by the **[future]** framework, which means that progression updates produced in parallel workers are reported to the end user as soon as the main R session have received them.




![](vignettes/figures/slow_sum.svg)

_Figure: Sequence diagram illustrating how signaled progression conditions are captured by `with_progress()` and relayed to the two progression handlers 'progress' (a progress bar in the terminal) and 'beepr' (auditory) that the end user has chosen._


### Debugging

To debug progress updates, use:
```r
> handlers("debug")
> with_progress(y <- slow_sum(1:10))
[13:33:49.743] (0.000s => +0.002s) initiate: 0/10 (+0) '' {clear=TRUE, enabled=TRUE, status=}
[13:33:49.847] (0.104s => +0.001s) update: 1/10 (+1) 'Added 1' {clear=TRUE, enabled=TRUE, status=}
[13:33:49.950] (0.206s => +0.001s) update: 2/10 (+1) 'Added 2' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.052] (0.309s => +0.000s) update: 3/10 (+1) 'Added 3' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.154] (0.411s => +0.001s) update: 4/10 (+1) 'Added 4' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.257] (0.514s => +0.001s) update: 5/10 (+1) 'Added 5' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.361] (0.618s => +0.002s) update: 6/10 (+1) 'Added 6' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.464] (0.721s => +0.001s) update: 7/10 (+1) 'Added 7' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.567] (0.824s => +0.001s) update: 8/10 (+1) 'Added 8' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.670] (0.927s => +0.001s) update: 9/10 (+1) 'Added 9' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.773] (1.030s => +0.001s) update: 10/10 (+1) 'Added 10' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.774] (1.031s => +0.003s) update: 10/10 (+0) 'Added 10' {clear=TRUE, enabled=TRUE, status=}
[13:33:50.776] (1.033s => +0.001s) shutdown: 10/10 (+0) '' {clear=TRUE, enabled=TRUE, status=ok}
```



[progressr]: https://github.com/HenrikBengtsson/progressr/
[beepr]: https://cran.r-project.org/package=beepr
[progress]: https://cran.r-project.org/package=progress
[future]: https://cran.r-project.org/package=future
[future.apply]: https://cran.r-project.org/package=future.apply

## Installation
R package progressr is only available via [GitHub](https://github.com/HenrikBengtsson/progressr) and can be installed in R as:
```r
remotes::install_github("HenrikBengtsson/progressr")
```

### Pre-release version

To install the pre-release version that is available in Git branch `develop` on GitHub, use:
```r
remotes::install_github("HenrikBengtsson/progressr@develop")
```
This will install the package from source.  



## Contributions

This Git repository uses the [Git Flow](http://nvie.com/posts/a-successful-git-branching-model/) branching model (the [`git flow`](https://github.com/petervanderdoes/gitflow-avh) extension is useful for this).  The [`develop`](https://github.com/HenrikBengtsson/progressr/tree/develop) branch contains the latest contributions and other code that will appear in the next release, and the [`master`](https://github.com/HenrikBengtsson/progressr) branch contains the code of the latest release.

Contributing to this package is easy.  Just send a [pull request](https://help.github.com/articles/using-pull-requests/).  When you send your PR, make sure `develop` is the destination branch on the [progressr repository](https://github.com/HenrikBengtsson/progressr).  Your PR should pass `R CMD check --as-cran`, which will also be checked by <a href="https://travis-ci.org/HenrikBengtsson/progressr">Travis CI</a> and  when the PR is submitted.


## Software status

| Resource:     | GitHub        | Travis CI       | AppVeyor         |
| ------------- | ------------------- | --------------- | ---------------- |
| _Platforms:_  | _Multiple_          | _Linux & macOS_ | _Windows_        |
| R CMD check   |  | <a href="https://travis-ci.org/HenrikBengtsson/progressr"><img src="https://travis-ci.org/HenrikBengtsson/progressr.svg" alt="Build status"></a>   |  |
| Test coverage |                     | <a href="https://codecov.io/gh/HenrikBengtsson/progressr"><img src="https://codecov.io/gh/HenrikBengtsson/progressr/branch/develop/graph/badge.svg" alt="Coverage Status"/></a>     |                  |
