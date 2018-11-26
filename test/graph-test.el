(ert-deftest ahead-behind ()
  (let (c1 c2 c3 c4 c5 c6 c7)
    (with-temp-dir path
      (init)
      (commit-change "a" "1")
      (setq c1 (rev-parse))
      (run "git" "checkout" "-b" "branch")
      (commit-change "a" "2")
      (setq c2 (rev-parse))
      (commit-change "a" "3")
      (setq c3 (rev-parse))
      (commit-change "a" "4")
      (setq c4 (rev-parse))
      (run "git" "checkout" "master")
      (commit-change "a" "5")
      (setq c5 (rev-parse))
      (commit-change "a" "6")
      (setq c6 (rev-parse))
      (commit-change "a" "7")
      (setq c7 (rev-parse))
      (let* ((repo (libgit-repository-open path)))
        (should (equal '(0 . 0) (libgit-graph-ahead-behind repo c1 c1)))
        (should (equal '(1 . 0) (libgit-graph-ahead-behind repo c2 c1)))
        (should (equal '(2 . 0) (libgit-graph-ahead-behind repo c3 c1)))
        (should (equal '(3 . 0) (libgit-graph-ahead-behind repo c4 c1)))
        (should (equal '(0 . 1) (libgit-graph-ahead-behind repo c1 c2)))
        (should (equal '(0 . 2) (libgit-graph-ahead-behind repo c1 c3)))
        (should (equal '(0 . 3) (libgit-graph-ahead-behind repo c1 c4)))
        (should (equal '(3 . 1) (libgit-graph-ahead-behind repo c4 c5)))
        (should (equal '(3 . 2) (libgit-graph-ahead-behind repo c4 c6)))
        (should (equal '(3 . 3) (libgit-graph-ahead-behind repo c4 c7)))))))

(ert-deftest descendant-p ()
  (let (c1 c2 c3 c4 c5 c6 c7)
    (with-temp-dir path
      (init)
      (commit-change "a" "1")
      (setq c1 (rev-parse))
      (run "git" "checkout" "-b" "branch")
      (commit-change "a" "2")
      (setq c2 (rev-parse))
      (commit-change "a" "3")
      (setq c3 (rev-parse))
      (commit-change "a" "4")
      (setq c4 (rev-parse))
      (run "git" "checkout" "master")
      (commit-change "a" "5")
      (setq c5 (rev-parse))
      (commit-change "a" "6")
      (setq c6 (rev-parse))
      (commit-change "a" "7")
      (setq c7 (rev-parse))
      (let* ((repo (libgit-repository-open path)))
        (should (libgit-graph-descendant-p repo c2 c1))
        (should-not (libgit-graph-descendant-p repo c1 c3))
        (should (libgit-graph-descendant-p repo c4 c2))
        (should-not (libgit-graph-descendant-p repo c7 c2))
        (should-not (libgit-graph-descendant-p repo c2 c7))))))