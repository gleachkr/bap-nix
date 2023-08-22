{
  description = "libghidra dependencies for bap";

  inputs = {
    libghidraDev = {
      url = "https://launchpad.net/~ivg/+archive/ubuntu/ghidra/+files/libghidra-dev_10.0~beta-3~focal_amd64.deb";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, libghidraDev }: let

    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    libghidra = pkgs.stdenv.mkDerivation {
      name = "libghidra";
      src = libghidraDev;
      sourceRoot = ".";
      dontConfigure = true;
      dontBuild = true;
      unpackCmd = "${pkgs.dpkg}/bin/dpkg -x ${libghidraDev} .";
      installPhase = ''
        mkdir $out
        cp -r usr/* $out
        cp -r usr $out
      '';
    };

  in {

    packages.x86_64-linux.libghidra = libghidra;

    packages.x86_64-linux.default = self.packages.x86_64-linux.libghidra;

  };
}
