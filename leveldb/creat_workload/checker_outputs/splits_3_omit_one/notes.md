Issues:
1. For MANIFEST-00001, the writes to the MANIFEST are not fsync()-ed before renaming CURRENT.
2. Rename of the CURRENT file: the data written is fsync()-ed before the rename, but the truncate is not; non-truncated CURRENT produces an error message.

