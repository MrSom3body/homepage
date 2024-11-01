alias u := update

update:
    git submodule update --remote --merge
    git add themes/blowfish
    git commit -m "themes/blowfish: update" themes/blowfish

serve:
    $BROWSER localhost:1313
    hugo server
