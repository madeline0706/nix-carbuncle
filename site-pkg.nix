# Pure site build, shared by the NixOS module (site.nix) and the dev flake
# outputs. Kept separate so `nix build .#site` on shiva builds the exact same
# tree that gets deployed to carbuncle — no drift between dev and prod.
{ pkgs
, blogSrc ? ./site/blog
, terminalSrc ? ./site/terminal
, loraFont ? pkgs.lora
, hackFont ? pkgs.hack-font
}:

let
  # render the blog from markdown, and bundle the fonts
  blog = pkgs.runCommand "spellbound-blog"
    { nativeBuildInputs = with pkgs; [ cmark-gfm coreutils gnused gawk bash ]; }
    ''
      bash ${./blog-generate.sh} ${blogSrc} $out   # generate HTML into $out from the blog source
      mkdir -p $out/fonts
      cp ${loraFont}/share/fonts/truetype/'Lora[wght].ttf' $out/fonts/Lora.ttf              # serve Lora under /fonts
      cp ${loraFont}/share/fonts/truetype/'Lora-Italic[wght].ttf' $out/fonts/Lora-Italic.ttf # don't forget about italic
      cp ${./fonts/OFL.txt} $out/fonts/OFL.txt                                               # SIL OFL travels with the served font (nixpkgs' lora ships no license)
      cp ${hackFont}/share/fonts/truetype/Hack-Regular.ttf $out/fonts/Hack-Regular.ttf      # Hack: code blocks + terminal, referenced via /fonts from both
      cp ${hackFont}/share/fonts/truetype/Hack-Bold.ttf $out/fonts/Hack-Bold.ttf
      cp ${./fonts/Hack-LICENSE.md} $out/fonts/Hack-LICENSE.md                              # nixpkgs' hack-font ships no license, so carry it ourselves
    '';
in
# assemble the final served tree: blog at the root, static terminal app at /terminal
pkgs.runCommand "spellbound-site" { } ''
  mkdir -p $out
  cp -r ${blog}/. $out/                  # generated blog becomes the site root
  cp -r ${terminalSrc} $out/terminal     # parked terminal app mounted at /terminal
''
