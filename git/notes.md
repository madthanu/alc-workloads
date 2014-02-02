Introduction
------------

Git provides many commands that can be used on a code repository; thus, many workloads can be tested for bugs, and many correctness checks can be performed. I tested for a simple workload: in a pre-existing repository with some existing files, the workload did a 'git add' of two files, followed by a 'git commit'. The workload and correctness checks used are described in detail in subsequent sections. It is possible that more bugs exist with other workloads, but I am guessing about 50% of the total bugs in git will follow the same pattern as the discovered bugs.

Git has a configuration option called 'core.fsyncobjectfiles'. This option is switched off by default. Without this option, Git mostly does not perform any sync()-like operation; in the workload considered, git never syncs without this option. For finding bugs, the workload was run with this option switched on.

**Unofficial ALC guarantee (as told by Git developers):** Git should work correctly on any file system that orders meta-data and data writes, even without 'core.fsyncobjectfiles'. For file systems that do not maintain order, switching on the fsyncs is a good idea, even though the state is "often" recoverable *manually* (i.e., by a git developer-expert) even if the syncs are not switched on. (These 'unofficial guarantees were obtained from some emails listed in subsequent sections.)

Developer assumptions and opinions
----------------------------------

* I find from my experiments that, except for issue (1) described in the subsequent paragraphs, the former assumption (ordering file system doesn't need 'core.fsyncobjectfiles') is entirely correct. The second assumption would be correct, for *common* non-reordering filesystems, if we define "recovery" to recover only to a consistent state (without considering durability) - git does not delete old old object files, so if the last commit is corrupted, manual recovery to the previous commit is possible. Jeff King (a Git developer) correctly guesses possible errors that might happen in a common re-ordering file system.

  However, for non common re-ordering file systems, even manual recovery might not be possible, since Git appends to certain meta-information logs (such as './git/logs/HEAD') and overwrites some meta-information pointer files (such as '.git/refs/heads/master'); crazy file systems might even leave the entire contents of these file as garbage when they are being edited. (I assume you have a sensible notion of recovery; deleting the entire repository to get a "consistent" but empty repository, is BS.)

The emails listed next (from the Git mailing list) provide information on developer assumptions and opinions about system crash recovery in Git. The description of 'core.fsyncobjectfiles' in the manpage of 'git-config' also provides information.

* http://marc.info/?l=git&m=124839484917965&w=2
* http://marc.info/?l=git&m=137489462314389&w=2
* http://marc.info/?l=git&m=133573931013962&w=2

* **Opinion on the term 'journaled file systems'**: From the manpage description of core.fsyncobjectfiles, and a 2009 email by Torvalds, the following opinion seems to be expressed: journaling maintains (system-call level) ordering.  I have encountered similar definitions of 'journaled file systems' from my interaction with the LevelDB developer community. Also, the apparent reason data ordering cannot be relied upon, in normal journaling file systems, is because they don't provide data journaling, but only metadata journaling. It will be interesting to know whether file system developers or researchers agree with this. I'm unsure whether application developers consider Btrfs as a journaling file system.

* The manpage entry for 'core.fsyncobjectfiles' seems to assume that the user knows the behavior of the underlying file system (akin to knowledge necessary for SQLite config options). While core.fsyncobjectfiles is not necessary for ext3-ordered, it is needed for automatic recovery in ext4, btrfs, and probably most other modern file systems; even manual recovery of the last commit is not possible with the option switched off. Torvalds is hopefully aware of this, but there doesn't seem to be any e-mail in the mailing list that discusses the issue (in the post-2009 era), and the option is still switched off by default.

Issues
------

1. In the tested workload, Git first appends some data to the end of a file, and then renames another file. For correct operation, both the rename and the append has to be atomic.

   *Details:* The appended file is ".git/logs/HEAD", and the rename is (".git/refs/heads/master.lock" -> ".git/refs/heads/master"). The former operation (append) will typically not result in more blocks being added to the file; only about 128 bytes are appended. The rename is part of an atomic overwrite sequence for the "...master" file; the creation and write to the temporary file ('master.lock') happens before the previous append of ".git/logs/HEAD". I believe that the developers intended to do the append in an isolated (i.e., atomic wrt other processes) fashion, and use the temporary file 'master.lock' as a lock for the purpose. (Thus, 'master.lock' serves two purposes: temporary file, and a lock.)

   Correctness is affected if either only the rename or only the append ends up on disk (or when the append partially gets to disk). This would, of course, mean that correctness will also be affected if the process gets killed (i.e., without a system crash) after the append and before the rename; however, the time window that affects correctness during such such a kill is small. When a file system decides to buffer either the rename or the append, but sends the other operation immediately to disk, the time window will be considerable.

   *Consequence:* If the bug occurs, the 'git ref-log' command shows wrong meta-information about the repository. Other tested correctness checks did not report any problems (except master.lock existence). I do not know the seriousness of this bug, though silently giving wrong meta-information is ominous.

   In the specific case where the append ends up in the disk before the rename (and a crash happens between), for certain checks other than 'git ref-log', Git reports the existence of the 'master.lock' file and refuses to continue. However, the user is told that 'master.lock' exists probably because another git process is running simultaneously; if the user is sure that another process is not running, the file should be removed, and Git can continue. Removing the master.lock file results in those checks working correctly (again, 'git ref-log' still reports wrong meta information, always).

   *Exposed in actual file systems?* I believe (haven't tested yet) that this bug would practically occur on Btrfs, and may be on Ext4-ordered. Btrfs forces renames to disk immediately, while the append might still be buffered. With Ext4-ordered, delayed allocation might have a similar effect; however, I do not know delayed allocation's effects when file size is increased without allocating newer blocks.

   *Note:* There is also another file (".git/logs/refs/heads/master") that is appended in an isolated fashion, before the rename of 'master.lock'. I tried re-ordering this file before or after the rename, but there was no effect on any of the tested correctness checks; probably indicates we can use more correctness checks.

2. There are two atomic overwrite sequences in the tested workloads. Neither of these fsync() the appropriate file data before the rename. Data needs to be ordered before the renames for correctness.

   *Details:* The renames are (".git/index.lock" -> ".git/index"), and (".git/refs/heads/master.lock" -> ".git/refs/heads/master"). 

   *Consequence:* A lot of corruption is reported.

   *Exposed in actual file systems?* No, as far as we know.

3. In a few situations, Git first does a link(), then atomically overwrites another file using rename(). There is no fsync() between the link and the rename. However, for correct operations, the link() needs to reach the disk first before the rename.

   *Details:* Before each of the atomic file *overwrite* scenarios described in issue (2), Git does additional atomic file *creations* (two file creations per overwrite) using the following protocol: Git creates a temporary file, fills the temporary file with data, does an fsync() on the temporary file, then link()-s the temporary files to permanent-file-names. The permanent file names are (I'm guessing) referred by the overwritten data (written to the renamed file). (By file *creation*, I mean, the permanent file names, i.e., the destinations in the link() calls, do not previously exist).  After the link, the temporary files are unlink()-ed.

   *Consequence:* The consequence of the bug is different for the two overwritten files. For the overwrite of 'master.lock', if either of the two corresponding links do not get to disk, lots of corruption are reported. For 'index.lock', a missing blob error is reported by 'git fsck', but there is non-deterministic behavior for other correctness checks ('git rm', depending on its mood, might report 'invalid object for fileX, error building trees').

   *Note:* As far as I can understand, the tempfile-link() sequence does not help in any way with system-crash-specific consistency guarantees. The only requirement that Git needs for system-crash guarantees, is that both the data of the created files, and the (permanent) name of the file, are fully in disk before the rename() call. This could have been achieved by directly creating a file under the permanent file name, writing the new data to it, and then doing an fsync() on the created file (plus, taking care of safe new file flush). I am guessing (from some of the emails listed in subsequent sections) the link() call was used to prevent simultaneously-active git processes from performing operations at the same time. This also explains why link() is used instead of rename(): link() can detect if another active process raced and created the file first.

   *Exposed in actual file systems?* This bug will probably be exposed under Btrfs (haven't tested yet).

4. In the workload, Git creates and renames two files. The first rename should go to disk first before the second rename.

   *Details:* The first rename ('index.lock') is part of 'git add', while the second rename ('master.lock') is part of 'git commit'.

   *Consequence:* Git's staging index is in a funny, but usable state; the stage looks like some ghost did an additional 'git rm --cached' on those files previously added using 'git add'. Everything else works properly. I do not know about the seriousness of this bug.

   *Note:* The rename of 'index.lock' is done first, as part of 'git add'. However, as the first step 'git commit', 'index.lock' is created and then immediately unlinked. I do not understand why git commit does this. My best guess is that, during 'git commit',  Git checks for the existence of 'index.lock' (i.e., whether the create call succeeds), and then proceeds only if the lock doesn't exist (we are talking about the workload phase here, before any crashes, so the rename() call of 'git add' would make sure that the lock does not exist). When a crash happens, if only the rename of 'index.lock' does not go to the disk (the create and unlink did end up in the disk), then the consequence described in the previous paragraph would directly result. However, if the create and the unlink are also lost, Git will indicate the existence of 'index.lock' with certain checks, similar to issue (1).

   *Exposed in actual file systems?* No, as far as we know.

5. The workload involves a few mkdir()-s, and then file creations within the new directory. The parent directory of the mkdir() needs to be fsync()-ed for correctness. (Safe new file flush for directories).

   *Details:* Consider the temporary files created, and then link()-ed under a permanent name in issue (3). Git creates one new directory corresponding to each of these files (using mkdir() ), and then puts the temporary file (and the corresponding permanent file too) in that new directory. For correct operation, the mkdir() must persist (similar to the link()) before the corresponding renames. For this to happen, I believe Linux requires doing an fsync() on the parent directory.

   Note that, for the file creation itself, safe new file flush is not specifically a problem: the required fsync() after the link() would also cover the creation of the file. (Of course, that required fsync() is also not present in Git, as detailed in issue 3.)
 
   *Consequence:* The same as link() not being persisted in issue (3).

   *Exposed in actual file systems?* No, as far as we know.

6. Beyond a final rename call, Git does not perform any sync operation. This will only give delayed durability, typically after 5 seconds or 30 seconds. Some file systems might decide to prevent durability for a longer time.

   *Note:* In Git, there is a problem in separating durability and consistency. The usual definition of consistency, as in other applications, would be that previous commits are retrievable, even if the last few commits are not. However, consider the situation where the user commits to git, then rewrites actual code files; if the last commit was not durable, the repository might be left in a state where the code files are updated, but the last commit is lost silently.

7. There are four files in total that Git creates using the *create(tmp); write(tmp); fsync(tmp); link(tmp->permanent);* sequence. The fsync() is left out by default, and requires the core.fsyncobjectfiles option. If the fsync() is left out, correctness is affected.

   *Details:* Two link()-creations correspond to each of the two renames in the workload. If the renames get to the disk before the data of the created files, various errors are produced.

   *Consequence:* If the data of either of the two files corresponding to the first rename are not persisted, but the rename ends up in disk, different errors occur depending on which parts of the files end up in disk. If none of the data is persisted, and the file size is not increased (remains at zero), 'git fsck' and 'git checkout' both detect the situation and inform the user. If the file size increases to the size of the data, but the contents of the file contain zero or garbage, 'git fsck' and 'git checkout' non-deterministically report errors. If the file size increases partially and the correct data is filled up till that size, 'git checkout' is stuck in an infinite loop, while 'git fsck' still non-deterministically reports errors. In all cases, checkers other than 'git fsck' and 'git checkout' run correctly.

  For the second rename, for the zero-size, the garbage-filled, and the zero-filled cases, the checkers produce non-deterministic error reports. For the first file, all checkers except the log checks produces non-deterministic errors; for the second file, all checkers produce non-deterministic output. For the second rename, I did not test the case where the size increases partially, but data is filled up till that size. (For the second rename, the file creations are done with a single write call each, while for the first rename, the file creations had multiple write calls.)

   *Exposed in actual file systems?* Btrfs, Ext4.
