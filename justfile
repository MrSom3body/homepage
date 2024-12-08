alias s := serve
alias u := update

serve:
    $BROWSER localhost:1313
    hugo server

update:
    git submodule update --remote --merge
    git add themes/blowfish
    git commit -m "themes/blowfish: update" themes/blowfish
