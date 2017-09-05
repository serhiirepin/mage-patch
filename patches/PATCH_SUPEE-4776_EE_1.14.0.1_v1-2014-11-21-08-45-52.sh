#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-4776 | EE_1.14.0.1 | v1 | be74e77758311ebff974aa433f9d48e13b0658bc | Tue Nov 11 19:09:42 2014 +0200 | v1.14.0.1..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Core/Helper/Abstract.php app/code/core/Mage/Core/Helper/Abstract.php
index b3f43c7..29c124d 100755
--- app/code/core/Mage/Core/Helper/Abstract.php
+++ app/code/core/Mage/Core/Helper/Abstract.php
@@ -235,7 +235,13 @@ abstract class Mage_Core_Helper_Abstract
      */
     public function removeTags($html)
     {
-        $html = preg_replace("# <(?![/a-z]) | (?<=\s)>(?![a-z]) #exi", "htmlentities('$0')", $html);
+        $html = preg_replace_callback(
+            "# <(?![/a-z]) | (?<=\s)>(?![a-z]) #xi",
+            function ($matches) {
+                return htmlentities($matches[0]);
+            },
+            $html
+        );
         $html =  strip_tags($html);
         return htmlspecialchars_decode($html);
     }
diff --git downloader/lib/Mage/Archive/Tar.php downloader/lib/Mage/Archive/Tar.php
index 8322963..3c21709 100644
--- downloader/lib/Mage/Archive/Tar.php
+++ downloader/lib/Mage/Archive/Tar.php
@@ -99,12 +99,18 @@ class Mage_Archive_Tar extends Mage_Archive_Abstract implements Mage_Archive_Int
     /**
      * Returns string that is used for tar's header parsing
      *
+     * Format codes were changed in 5.5.0 version. See http://php.net/manual/en/function.unpack.php
+     *
      * @return string
      */
     protected static final function _getFormatParseHeader()
     {
-        return 'a100name/a8mode/a8uid/a8gid/a12size/a12mtime/a8checksum/a1type/a100symlink/a6magic/a2version/'
+        if (version_compare(phpversion(), '5.5.0', '<') === true) {
+            return 'a100name/a8mode/a8uid/a8gid/a12size/a12mtime/a8checksum/a1type/a100symlink/a6magic/a2version/'
             . 'a32uname/a32gname/a8devmajor/a8devminor/a155prefix/a12closer';
+        }
+        return 'Z100name/Z8mode/Z8uid/Z8gid/Z12size/Z12mtime/Z8checksum/Z1type/Z100symlink/Z6magic/Z2version/'
+        . 'Z32uname/Z32gname/Z8devmajor/Z8devminor/Z155prefix/Z12closer';
     }
 
     /**
diff --git lib/Mage/Archive/Tar.php lib/Mage/Archive/Tar.php
index a88acfc..261e524 100644
--- lib/Mage/Archive/Tar.php
+++ lib/Mage/Archive/Tar.php
@@ -99,12 +99,18 @@ class Mage_Archive_Tar extends Mage_Archive_Abstract implements Mage_Archive_Int
     /**
      * Returns string that is used for tar's header parsing
      *
+     * Format codes were changed in 5.5.0 version. See http://php.net/manual/en/function.unpack.php
+     *
      * @return string
      */
     protected static final function _getFormatParseHeader()
     {
-        return 'a100name/a8mode/a8uid/a8gid/a12size/a12mtime/a8checksum/a1type/a100symlink/a6magic/a2version/'
+        if (version_compare(phpversion(), '5.5.0', '<') === true) {
+            return 'a100name/a8mode/a8uid/a8gid/a12size/a12mtime/a8checksum/a1type/a100symlink/a6magic/a2version/'
             . 'a32uname/a32gname/a8devmajor/a8devminor/a155prefix/a12closer';
+        }
+        return 'Z100name/Z8mode/Z8uid/Z8gid/Z12size/Z12mtime/Z8checksum/Z1type/Z100symlink/Z6magic/Z2version/'
+        . 'Z32uname/Z32gname/Z8devmajor/Z8devminor/Z155prefix/Z12closer';
     }
 
     /**
