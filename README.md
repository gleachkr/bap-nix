# bap-flake

This is an (experimental) Nix flake, intended to provide simple reproducible
builds of [CMU BAP](https://github.com/BinaryAnalysisPlatform/bap), the
Carnegie Mellon University Binary Analysis Platform.

# Basic Usage

To build a usable `bap`, on an `x86_64-linux` system: 

1. Make sure you have `nix` [installed](https://nixos.org/download.html). 

2. Create an empty directory

``` 
$ mkdir bap-nix
```

and run 

```
$ nix build github:gleachkr/bap-nix#cli
```

3. Get a cup of coffee or something.

When you return, you'll find a executable called `bap` under
`bap-nix/result/bin/bap`. This executable wraps the ordinary `bap` executable
(available at `bap-nix/result/bapClassic`) with a fair number of environment
variables that tell it where to find its runtime dependencies.
