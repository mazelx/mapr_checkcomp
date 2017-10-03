# mapr_checkcomp

A script to show the relative compressed and uncompressd file sizes on a MapR filesystem.

Now works recursively.

Initially developped by cjmatta. Fixed and added recursive support.
https://gist.github.com/cjmatta/8409de7e92e0d5c016e5


Options: 
* -r (Recursive) : Get size from folder and subfolders
* -h (Human readable) : Print size in To/Mo/Ko


Example:
```
tproduct@a01hmapra004:~$ /data/a01hmaprb.cdweb.biz/scripts/shell/mapr-checkcomp.sh /tests/test_compression/sub1

/tests/test_compression/sub1 : 5 files
Compression: Zlib
28.26 Mo compressed
115.67 Mo uncompressed
28.26 Mo / 115.67 Mo (x4.09)

```
