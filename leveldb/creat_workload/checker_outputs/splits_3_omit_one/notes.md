Issues:
0. File creations are not fsync()-ed
1. For MANIFEST-00001, the writes to the MANIFEST are not fsync()-ed before renaming CURRENT.
2. Rename of the CURRENT file: the data written is fsync()-ed before the rename, but the truncate is not; non-truncated CURRENT produces an error message.
3. MANIFEST-00002, after being created, truncated for extension, then written to, is msync()-ed. However, the msync() corresponds to only the written area, and not the extended area. Subsequently, CURRENT is renamed; if the extended area is not persisted as zeros (but instead contains garbage) before the rename gets persisted, there will be a problem.
4. While renaming CURRENT, if the rename() does not get persisted, but the truncate of old-CURRENT has already started, leveldb will fail.

(Undiscovered by Omit-one):
1. When the CURRENT file is renamed, there is no fsync() between the rename() and the subsequent unlink() of the old MANIFEST file. If the unlink() is persisted first, there will be a problem.
