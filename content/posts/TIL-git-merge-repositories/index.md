---
title: "TIL: Merge git repositories"
date: 2025-01-28
lastmod: 2025-01-28
draft: false
description: How to merge two git branches from different repositories while keeping the history
summary: How to merge two git repositories while keeping the history
tags:
  - git
  - TIL
---

{{< alert >}}
These commands can be extremely destructive! Don't just blindly copy them pls :)
{{< /alert >}}

Ever thought about getting commits of another repository into another one? Yeah,
me neither until today.

You may think it's complicated, but it really isn't. Let's say you have these
two repositories:

{{< mermaid >}}
gitGraph
branch to-merge
checkout main
commit
commit
commit
checkout to-merge
commit
commit
commit
{{< /mermaid >}}

Your main repository is the one called `main` (really creative right?). The one
you want to merge is called `to-merge` (🤯). The goal is to make it look like
the following git graph, but how would you do that?

{{< mermaid >}}
gitGraph
commit
commit
commit
commit
commit
commit
{{< /mermaid >}}

First you'll start on your main repository (in this
case `main`). Then run the following commands:

```sh
git remote add to-merge <path/url>
git rebase main to-merge/main
# now fix all the merge conflicts that may occur
git log --oneline | head -1 # copy the commit id which this command returns
git rebase <commit id> main
```

Every thing in between `<` and `>` is supposed to be replaced. You can also
rename `to-merge` to something else if you really want to.

Now if you also use GitHub you'll probably notice on your GitHub repository that
the timestamps are not correct. Run the following commands to also fix these:

```sh
git filter-branch --env-filter 'export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"'
git push -f
```
