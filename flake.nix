{ description = "Build an opam project not in the repo, using sane defaults";
  inputs.opam-nix.url = "github:tweag/opam-nix";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.libghidra.url = "/home/graham/Projects/libghidra-flake";
  inputs.bapRepo = {
    url = "github:BinaryAnalysisPlatform/bap";
    flake = false;
  };
  outputs = { self, opam-nix, bapRepo, nixpkgs, libghidra, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system: let

      baseScope = let
        inherit (opam-nix.lib.${system}) buildDuneProject;
        scope = buildDuneProject { } "bap" bapRepo {
          ocaml-base-compiler="4.14.1";
          piqi="*";
          bitstring="*";
          ppx_bitstring="*";
          ezjsonm="*";
          yojson ="*";
          ocurl ="*";
          z3 = "*";
        };
      in scope;

      pkgs = nixpkgs.legacyPackages.${system}.extend
      (final: prev : {
        ncurses5 = prev.ncurses5.overrideAttrs (oa : {
          postFixup = "ln -s $out/lib/libncursesw.so $out/lib/libcurses.so";
        });
      });

      overlay = final: prev: {
        bap-recipe = prev.bap-recipe.overrideAttrs (oa: {
          buildInputs = oa.buildInputs ++ [ 
            final.camlzip 
            final.fileutils
          ];
        });
        bap-llvm = prev.bap-llvm.overrideAttrs (oa : {
          buildInputs = oa.buildInputs ++ [
            pkgs.zstd
            pkgs.ncurses5
          ];
        });
        bap-core = prev.bap-core.overrideAttrs (oa : {
          buildInputs = oa.buildInputs ++ [
            pkgs.zstd
          ];
        });
        bap-primus-propagate-taint = 
        prev.bap-primus-propagate-taint.overrideAttrs (oa : {
          buildInputs = oa.buildInputs ++ [
            final.bap-microx
          ];
        });

        piqi = 
        prev.piqi.overrideAttrs (oa : {
          postFixup = "cp -r $out/lib/piqirun $out/lib/ocaml/4.14.1/site-lib/";
        });

        z3 = 
        prev.z3.overrideAttrs (oa : {
          # the ocaml z3 build toolchain requires that the destination
          # directory exists prior to building
          preBuild = "mkdir -p $out/lib/ocaml/4.14.1/site-lib";
        });

        bap = prev.bap.overrideAttrs (oa : {
          patches = [
            (pkgs.substituteAll {
              src = ./libghidra.patch;
              libghidra = libghidra.packages.x86_64-linux.default.outPath;
            })
          ];

          # dune bakes the build dir into the build artifacts, 
          # so it's necessary to build directly into $out
          buildPhase = "dune build --build-dir $out";

          nativeBuildInputs = oa.nativeBuildInputs ++ [ 
            final.piqi
          ];

          buildInputs = oa.buildInputs ++ [
            final.z3
            final.piqi
            final.ppx_bitstring
            final.ezjsonm
            final.yojson
            final.ocurl
            libghidra.packages.x86_64-linux.default
          ];

        });
      };

      legacyPackages = baseScope.overrideScope' overlay;

  in {

    inherit legacyPackages;

    inherit pkgs;

    defaultPackage = self.legacyPackages.${system}.bap;

    packages.frontend = self.legacyPackages.${system}.bap-frontend;

    packages.cli = self.legacyPackages.${system}.bap-frontend.overrideAttrs (oa :{

      nativeBuildInputs = oa.nativeBuildInputs ++ [pkgs.makeWrapper];
      # the buildInputs below guarantee that what the bap frontend needs is on
      # OCAMLPATH in the build environment.
      buildInputs = [legacyPackages.bap-core legacyPackages.bap];
      postFixup = ''
        mv $out/bin/bap $out/bin/bapClassic
        makeWrapper $out/bin/bapClassic $out/bin/bap \
        --set DUNE_SOURCEROOT "${legacyPackages.bap.outPath}" \
        --set DUNE_OCAML_STDLIB "${legacyPackages.ocaml-base-compiler.outPath}/lib/ocaml" \
        --set DUNE_OCAML_HARDCODED "${legacyPackages.ocaml-base-compiler.outPath}/lib" \
        --set DUNE_DIR_LOCATIONS "bap-common:share:${legacyPackages.bap.outPath}/install/default/share/bap-common:bap-common:lib:${legacyPackages.bap.outPath}/install/default/lib/bap-common" \
        --set OCAMLPATH ${legacyPackages.bap.outPath}/install/default/lib:$OCAMLPATH
      '';
    });

    devShell = self.legacyPackages.${system}.bap;

  });
}
