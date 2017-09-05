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


SUPEE-1475 | EE_1.13.0.0 | v1 |  | v1.13.0.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/UrlRewrite/controllers/Adminhtml/UrlrewriteController.php app/code/core/Enterprise/UrlRewrite/controllers/Adminhtml/UrlrewriteController.php
index 5ec01c6..0036f87 100644
--- app/code/core/Enterprise/UrlRewrite/controllers/Adminhtml/UrlrewriteController.php
+++ app/code/core/Enterprise/UrlRewrite/controllers/Adminhtml/UrlrewriteController.php
@@ -143,9 +143,9 @@ class Enterprise_UrlRewrite_Adminhtml_UrlrewriteController extends Mage_Adminhtm
                 $this->_getSession()->setData('url_redirect_data', $params);
 
                 $model = $this->_getRedirect();
-                if (!$model->getRedirectId() && isset($params['identifier'])) {
+                if (!$model->getRedirectId() || isset($params['identifier'])) {
                     $model->load($params['identifier'], 'identifier');
-                    if ($model->getRedirectId()) {
+                    if ($model->getRedirectId() && $model->getRedirectId() != $this->_getRedirectId()) {
                         Mage::throwException($this->__('URL Redirect with same Request Path already exists.'));
                     }
                 }
diff --git app/code/core/Mage/Catalog/data/catalog_setup/data-upgrade-1.6.0.0.17.0.1-1.6.0.0.17.0.2.php app/code/core/Mage/Catalog/data/catalog_setup/data-upgrade-1.6.0.0.17.0.1-1.6.0.0.17.0.2.php
new file mode 100644
index 0000000..1673cba
--- /dev/null
+++ app/code/core/Mage/Catalog/data/catalog_setup/data-upgrade-1.6.0.0.17.0.1-1.6.0.0.17.0.2.php
@@ -0,0 +1,77 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Catalog
+ * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+/** @var $this Mage_Catalog_Model_Resource_Setup */
+
+$this->startSetup();
+$connection = $this->getConnection();
+
+foreach (array('catalog/product', 'catalog/category') as $tableName) {
+    $urlKeyTable = $this->getTable(array($tableName, 'url_key'));
+
+    $connection->truncateTable($urlKeyTable);
+
+    $select = $connection->select()
+        ->from(array('ev' => $this->getTable(array($tableName, 'varchar'))),
+        array(
+            'evs.entity_type_id',
+            'evs.attribute_id',
+            'evs.store_id',
+            'evs.entity_id',
+            'value' => $connection->getCheckSql(
+                $connection->quoteIdentifier('evs.value_id') . ' = ' . $connection->quoteIdentifier('ev.value_id'),
+                $connection->quoteIdentifier('ev.value'),
+                $connection->getConcatSql(array(
+                    $connection->quoteIdentifier('evs.value'),
+                    $connection->quoteIdentifier('evs.value_id')
+                ), '-')
+            )
+        )
+    )->join(
+        array('ea' => $this->getTable('eav/attribute')),
+        $connection->quoteIdentifier('ea.attribute_id') . ' = ' .
+            $connection->quoteIdentifier('ev.attribute_id') . ' AND ' .
+            $connection->quoteInto($connection->quoteIdentifier('ea.attribute_code') . ' = ?', 'url_key'),
+        array()
+    )->joinLeft(
+        array('evs' => $this->getTable(array($tableName, 'varchar'))),
+        $connection->quoteIdentifier('ev.value') . ' = ' . $connection->quoteIdentifier('evs.value') . ' AND ' .
+            $connection->quoteIdentifier('ea.attribute_id') . ' = ' . $connection->quoteIdentifier('evs.attribute_id'),
+        array()
+    )->where(
+        'ev.value != ?', ''
+    )->where(
+        'evs.value != ?', ''
+    )->group('evs.value_id')
+    ;
+
+    $insertQuery = $connection->insertFromSelect($select, $urlKeyTable,
+        array('entity_type_id', 'attribute_id', 'store_id', 'entity_id', 'value')
+    );
+
+    $connection->query($insertQuery);
+}
+
+$this->endSetup();
diff --git app/code/core/Mage/Catalog/etc/config.xml app/code/core/Mage/Catalog/etc/config.xml
index 2831e8c..015100a 100644
--- app/code/core/Mage/Catalog/etc/config.xml
+++ app/code/core/Mage/Catalog/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Catalog>
-            <version>1.6.0.0.17</version>
+            <version>1.6.0.0.17.0.2</version>
         </Mage_Catalog>
     </modules>
     <admin>
