# libgit2 bindings for Emacs

[![Build status](https://travis-ci.org/magit/libegit2.svg?branch=master "Build Status")](https://travis-ci.org/magit/libegit2)
[![Build status](https://ci.appveyor.com/api/projects/status/jrisqkoiq07qt2in/branch/master?svg=true)](https://ci.appveyor.com/project/TheBB/libegit2/branch/master)

This is an *experimental* module for libgit2 bindings to Emacs, intended to boost the performance of
[magit](https://github.com/magit/magit).

Other work in this direction:
- [ksjogo/emacs-libgit2](https://github.com/ksjogo/emacs-libgit2) in C, has been dormant for more
  than a year.
- [ubolonton/magit-libgit2](https://github.com/ubolonton/magit-libgit2) in Rust.

This module is written in C, and aims to be a thin wrapper around libgit2. That means that all
functions in the [libgit2 reference](https://libgit2.github.com/libgit2/#HEAD) should translate
more-or-less directly to Emacs, in the following sense:

- Function names are the same, except with underscores replaced by hyphens. The prefix is changed
  from `git-` to `libgit-`.
- Predicate functions are given a `-p` suffix, and words like "is" are removed,
  e.g. `git_repository_is_bare` becomes `libgit-repository-bare-p`.
- Output parameters become return values.
- Error codes become error signals (type `giterr`).
- Return types map to their natural Emacs counterparts, or opaque user pointers when not applicable
  (e.g. for `git-???` structures). Exceptions: `git-oid` and `git-buf` types are converted to Emacs
  strings.
- Boolean parameters or pointers towards the end of argument lists whose natural default value is
  false or NULL will be made optional.

Quality-of-life convenience functionality is better implemented in Emacs Lisp than in C.

## Building

There is a loader file written in Emacs Lisp that will build the module for you, but the
`git submodule` steps need to be run manually.

```
git submodule init
git submodule update
mkdir build
cd build
cmake ..
make
```

If you're on OSX and using Macports, you may need to set `CMAKE_PREFIX_PATH` to avoid linking
against the wrong libiconv. For example,

```
cmake -DCMAKE_PREFIX_PATH=/opt/local ..
```

## Testing

Ensure that you have [Cask](https://github.com/cask/cask) installed.

```
cask install
cd build
make test
```

To see more output for debugging new tests you can specify more verbose output.

```
make test ARGS=-V
```

## Using

Ensure that `libgit.el` is somewhere in your load path. Then

```elisp
(require 'libgit)
```

If the dynamic module was not already built, you should be asked to do it manually.

If you use [Borg](https://github.com/emacscollective/borg), the following `.gitmodules` entry should
work.

```
[submodule "libgit"]
    path = lib/libgit
    url = git@github.com:magit/libegit2.git
    build-step = git submodule init
    build-step = git submodule update
    build-step = mkdir -p build
    build-step = cd build && cmake ..
    build-step = cd build && make
```

## Contributing

### Adding a function

1. Find the section that the function belongs to (i.e. `git_SECTION_xyz`).
2. Create, if necessary, `src/egit-SECTION.h` and `src/egit-SECTION.c`.
3. In `src/egit-SECTION.h`, declare the function with `EGIT_DEFUN`. See existing headers for
   examples.
4. In `src/egit-SECTION.c`, document the function with `EGIT_DOC`. See existing files for examples.
5. In `src/egit-SECTION.c`, implement the function. See existing files for examples.
   1. Always check argument types in the beginning. Use `EGIT_ASSERT` for this. These macros may return.
   2. Then, extract the data needed from `emacs_value`. This may involve allocating buffers for strings.
   3. Call the `libgit2` backend function.
   4. Free any memory you might need to free that was allocated in step 2.
   5. Check the error code if applicable with `EGIT_CHECK_ERROR`. This macro may return.
   6. Create return value and return.
6. In `src/egit.c`, create a `DEFUN` call in `egit_init`. You may need to include a new header.

### Adding a type

Sometimes a struct of type `git_???` may need to be returned to Emacs as an opaque user pointer. 
To do this, we use a wrapper structure with a type information tag. 

Usually, objects that belong to a repository need to keep the repository alive until after they are
freed. To do this, we use a hash table with reference counting semantics for repositories to ensure
that none of them are freed out of turn.

1. In `src/egit.h` add an entry to the `egit_type` enum for the new type.
2. In `src/egit.h` ass a new `EGIT_ASSERT` macro for the new type.
3. In `src/egit.c` add a new entry to the `egit_finalize` switch statement to free a
   structure. If the new structure needs to keep a repository alive (usually the "owner" in libgit2
   terms), also call `egit_decref_repository` on these (see existing code for examples).
4. In `src/egit.c` add a new entry to the `egit_wrap` switch statement to increase the reference
   counts of the repository if it must be kept alive.
5. In `src/egit.c` add a new entry to the `egit_typeof` switch statement.
6. In `src/egit.c` add a new `egit_TYPE_p` predicate function.
7. In `src/egit.c` create a `DEFUN` call in `egit_init` for the predicate function.
8. In `interface.h` add two new symbols, `TYPE-p` and `TYPE`.
9. In `interface.c` initialize those symbols in the `em_init` function.

## Function list

This is a complete list of functions in libgit2. It therefore serves more or less as an upper bound
on the amount of work needed.

Legend:
- :heavy_check_mark: Function is implemented
- :x: Function should probably not be implemented (reason given)
- :interrobang: Undecided

Some functions are defined in libgit2 headers in the `sys` subdirectory, and are not reachable from
a standard include (i.e. `#include "git2.h"`). For now, we will skip those on the assumption that
they are more specialized.

Estimates (updated periodically):
- Implemented: 54 (7.0%)
- Should not implement: 80 (10.4%)
- To do: 637 (82.6%)
- Total: 771

### extra

These are functions that do not have a `libgit2` equivalent.

- :heavy_check_mark: `libgit-object-p`
- :heavy_check_mark: `libgit-reference-p`
- :heavy_check_mark: `libgit-repository-p`
- :heavy_check_mark: `libgit-typeof`
- :heavy_check_mark: `libgit-reference-direct-p`
- :heavy_check_mark: `libgit-reference-symbolic-p`
- other type-checking predicates as we add more types

### annotated

- :x: `libgit-annotated-commit-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-annotated-commit-from-fetchhead`
- :interrobang: `libgit-annotated-commit-from-ref`
- :interrobang: `libgit-annotated-commit-from-revspec`
- :interrobang: `libgit-annotated-commit-id`
- :interrobang: `libgit-annotated-commit-lookup`

### attr

- :interrobang: `libgit-attr-add-macro`
- :interrobang: `libgit-attr-cache-flush`
- :interrobang: `libgit-attr-foreach`
- :interrobang: `libgit-attr-get`
- :interrobang: `libgit-attr-get-many`
- :interrobang: `libgit-attr-value`

### blame

- :interrobang: `libgit-blame-buffer`
- :interrobang: `libgit-blame-file`
- :x: `libgit-blame-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-blame-get-hunk-byindex`
- :interrobang: `libgit-blame-get-hunk-byline`
- :interrobang: `libgit-blame-get-hunk-count`
- :interrobang: `libgit-blame-init-options`

### blob

- :interrobang: `libgit-blob-create-frombuffer`
- :interrobang: `libgit-blob-create-fromdisk`
- :interrobang: `libgit-blob-create-fromstream`
- :interrobang: `libgit-blob-create-fromstream-commit`
- :interrobang: `libgit-blob-create-fromworkdir`
- :interrobang: `libgit-blob-dup`
- :interrobang: `libgit-blob-filtered-content`
- :x: `libgit-blob-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-blob-id`
- :interrobang: `libgit-blob-is-binary`
- :interrobang: `libgit-blob-lookup`
- :interrobang: `libgit-blob-lookup-prefix`
- :interrobang: `libgit-blob-owner`
- :interrobang: `libgit-blob-rawcontent`
- :interrobang: `libgit-blob-rawsize`

### branch

- :interrobang: `libgit-branch-create`
- :interrobang: `libgit-branch-create-from-annotated`
- :interrobang: `libgit-branch-delete`
- :interrobang: `libgit-branch-is-checked-out`
- :interrobang: `libgit-branch-is-head`
- :interrobang: `libgit-branch-iterator-free`
- :interrobang: `libgit-branch-iterator-new`
- :interrobang: `libgit-branch-lookup`
- :interrobang: `libgit-branch-move`
- :interrobang: `libgit-branch-name`
- :interrobang: `libgit-branch-next`
- :interrobang: `libgit-branch-set-upstream`
- :interrobang: `libgit-branch-upstream`

### buf

Probably none of these functions are necessary, since we can expose buffers to Emacs as strings.

- :x: `libgit-buf-contains-nul`
- :x: `libgit-buf-free` (memory management shouldn't be exposed to Emacs)
- :x: `libgit-buf-grow`
- :x: `libgit-buf-is-binary`
- :x: `libgit-buf-set`

### checkout

- :interrobang: `libgit-checkout-head`
- :interrobang: `libgit-checkout-index`
- :interrobang: `libgit-checkout-init-options`
- :interrobang: `libgit-checkout-tree`

### cherrypick

- :interrobang: `libgit-cherrypick`
- :interrobang: `libgit-cherrypick-commit`
- :interrobang: `libgit-cherrypick-init-options`

### clone

- :heavy_check_mark: `libgit-clone`
- :interrobang: `libgit-clone-init-options`

### commit

- :interrobang: `libgit-commit-amend`
- :interrobang: `libgit-commit-author`
- :interrobang: `libgit-commit-body`
- :interrobang: `libgit-commit-committer`
- :interrobang: `libgit-commit-create`
- :interrobang: `libgit-commit-create-buffer`
- :interrobang: `libgit-commit-create-from-callback`
- :interrobang: `libgit-commit-create-from-ids`
- :interrobang: `libgit-commit-create-v`
- :interrobang: `libgit-commit-create-with-signature`
- :interrobang: `libgit-commit-dup`
- :interrobang: `libgit-commit-extract-signature`
- :x: `libgit-commit-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-commit-header-field`
- :interrobang: `libgit-commit-id`
- :interrobang: `libgit-commit-lookup`
- :interrobang: `libgit-commit-lookup-prefix`
- :interrobang: `libgit-commit-message`
- :interrobang: `libgit-commit-message-encoding`
- :interrobang: `libgit-commit-message-raw`
- :interrobang: `libgit-commit-nth-gen-ancestor`
- :interrobang: `libgit-commit-owner`
- :interrobang: `libgit-commit-parent`
- :interrobang: `libgit-commit-parent-id`
- :interrobang: `libgit-commit-parentcount`
- :interrobang: `libgit-commit-raw-header`
- :interrobang: `libgit-commit-summary`
- :interrobang: `libgit-commit-time`
- :interrobang: `libgit-commit-time-offset`
- :interrobang: `libgit-commit-tree`
- :interrobang: `libgit-commit-tree-id`

### config

- :interrobang: `libgit-config-add-backend`
- :interrobang: `libgit-config-add-file-ondisk`
- :interrobang: `libgit-config-backend-foreach-match`
- :interrobang: `libgit-config-delete-entry`
- :interrobang: `libgit-config-delete-multivar`
- :x: `libgit-config-entry-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-config-find-global`
- :interrobang: `libgit-config-find-programdata`
- :interrobang: `libgit-config-find-system`
- :interrobang: `libgit-config-find-xdg`
- :interrobang: `libgit-config-foreach`
- :interrobang: `libgit-config-foreach-match`
- :x: `libgit-config-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-config-get-bool`
- :interrobang: `libgit-config-get-entry`
- :interrobang: `libgit-config-get-int32`
- :interrobang: `libgit-config-get-int64`
- :interrobang: `libgit-config-get-mapped`
- :interrobang: `libgit-config-get-multivar-foreach`
- :interrobang: `libgit-config-get-path`
- :interrobang: `libgit-config-get-string`
- :interrobang: `libgit-config-get-string-buf`
- :interrobang: `libgit-config-init-backend`
- :x: `libgit-config-iterator-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-config-iterator-glob-new`
- :interrobang: `libgit-config-iterator-new`
- :interrobang: `libgit-config-lock`
- :interrobang: `libgit-config-lookup-map-value`
- :interrobang: `libgit-config-multivar-iterator-new`
- :interrobang: `libgit-config-new`
- :interrobang: `libgit-config-next`
- :interrobang: `libgit-config-open-default`
- :interrobang: `libgit-config-open-global`
- :interrobang: `libgit-config-open-level`
- :interrobang: `libgit-config-open-ondisk`
- :interrobang: `libgit-config-parse-bool`
- :interrobang: `libgit-config-parse-int32`
- :interrobang: `libgit-config-parse-int64`
- :interrobang: `libgit-config-parse-path`
- :interrobang: `libgit-config-set-bool`
- :interrobang: `libgit-config-set-int32`
- :interrobang: `libgit-config-set-int64`
- :interrobang: `libgit-config-set-multivar`
- :interrobang: `libgit-config-set-string`
- :interrobang: `libgit-config-snapshot`

### cred

- :interrobang: `libgit-cred-default-new`
- :x: `libgit-cred-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-cred-has-username`
- :interrobang: `libgit-cred-ssh-custom-new`
- :interrobang: `libgit-cred-ssh-interactive-new`
- :interrobang: `libgit-cred-ssh-key-from-agent`
- :interrobang: `libgit-cred-ssh-key-memory-new`
- :interrobang: `libgit-cred-ssh-key-new`
- :interrobang: `libgit-cred-username-new`
- :interrobang: `libgit-cred-userpass`
- :interrobang: `libgit-cred-userpass-plaintext-new`

### describe

- :interrobang: `libgit-describe-commit`
- :interrobang: `libgit-describe-format`
- :interrobang: `libgit-describe-result-free`
- :interrobang: `libgit-describe-workdir`

### diff

- :interrobang: `libgit-diff-blob-to-buffer`
- :interrobang: `libgit-diff-blobs`
- :interrobang: `libgit-diff-buffers`
- :interrobang: `libgit-diff-commit-as-email`
- :interrobang: `libgit-diff-find-init-options`
- :interrobang: `libgit-diff-find-similar`
- :interrobang: `libgit-diff-foreach`
- :interrobang: `libgit-diff-format-email`
- :interrobang: `libgit-diff-format-email-init-options`
- :x: `libgit-diff-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-diff-from-buffer`
- :interrobang: `libgit-diff-get-delta`
- :interrobang: `libgit-diff-get-perfdata`
- :interrobang: `libgit-diff-get-stats`
- :interrobang: `libgit-diff-index-to-index`
- :interrobang: `libgit-diff-index-to-workdir`
- :interrobang: `libgit-diff-init-options`
- :interrobang: `libgit-diff-is-sorted-icase`
- :interrobang: `libgit-diff-merge`
- :interrobang: `libgit-diff-num-deltas`
- :interrobang: `libgit-diff-num-deltas-of-type`
- :interrobang: `libgit-diff-patchid`
- :interrobang: `libgit-diff-patchid-init-options`
- :interrobang: `libgit-diff-print`
- :interrobang: `libgit-diff-print-callback--to-buf`
- :interrobang: `libgit-diff-print-callback--to-file-handle`
- :interrobang: `libgit-diff-stats-deletions`
- :interrobang: `libgit-diff-stats-files-changed`
- :x: `libgit-diff-stats-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-diff-stats-insertions`
- :interrobang: `libgit-diff-stats-to-buf`
- :interrobang: `libgit-diff-status-char`
- :interrobang: `libgit-diff-to-buf`
- :interrobang: `libgit-diff-tree-to-index`
- :interrobang: `libgit-diff-tree-to-tree`
- :interrobang: `libgit-diff-tree-to-workdir`
- :interrobang: `libgit-diff-tree-to-workdir-with-index`

### fetch

- :interrobang: `libgit-fetch-init-options`

### filter

- :interrobang: `libgit-filter-init`
- :interrobang: `libgit-filter-list-apply-to-blob`
- :interrobang: `libgit-filter-list-apply-to-data`
- :interrobang: `libgit-filter-list-apply-to-file`
- :interrobang: `libgit-filter-list-contains`
- :x: `libgit-filter-list-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-filter-list-length`
- :interrobang: `libgit-filter-list-load`
- :interrobang: `libgit-filter-list-new`
- :interrobang: `libgit-filter-list-push`
- :interrobang: `libgit-filter-list-stream-blob`
- :interrobang: `libgit-filter-list-stream-data`
- :interrobang: `libgit-filter-list-stream-file`
- :interrobang: `libgit-filter-lookup`
- :interrobang: `libgit-filter-register`
- :interrobang: `libgit-filter-source-filemode`
- :interrobang: `libgit-filter-source-flags`
- :interrobang: `libgit-filter-source-id`
- :interrobang: `libgit-filter-source-mode`
- :interrobang: `libgit-filter-source-path`
- :interrobang: `libgit-filter-source-repo`
- :interrobang: `libgit-filter-unregister`

### giterr

Probably none of these functions will be necessary, since we expose errors to Emacs as signals.

- :x: `giterr-clear`
- :x: `giterr-last`
- :x: `giterr-set-oom`
- :x: `giterr-set-str`

### graph

- :interrobang: `libgit-graph-ahead-behind`
- :interrobang: `libgit-graph-descendant-of`

### hashsig

- :interrobang: `libgit-hashsig-compare`
- :interrobang: `libgit-hashsig-create`
- :interrobang: `libgit-hashsig-create-fromfile`
- :x: `libgit-hashsig-free` (memory management shouldn't be exposed to Emacs)

### ignore

- :heavy_check_mark: `libgit-ignore-add-rule`
- :heavy_check_mark: `libgit-ignore-clear-internal-rules`
- :heavy_check_mark: `libgit-ignore-path-is-ignored`

### index

- :interrobang: `libgit-index-add`
- :interrobang: `libgit-index-add-all`
- :interrobang: `libgit-index-add-bypath`
- :interrobang: `libgit-index-add-frombuffer`
- :interrobang: `libgit-index-caps`
- :interrobang: `libgit-index-checksum`
- :interrobang: `libgit-index-clear`
- :interrobang: `libgit-index-conflict-add`
- :interrobang: `libgit-index-conflict-cleanup`
- :interrobang: `libgit-index-conflict-get`
- :interrobang: `libgit-index-conflict-iterator-free`
- :interrobang: `libgit-index-conflict-iterator-new`
- :interrobang: `libgit-index-conflict-next`
- :interrobang: `libgit-index-conflict-remove`
- :interrobang: `libgit-index-entry-is-conflict`
- :interrobang: `libgit-index-entry-stage`
- :interrobang: `libgit-index-entrycount`
- :interrobang: `libgit-index-find`
- :interrobang: `libgit-index-find-prefix`
- :x: `libgit-index-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-index-get-byindex`
- :interrobang: `libgit-index-get-bypath`
- :interrobang: `libgit-index-has-conflicts`
- :interrobang: `libgit-index-new`
- :interrobang: `libgit-index-open`
- :interrobang: `libgit-index-owner`
- :interrobang: `libgit-index-path`
- :interrobang: `libgit-index-read`
- :interrobang: `libgit-index-read-tree`
- :interrobang: `libgit-index-remove`
- :interrobang: `libgit-index-remove-all`
- :interrobang: `libgit-index-remove-bypath`
- :interrobang: `libgit-index-remove-directory`
- :interrobang: `libgit-index-set-caps`
- :interrobang: `libgit-index-set-version`
- :interrobang: `libgit-index-update-all`
- :interrobang: `libgit-index-version`
- :interrobang: `libgit-index-write`
- :interrobang: `libgit-index-write-tree`
- :interrobang: `libgit-index-write-tree-to`

### indexer

- :interrobang: `libgit-indexer-append`
- :interrobang: `libgit-indexer-commit`
- :x: `libgit-indexer-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-indexer-hash`
- :interrobang: `libgit-indexer-new`

### libgit2

- :interrobang: `libgit-libgit2-features`
- :interrobang: `libgit-libgit2-init`
- :interrobang: `libgit-libgit2-opts`
- :interrobang: `libgit-libgit2-shutdown`
- :interrobang: `libgit-libgit2-version`

### mempack

- :interrobang: `libgit-mempack-dump`
- :interrobang: `libgit-mempack-new`
- :interrobang: `libgit-mempack-reset`

### merge

- :interrobang: `libgit-merge`
- :interrobang: `libgit-merge-analysis`
- :interrobang: `libgit-merge-base`
- :interrobang: `libgit-merge-base-many`
- :interrobang: `libgit-merge-base-octopus`
- :interrobang: `libgit-merge-bases`
- :interrobang: `libgit-merge-bases-many`
- :interrobang: `libgit-merge-commits`
- :interrobang: `libgit-merge-file`
- :interrobang: `libgit-merge-file-from-index`
- :interrobang: `libgit-merge-file-init-input`
- :interrobang: `libgit-merge-file-init-options`
- :interrobang: `libgit-merge-file-result-free`
- :interrobang: `libgit-merge-init-options`
- :interrobang: `libgit-merge-trees`

### message

- :interrobang: `libgit-message-prettify`
- :interrobang: `libgit-message-trailer-array-free`
- :interrobang: `libgit-message-trailers`

### note

- :interrobang: `libgit-note-author`
- :interrobang: `libgit-note-commit-create`
- :interrobang: `libgit-note-commit-iterator-new`
- :interrobang: `libgit-note-commit-read`
- :interrobang: `libgit-note-commit-remove`
- :interrobang: `libgit-note-committer`
- :interrobang: `libgit-note-create`
- :interrobang: `libgit-note-foreach`
- :x: `libgit-note-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-note-id`
- :interrobang: `libgit-note-iterator-free`
- :interrobang: `libgit-note-iterator-new`
- :interrobang: `libgit-note-message`
- :interrobang: `libgit-note-next`
- :interrobang: `libgit-note-read`
- :interrobang: `libgit-note-remove`

### object

- :x: `libgit-object--size` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-object-dup`
- :x: `libgit-object-free` (memory management shouldn't be exposed to Emacs)
- :heavy_check_mark: `libgit-object-id`
- :interrobang: `libgit-object-lookup`
- :interrobang: `libgit-object-lookup-bypath`
- :interrobang: `libgit-object-lookup-prefix`
- :interrobang: `libgit-object-owner`
- :interrobang: `libgit-object-peel`
- :heavy_check_mark: `libgit-object-short-id`
- :x: `libgit-object-string2type` (see below)
- :x: `libgit-object-type` (can be covered by a more general `libgit-typeof` for all opaque user pointers)
- :x: `libgit-object-type2string` (see above)
- :interrobang: `libgit-object-typeisloose`

### odb

- :interrobang: `libgit-odb-add-alternate`
- :interrobang: `libgit-odb-add-backend`
- :interrobang: `libgit-odb-add-disk-alternate`
- :interrobang: `libgit-odb-backend-loose`
- :interrobang: `libgit-odb-backend-one-pack`
- :interrobang: `libgit-odb-backend-pack`
- :interrobang: `libgit-odb-exists`
- :interrobang: `libgit-odb-exists-prefix`
- :interrobang: `libgit-odb-expand-ids`
- :interrobang: `libgit-odb-foreach`
- :x: `libgit-odb-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-odb-get-backend`
- :interrobang: `libgit-odb-hash`
- :interrobang: `libgit-odb-hashfile`
- :interrobang: `libgit-odb-init-backend`
- :interrobang: `libgit-odb-new`
- :interrobang: `libgit-odb-num-backends`
- :interrobang: `libgit-odb-object-data`
- :interrobang: `libgit-odb-object-dup`
- :x: `libgit-odb-object-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-odb-object-id`
- :interrobang: `libgit-odb-object-size`
- :interrobang: `libgit-odb-object-type`
- :interrobang: `libgit-odb-open`
- :interrobang: `libgit-odb-open-rstream`
- :interrobang: `libgit-odb-open-wstream`
- :interrobang: `libgit-odb-read`
- :interrobang: `libgit-odb-read-header`
- :interrobang: `libgit-odb-read-prefix`
- :interrobang: `libgit-odb-refresh`
- :interrobang: `libgit-odb-stream-finalize-write`
- :x: `libgit-odb-stream-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-odb-stream-read`
- :interrobang: `libgit-odb-stream-write`
- :interrobang: `libgit-odb-write`
- :interrobang: `libgit-odb-write-pack`

### oid

Probably none of these functions will be necessary, since we can expose OIDs to Emacs as strings.

- :x: `libgit-oid-cmp`
- :x: `libgit-oid-cpy`
- :x: `libgit-oid-equal`
- :x: `libgit-oid-fmt`
- :x: `libgit-oid-fromraw`
- :x: `libgit-oid-fromstr`
- :x: `libgit-oid-fromstrn`
- :x: `libgit-oid-fromstrp`
- :x: `libgit-oid-iszero`
- :x: `libgit-oid-ncmp`
- :x: `libgit-oid-nfmt`
- :x: `libgit-oid-pathfmt`
- :x: `libgit-oid-shorten-add`
- :x: `libgit-oid-shorten-free`
- :x: `libgit-oid-shorten-new`
- :x: `libgit-oid-strcmp`
- :x: `libgit-oid-streq`
- :x: `libgit-oid-tostr`
- :x: `libgit-oid-tostr-s`

### oidarray

- :x: `libgit-oidarray-free` (memory management shouldn't be exposed to Emacs)

### openssl

- :interrobang: `libgit-openssl-set-locking`

### packbuilder

- :interrobang: `libgit-packbuilder-foreach`
- :x: `libgit-packbuilder-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-packbuilder-hash`
- :interrobang: `libgit-packbuilder-insert`
- :interrobang: `libgit-packbuilder-insert-commit`
- :interrobang: `libgit-packbuilder-insert-recur`
- :interrobang: `libgit-packbuilder-insert-tree`
- :interrobang: `libgit-packbuilder-insert-walk`
- :interrobang: `libgit-packbuilder-new`
- :interrobang: `libgit-packbuilder-object-count`
- :interrobang: `libgit-packbuilder-set-callbacks`
- :interrobang: `libgit-packbuilder-set-threads`
- :interrobang: `libgit-packbuilder-write`
- :interrobang: `libgit-packbuilder-written`

### patch

- :x: `libgit-patch-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-patch-from-blob-and-buffer`
- :interrobang: `libgit-patch-from-blobs`
- :interrobang: `libgit-patch-from-buffers`
- :interrobang: `libgit-patch-from-diff`
- :interrobang: `libgit-patch-get-delta`
- :interrobang: `libgit-patch-get-hunk`
- :interrobang: `libgit-patch-get-line-in-hunk`
- :interrobang: `libgit-patch-line-stats`
- :interrobang: `libgit-patch-num-hunks`
- :interrobang: `libgit-patch-num-lines-in-hunk`
- :interrobang: `libgit-patch-print`
- :interrobang: `libgit-patch-size`
- :interrobang: `libgit-patch-to-buf`

### pathspec

- :x: `libgit-pathspec-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-pathspec-match-diff`
- :interrobang: `libgit-pathspec-match-index`
- :interrobang: `libgit-pathspec-match-list-diff-entry`
- :interrobang: `libgit-pathspec-match-list-entry`
- :interrobang: `libgit-pathspec-match-list-entrycount`
- :interrobang: `libgit-pathspec-match-list-failed-entry`
- :interrobang: `libgit-pathspec-match-list-failed-entrycount`
- :x: `libgit-pathspec-match-list-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-pathspec-match-tree`
- :interrobang: `libgit-pathspec-match-workdir`
- :interrobang: `libgit-pathspec-matches-path`
- :interrobang: `libgit-pathspec-new`

### proxy

- :interrobang: `libgit-proxy-init-options`

### push

- :interrobang: `libgit-push-init-options`

### rebase

- :interrobang: `libgit-rebase-abort`
- :interrobang: `libgit-rebase-commit`
- :interrobang: `libgit-rebase-finish`
- :x: `libgit-rebase-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-rebase-init`
- :interrobang: `libgit-rebase-init-options`
- :interrobang: `libgit-rebase-inmemory-index`
- :interrobang: `libgit-rebase-next`
- :interrobang: `libgit-rebase-open`
- :interrobang: `libgit-rebase-operation-byindex`
- :interrobang: `libgit-rebase-operation-current`
- :interrobang: `libgit-rebase-operation-entrycount`

### refdb

- :interrobang: `libgit-refdb-backend-fs`
- :interrobang: `libgit-refdb-compress`
- :x: `libgit-refdb-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-refdb-init-backend`
- :interrobang: `libgit-refdb-new`
- :interrobang: `libgit-refdb-open`
- :interrobang: `libgit-refdb-set-backend`

### reference

- :x: `libgit-reference--alloc` (in `sys`)
- :x: `libgit-reference--alloc-symbolic` (in `sys`)
- :interrobang: `libgit-reference-cmp`
- :heavy_check_mark: `libgit-reference-create`
- :heavy_check_mark: `libgit-reference-create-matching`
- :heavy_check_mark: `libgit-reference-delete`
- :heavy_check_mark: `libgit-reference-dup`
- :heavy_check_mark: `libgit-reference-dwim`
- :heavy_check_mark: `libgit-reference-ensure-log`
- :interrobang: `libgit-reference-foreach`
- :interrobang: `libgit-reference-foreach-glob`
- :interrobang: `libgit-reference-foreach-name`
- :x: `libgit-reference-free` (memory management shouldn't be exposed to Emacs)
- :heavy_check_mark: `libgit-reference-has-log`
- :heavy_check_mark: `libgit-reference-is-branch`
- :heavy_check_mark: `libgit-reference-is-note`
- :heavy_check_mark: `libgit-reference-is-remote`
- :heavy_check_mark: `libgit-reference-is-tag`
- :heavy_check_mark: `libgit-reference-is-valid-name`
- :interrobang: `libgit-reference-iterator-free`
- :interrobang: `libgit-reference-iterator-glob-new`
- :interrobang: `libgit-reference-iterator-new`
- :heavy_check_mark: `libgit-reference-list`
- :heavy_check_mark: `libgit-reference-lookup`
- :heavy_check_mark: `libgit-reference-name`
- :heavy_check_mark: `libgit-reference-name-to-id`
- :interrobang: `libgit-reference-next`
- :interrobang: `libgit-reference-next-name`
- :interrobang: `libgit-reference-normalize-name`
- :heavy_check_mark: `libgit-reference-owner`
- :heavy_check_mark: `libgit-reference-peel`
- :heavy_check_mark: `libgit-reference-remove`
- :interrobang: `libgit-reference-rename`
- :heavy_check_mark: `libgit-reference-resolve`
- :interrobang: `libgit-reference-set-target`
- :heavy_check_mark: `libgit-reference-shorthand`
- :interrobang: `libgit-reference-symbolic-create`
- :interrobang: `libgit-reference-symbolic-create-matching`
- :interrobang: `libgit-reference-symbolic-set-target`
- :heavy_check_mark: `libgit-reference-symbolic-target`
- :heavy_check_mark: `libgit-reference-target`
- :heavy_check_mark: `libgit-reference-target-peel`
- :heavy_check_mark: `libgit-reference-type`

### reflog

- :interrobang: `libgit-reflog-append`
- :interrobang: `libgit-reflog-delete`
- :interrobang: `libgit-reflog-drop`
- :interrobang: `libgit-reflog-entry-byindex`
- :interrobang: `libgit-reflog-entry-committer`
- :interrobang: `libgit-reflog-entry-id-new`
- :interrobang: `libgit-reflog-entry-id-old`
- :interrobang: `libgit-reflog-entry-message`
- :interrobang: `libgit-reflog-entrycount`
- :x: `libgit-reflog-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-reflog-read`
- :interrobang: `libgit-reflog-rename`
- :interrobang: `libgit-reflog-write`

### refspec

- :interrobang: `libgit-refspec-direction`
- :interrobang: `libgit-refspec-dst`
- :interrobang: `libgit-refspec-dst-matches`
- :interrobang: `libgit-refspec-force`
- :interrobang: `libgit-refspec-rtransform`
- :interrobang: `libgit-refspec-src`
- :interrobang: `libgit-refspec-src-matches`
- :interrobang: `libgit-refspec-string`
- :interrobang: `libgit-refspec-transform`

### remote

- :interrobang: `libgit-remote-add-fetch`
- :interrobang: `libgit-remote-add-push`
- :interrobang: `libgit-remote-autotag`
- :interrobang: `libgit-remote-connect`
- :interrobang: `libgit-remote-connected`
- :interrobang: `libgit-remote-create`
- :interrobang: `libgit-remote-create-anonymous`
- :interrobang: `libgit-remote-create-detached`
- :interrobang: `libgit-remote-create-with-fetchspec`
- :interrobang: `libgit-remote-default-branch`
- :interrobang: `libgit-remote-delete`
- :interrobang: `libgit-remote-disconnect`
- :interrobang: `libgit-remote-download`
- :interrobang: `libgit-remote-dup`
- :interrobang: `libgit-remote-fetch`
- :x: `libgit-remote-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-remote-get-fetch-refspecs`
- :interrobang: `libgit-remote-get-push-refspecs`
- :interrobang: `libgit-remote-get-refspec`
- :interrobang: `libgit-remote-init-callbacks`
- :interrobang: `libgit-remote-is-valid-name`
- :interrobang: `libgit-remote-list`
- :interrobang: `libgit-remote-lookup`
- :interrobang: `libgit-remote-ls`
- :interrobang: `libgit-remote-name`
- :interrobang: `libgit-remote-owner`
- :interrobang: `libgit-remote-prune`
- :interrobang: `libgit-remote-prune-refs`
- :interrobang: `libgit-remote-push`
- :interrobang: `libgit-remote-pushurl`
- :interrobang: `libgit-remote-refspec-count`
- :interrobang: `libgit-remote-rename`
- :interrobang: `libgit-remote-set-autotag`
- :interrobang: `libgit-remote-set-pushurl`
- :interrobang: `libgit-remote-set-url`
- :interrobang: `libgit-remote-stats`
- :interrobang: `libgit-remote-stop`
- :interrobang: `libgit-remote-update-tips`
- :interrobang: `libgit-remote-upload`
- :interrobang: `libgit-remote-url`

### repository

- :x: `libgit-repository--cleanup` (in `sys`)
- :heavy_check_mark: `libgit-repository-commondir`
- :interrobang: `libgit-repository-config`
- :interrobang: `libgit-repository-config-snapshot`
- :heavy_check_mark: `libgit-repository-detach-head`
- :interrobang: `libgit-repository-discover`
- :interrobang: `libgit-repository-fetchhead-foreach`
- :x: `libgit-repository-free` (memory management shouldn't be exposed to Emacs)
- :heavy_check_mark: `libgit-repository-get-namespace`
- :interrobang: `libgit-repository-hashfile`
- :heavy_check_mark: `libgit-repository-head`
- :heavy_check_mark: `libgit-repository-head-detached`
- :heavy_check_mark: `libgit-repository-head-for-worktree`
- :heavy_check_mark: `libgit-repository-head-unborn`
- :heavy_check_mark: `libgit-repository-ident`
- :interrobang: `libgit-repository-index`
- :heavy_check_mark: `libgit-repository-init`
- :interrobang: `libgit-repository-init-ext`
- :interrobang: `libgit-repository-init-init-options`
- :heavy_check_mark: `libgit-repository-is-bare`
- :heavy_check_mark: `libgit-repository-is-empty`
- :heavy_check_mark: `libgit-repository-is-shallow`
- :heavy_check_mark: `libgit-repository-is-worktree`
- :interrobang: `libgit-repository-item-path`
- :interrobang: `libgit-repository-mergehead-foreach`
- :heavy_check_mark: `libgit-repository-message`
- :heavy_check_mark: `libgit-repository-message-remove`
- :x: `libgit-repository-new` (in `sys`)
- :interrobang: `libgit-repository-odb`
- :heavy_check_mark: `libgit-repository-open`
- :heavy_check_mark: `libgit-repository-open-bare`
- :interrobang: `libgit-repository-open-ext`
- :interrobang: `libgit-repository-open-from-worktree`
- :heavy_check_mark: `libgit-repository-path`
- :interrobang: `libgit-repository-refdb`
- :x: `libgit-repository-reinit-filesystem` (in `sys`)
- :x: `libgit-repository-set-bare` (in `sys`)
- :x: `libgit-repository-set-config` (in `sys`)
- :heavy_check_mark: `libgit-repository-set-head`
- :heavy_check_mark: `libgit-repository-set-head-detached`
- :interrobang: `libgit-repository-set-head-detached-from-annotated`
- :heavy_check_mark: `libgit-repository-set-ident`
- :interrobang: `libgit-repository-set-index`
- :heavy_check_mark: `libgit-repository-set-namespace`
- :interrobang: `libgit-repository-set-odb`
- :interrobang: `libgit-repository-set-refdb`
- :heavy_check_mark: `libgit-repository-set-workdir`
- :heavy_check_mark: `libgit-repository-state`
- :heavy_check_mark: `libgit-repository-state-cleanup`
- :x: `libgit-repository-submodule-cache-all` (in `sys`)
- :x: `libgit-repository-submodule-cache-clear` (in `sys`)
- :heavy_check_mark: `libgit-repository-workdir`
- :interrobang: `libgit-repository-wrap-odb`

### reset

- :interrobang: `libgit-reset`
- :interrobang: `libgit-reset-default`
- :interrobang: `libgit-reset-from-annotated`

### revert

- :interrobang: `libgit-revert`
- :interrobang: `libgit-revert-commit`
- :interrobang: `libgit-revert-init-options`

### revparse

- :interrobang: `libgit-revparse`
- :interrobang: `libgit-revparse-ext`
- :heavy_check_mark: `libgit-revparse-single`

### revwalk

- :interrobang: `libgit-revwalk-add-hide-cb`
- :x: `libgit-revwalk-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-revwalk-hide`
- :interrobang: `libgit-revwalk-hide-glob`
- :interrobang: `libgit-revwalk-hide-head`
- :interrobang: `libgit-revwalk-hide-ref`
- :interrobang: `libgit-revwalk-new`
- :interrobang: `libgit-revwalk-next`
- :interrobang: `libgit-revwalk-push`
- :interrobang: `libgit-revwalk-push-glob`
- :interrobang: `libgit-revwalk-push-head`
- :interrobang: `libgit-revwalk-push-range`
- :interrobang: `libgit-revwalk-push-ref`
- :interrobang: `libgit-revwalk-repository`
- :interrobang: `libgit-revwalk-reset`
- :interrobang: `libgit-revwalk-simplify-first-parent`
- :interrobang: `libgit-revwalk-sorting`

### signature

- :interrobang: `libgit-signature-default`
- :interrobang: `libgit-signature-dup`
- :x: `libgit-signature-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-signature-from-buffer`
- :interrobang: `libgit-signature-new`
- :interrobang: `libgit-signature-now`

### smart

- :interrobang: `libgit-smart-subtransport-git`
- :interrobang: `libgit-smart-subtransport-http`
- :interrobang: `libgit-smart-subtransport-ssh`

### stash

- :interrobang: `libgit-stash-apply`
- :interrobang: `libgit-stash-apply-init-options`
- :interrobang: `libgit-stash-drop`
- :interrobang: `libgit-stash-foreach`
- :interrobang: `libgit-stash-pop`

### status

- :interrobang: `libgit-status-byindex`
- :heavy_check_mark: `libgit-status-file`
- :heavy_check_mark: `libgit-status-foreach`
- :heavy_check_mark: `libgit-status-foreach-ext`
- :x: `libgit-status-init-options`
- :interrobang: `libgit-status-list-entrycount`
- :interrobang: `libgit-status-list-free`
- :interrobang: `libgit-status-list-get-perfdata`
- :interrobang: `libgit-status-list-new`
- :heavy_check_mark: `libgit-status-should-ignore`

### strarray

- :x: `libgit-strarray-copy`
- :x: `libgit-strarray-free` (memory management shouldn't be exposed to Emacs)

### stream

- :interrobang: `libgit-stream-register-tls`

### submodule

- :interrobang: `libgit-submodule-add-finalize`
- :interrobang: `libgit-submodule-add-setup`
- :interrobang: `libgit-submodule-add-to-index`
- :interrobang: `libgit-submodule-branch`
- :interrobang: `libgit-submodule-fetch-recurse-submodules`
- :interrobang: `libgit-submodule-foreach`
- :x: `libgit-submodule-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-submodule-head-id`
- :interrobang: `libgit-submodule-ignore`
- :interrobang: `libgit-submodule-index-id`
- :interrobang: `libgit-submodule-init`
- :interrobang: `libgit-submodule-location`
- :interrobang: `libgit-submodule-lookup`
- :interrobang: `libgit-submodule-name`
- :interrobang: `libgit-submodule-open`
- :interrobang: `libgit-submodule-owner`
- :interrobang: `libgit-submodule-path`
- :interrobang: `libgit-submodule-reload`
- :interrobang: `libgit-submodule-repo-init`
- :interrobang: `libgit-submodule-resolve-url`
- :interrobang: `libgit-submodule-set-branch`
- :interrobang: `libgit-submodule-set-fetch-recurse-submodules`
- :interrobang: `libgit-submodule-set-ignore`
- :interrobang: `libgit-submodule-set-update`
- :interrobang: `libgit-submodule-set-url`
- :interrobang: `libgit-submodule-status`
- :interrobang: `libgit-submodule-sync`
- :interrobang: `libgit-submodule-update`
- :interrobang: `libgit-submodule-update-init-options`
- :interrobang: `libgit-submodule-update-strategy`
- :interrobang: `libgit-submodule-url`
- :interrobang: `libgit-submodule-wd-id`

### tag

- :interrobang: `libgit-tag-annotation-create`
- :interrobang: `libgit-tag-create`
- :interrobang: `libgit-tag-create-frombuffer`
- :interrobang: `libgit-tag-create-lightweight`
- :interrobang: `libgit-tag-delete`
- :interrobang: `libgit-tag-dup`
- :interrobang: `libgit-tag-foreach`
- :x: `libgit-tag-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-tag-id`
- :interrobang: `libgit-tag-list`
- :interrobang: `libgit-tag-list-match`
- :interrobang: `libgit-tag-lookup`
- :interrobang: `libgit-tag-lookup-prefix`
- :interrobang: `libgit-tag-message`
- :interrobang: `libgit-tag-name`
- :interrobang: `libgit-tag-owner`
- :interrobang: `libgit-tag-peel`
- :interrobang: `libgit-tag-tagger`
- :interrobang: `libgit-tag-target`
- :interrobang: `libgit-tag-target-id`
- :interrobang: `libgit-tag-target-type`

### time

- :interrobang: `libgit-time-monotonic`

### trace

- :interrobang: `libgit-trace-set`

### transport

- :interrobang: `libgit-transport-dummy`
- :interrobang: `libgit-transport-init`
- :interrobang: `libgit-transport-local`
- :interrobang: `libgit-transport-new`
- :interrobang: `libgit-transport-register`
- :interrobang: `libgit-transport-smart`
- :interrobang: `libgit-transport-smart-certificate-check`
- :interrobang: `libgit-transport-smart-credentials`
- :interrobang: `libgit-transport-smart-proxy-options`
- :interrobang: `libgit-transport-ssh-with-paths`
- :interrobang: `libgit-transport-unregister`

### tree

- :interrobang: `libgit-tree-create-updated`
- :interrobang: `libgit-tree-dup`
- :interrobang: `libgit-tree-entry-byid`
- :interrobang: `libgit-tree-entry-byindex`
- :interrobang: `libgit-tree-entry-byname`
- :interrobang: `libgit-tree-entry-bypath`
- :interrobang: `libgit-tree-entry-cmp`
- :interrobang: `libgit-tree-entry-dup`
- :interrobang: `libgit-tree-entry-filemode`
- :interrobang: `libgit-tree-entry-filemode-raw`
- :interrobang: `libgit-tree-entry-free`
- :interrobang: `libgit-tree-entry-id`
- :interrobang: `libgit-tree-entry-name`
- :interrobang: `libgit-tree-entry-to-object`
- :interrobang: `libgit-tree-entry-type`
- :interrobang: `libgit-tree-entrycount`
- :x: `libgit-tree-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-tree-id`
- :interrobang: `libgit-tree-lookup`
- :interrobang: `libgit-tree-lookup-prefix`
- :interrobang: `libgit-tree-owner`
- :interrobang: `libgit-tree-walk`

### treebuilder

- :interrobang: `libgit-treebuilder-clear`
- :interrobang: `libgit-treebuilder-entrycount`
- :interrobang: `libgit-treebuilder-filter`
- :x: `libgit-treebuilder-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-treebuilder-get`
- :interrobang: `libgit-treebuilder-insert`
- :interrobang: `libgit-treebuilder-new`
- :interrobang: `libgit-treebuilder-remove`
- :interrobang: `libgit-treebuilder-write`
- :interrobang: `libgit-treebuilder-write-with-buffer`

### worktree

- :interrobang: `libgit-worktree-add`
- :interrobang: `libgit-worktree-add-init-options`
- :x: `libgit-worktree-free` (memory management shouldn't be exposed to Emacs)
- :interrobang: `libgit-worktree-is-locked`
- :interrobang: `libgit-worktree-is-prunable`
- :interrobang: `libgit-worktree-list`
- :interrobang: `libgit-worktree-lock`
- :interrobang: `libgit-worktree-lookup`
- :interrobang: `libgit-worktree-open-from-repository`
- :interrobang: `libgit-worktree-prune`
- :interrobang: `libgit-worktree-prune-init-options`
- :interrobang: `libgit-worktree-unlock`
- :interrobang: `libgit-worktree-validate`
