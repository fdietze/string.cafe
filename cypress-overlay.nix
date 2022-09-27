# Based on: https://gist.github.com/r-k-b/2485f977b476aa3f76a47329ce7f9ad4

# When Cypress starts, it copies some files into `~/.config/Cypress/cy/production/browsers/chrome-stable/interactive/CypressExtension/`
# from the Nix Store, one of which it attempts to modify immediately after.
# As-is, this fails because the copied file keeps the read-only flag it had in
# the Store.
# Luckily, the code responsible is a plain text script that we can easily patch:
final: prev: {
  cypress = prev.cypress.overrideAttrs (oldAttrs: rec {
    pname = "cypress";
    version = "10.7.0";

    src = prev.fetchzip {
      url = "https://cdn.cypress.io/desktop/${version}/linux-x64/cypress.zip";
      sha256 = "sha256-d9rJEC+1+68jVyq7c2sR92HGvqsfWctr52TIX7wTjDc=";
    };

    installPhase =
      let
        oldChrome = "fs_1.fs.chmod(extensionBg, 0o0644)";
        newChrome = "fs_1.fs.chmod(extensionDest, 0o0644)";

        oldFirefox = "fs.chmod(extensionBg, 0o0644)";
        newFirefox = "fs.chmod(extensionDest, 0o0644)";
      in
      ''
        sed -i 's/${oldChrome}/${newChrome}/' \
            ./resources/app/packages/server/lib/browsers/chrome.js

        sed -i 's/${oldFirefox}/${newFirefox}/' \
            ./resources/app/packages/server/lib/browsers/utils.js
      '' + oldAttrs.installPhase;
  });
}
