alias u := update

update:
    git submodule update --remote --merge

serve:
    $BROWSER localhost:1313
    hugo server
