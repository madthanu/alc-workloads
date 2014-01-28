Introduction
------------

With Git, many workloads can be tested for bugs, and many correctness checks can be performed. I tested for a simple workload: in a pre-existing repository with some existing files, the workload did a 'git add' of two files, followed by a 'git commit'. It is possible that many more bugs exist with other workloads, but I believe they will follow the same pattern as the discovered bugs.

Git has a configuration option called 'core.fsyncobjectfiles'. This option is switched off by default. Without this option, Git mostly does not perform any syncing operation; in the workload considered, git never syncs without this option. For finding bugs, the workload was run with this option switched on.

Aside: In Git, there is a problem in separating durability and consistency. The usual definition of consistency, as with other applications, would be that previous commits are retrievable, even if the last few commits are not. However, consider the situation where the user commits to git, then rewrites actual code files; if the last commit was not 'durable', the repository might be left in a state where the code files are updated, but the last commit is lost silently.

The emails listed next (from the Git mailing list) provide information on developer assumptions and opinions about system crash recovery in Git. The description of 'core.fsyncobjectfiles' in the manpage of 'git-config' also provides information.

* http://marc.info/?l=git&m=124839484917965&w=2
* http://marc.info/?l=git&m=137489462314389&w=2
* http://marc.info/?l=git&m=133573931013962&w=2

Developer assumptions and opinions
----------------------------------

* Git should work correctly on any file system that orders meta-data and data writes, even without 'core.fsyncobjectfiles'. For file systems that do not maintain order, switching on the fsyncs is a good idea, even though the state is "often" recoverable *manually* (i.e., by a git developer-expert) even if the fsyncs are not switched on.

  From my experiments, I believe that, except for issue (1) described in the subsequent paragraphs, the former assumption is entirely correct (ordering file system doesn't need 'core.fsyncobjectfiles'). The second assumption would be correct, for common non-reordering filesystems, if we define "recovery" to recover only to a consistent state, without considering durability - git does not delete old old object files, so if the last commit is screwed up, manual recovery to the previous commit is always possible. Jeff King correctly guesses possible errors that might happen in a common re-ordering file system.

  However, for non common re-ordering file systems, even manual recovery might not be possible, since Git appends to certain meta-information logs (such as './git/logs/HEAD') and overwrites some meta-information pointer files (such as '.git/refs/heads/master'); crazy file systems might even leave the entire contents of these file as garbage when they are being edited. (I assume you have a sensible notion of recovery; deleting the entire repository to get a "consistent" but empty repository, is BS.)

* From the manpage description of core.fsyncobjectfiles, and a mail from the mailing list, I believe Torvalds (during 2009) had the following opinion about the term 'journaled file systems': journaling maintains ordering.  I have encountered similar definitions of 'journaled file systems' from my interaction with the LevelDB developer community. It will be interesting to know whether file system developers or researchers agree with this.

* The manpage entry for 'core.fsyncobjectfiles' seems to assume that the user knows the behavior of the underlying file system (akin to knowledge necessary for SQLite config options). While core.fsyncobjectfiles is not necessary for ext3-ordered, it is needed for automatic recovery in ext4, btrfs, and probably most other modern file systems; even manual recovery of the last commit is not possible with the option switched off. Torvalds is hopefully aware of this, but there doesn't seem to be any e-mail in the mailing list that discusses the issue (in the post-2009 era), and the option is still switched off by default.

Issues
------

1. In the tested workload, Git first appends some data to the end of a file (".git/logs/HEAD"), and then renames a file(".git/refs/heads/master.lock" -> ".git/refs/heads/master"). The former operation (append) will typically not result in more blocks being added to the file; only about 128 bytes are appended. The rename is part of an atomic file content replacement sequence for the "...master" file; the creation and write to the temporary file ('master.lock') for the file content replacement, happens before the append operation talked about previously.

   For correct operation, both the rename and the append has to be atomic. Correctness is affected (seemingly, as described next) if either only the rename or only the append ends up on disk (or when the append partially gets to disk). This would, of course, mean that correctness will also be affected if the process gets killed (i.e., without a system crash) after the append and before the rename; however, the time window for such a kill is small. With a file system that decides to buffer either the rename or the append, but sends the other operation immediately to disk, the time window (of a system crash that affects correctness) will be considerable.

   If the the rename does not occur, but the append does, git reports (on the next git operation, after reboot in the case of a system crash) the existence of the 'master.lock' file, and refuses to continue. However, the user is told that 'master.lock' exists probably because another git process is running simultaneously; if the user is sure that another process is not running, the file should be removed, and git can continue. I tested for correctness after removing the master.lock file.

   If the operation is not atomic, git ref-log shows wrong meta-information (without reporting any corruption), but other tested correctness checks did not report any problems (except the master.lock indication). I do not know the seriousness of this bug, though silently giving wrong meta-information is ominous.

   I believe (haven't tested yet) that this bug would practically occur on Btrfs, and may be on Ext4-ordered. Btrfs forces renames to disk immediately, while the append might still be buffered. With Ext4-ordered, delayed allocation might have a similar effect; however, I do not know delayed allocation's effects when file size is increased without allocating newer blocks.

   1. There is also another file (".git/logs/refs/heads/master") that is appended before the rename of 'master.lock'. I tried re-ordering this file before or after the rename, but there was no effect on any of the tested correctness checks; probably indicates we can use more correctness checks.

2. There are two atomic file replacement sequences in the tested workloads (".git/index.lock" -> ".git/index", and ".git/refs/heads/master.lock" -> ".git/refs/heads/master"). Neither of these fsync the appropriate file data before the rename. 

   If the file data does not get to disk (i.e., the file is empty or contains garbage), a lot of corruption is reported.

   The bug would happen on any file system not considering the creat()->write()->rename() file replacement sequence.

3. Before each of the atomic file *replacement* scenarios described in (2), Git does additional atomic *file creations* (for a few files) using the following protocol: Git creates a temporary file, fills the temporary file with data, does an fsync() on the temporary file, then link()-s the temporary files to permanent-file-names. The permanent file names will be referred to (indirectly) by pointers written to the atomically *replaced* file from (2). (By file *creation*, I mean, the permanent file names, i.e., the destinations in the link() calls, do not previously exist).  After the link, the temporary files are unlink()-ed.

   For correct operation, the link() of the file creations must go to disk before the rename() of the file replacement does. If this does not happen for the 'master.lock' file's rename in (2), lots of corruption are reported. If it does not happen for 'index.lock', a missing blob error is reported by 'git fsck', but there is non-deterministic behavior for the rest of the correctness checks. Most of the times, other correctness checks don't report anything wrong; however, sometimes, they do. (More specifically, 'git rm' reports 'invalid object for fileX, error building trees').

   Note that, curiosly, there was no system-crash-specific necessity for the file creation to be done using the tempfile-link() sequence. So long as the rename() does not go to disk, it wouldn't matter if the linked-file was half written, or filled with garbage. Specifically, things wouldn't be any different in a file system with a non-atomic link() call (if the call leaves the file in a half-written state). I believe the link() call was used to prevent simultaneously-active git processes from performing 'git-commit' at the same time; link() can be used to detect if another active process raced and created the object file.

  This bug might be exposed under Btrfs.

4. In the workload, Git creates and renames two files ('index.lock' and 'master.lock'). The first rename ('index.lock') is part of 'git add', while the second rename is part of 'git commit'. 'git add' and 'git commit' together constitute the tested workload.

   If the first rename does not go to the disk, but the second does, git's staging index is in a funny, but usable state; the stage looks like an invisible ghost did an additional 'git rm --cached' on files added using 'git add' previously. However, the final commit done using 'git commit' remains the same. I do not know the seriousness of this bug.

   I believe this bug will not be exposed under any of our currently studied file systems.

5. Consider the temporary files created, and then link()-ed under a permanent name in (3). Git creates one new directory corresponding to each of these files, and then puts the temporary file (and the corresponding permanent file too) in that new directory. The directories are created using mkdir().

   For correct operation, the mkdir() must persist (similar to the link()) before the corresponding renames. For this to happen, I believe Linux requires doing an fsync() on the parent directory.

   If the mkdir() does not get persisted before the corresponding rename, the same effects as link() not being persisted in (3), will happen.

   I believe this bug will not be exposed under any of our currently studied file systems.

   1. Git also never does an fsync() on a newly created file. However, since all newly created files (that we observe in the tested workload) are temporary files that will subsequently be link()-ed or rename()-ed to a permanent file, only the link() or the rename() might need to be fsync()-ed.

6. Beyond a final rename call, Git does not perform any sync operation. This will give delayed durability, typically after 5 seconds or 30 seconds. However, some file systems might decide to prevent durability for a longer time.
