# Missing Routing Field Templates

Illustrative: replace names, labels and the object. Use only for fields that the Pre-Flight lookup showed are missing (row 18). A custom field deployed by metadata has no field-level security for anyone, so grant access the way the user chose in Pre-Flight row 19 (a new permission set, an existing one, or no change) and assign it to the users they named.

## Number field (`<Object>/fields/<LevelField>.field-meta.xml`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName><LevelField></fullName>
    <label><Level Label></label>
    <precision>2</precision>
    <required>false</required>
    <scale>0</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## Checkbox field (`<Object>/fields/<CheckboxField>.field-meta.xml`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName><CheckboxField></fullName>
    <defaultValue>false</defaultValue>
    <label><Checkbox Label></label>
    <trackTrending>false</trackTrending>
    <type>Checkbox</type>
</CustomField>
```

## Field access permission set (`<Domain>_<Object>_Approval_Fields.permissionset-meta.xml`)
One `fieldPermissions` block per new field.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldPermissions>
        <editable>true</editable>
        <field><Object>.<LevelField></field>
        <readable>true</readable>
    </fieldPermissions>
    <hasActivationRequired>false</hasActivationRequired>
    <label><Domain> <Object> Approval Fields</label>
</PermissionSet>
```

## Existing fields
Describe an existing routing field before using it. If it is `calculated: true` or `updateable: false`, field access cannot make it writable: no permission set grants edit on a calculated field, and test records cannot set its value (symptom: `INVALID_FIELD_FOR_INSERT_UPDATE ... verify that it is read/write`). Follow Pre-Flight row 18. If it is writable but the deploying or test user lacks edit access, add it to the permission set with `editable` true and `readable` true; the field itself is not changed.

## Choosing the permission set (Pre-Flight row 19)
Look up which permission sets already grant edit on the fields before proposing one:
```bash
sf data query --target-org <alias> --query "SELECT Parent.Name, Parent.IsOwnedByProfile, Field, PermissionsEdit FROM FieldPermissions WHERE Field IN ('<Object>.<LevelField>','<Object>.<CheckboxField>')" --json
```
- **New (default):** use the permission set template above and assign it.
- **Existing, chosen by the user:** retrieve that permission set, add one `fieldPermissions` block per field, and deploy it. This changes a component other users depend on, so say so first and show the diff. Never do this without the user's choice.
- **No change:** access already exists through a profile or a permission set; assign nothing.
- **Assignees:** the deploying user (default), named users, or an existing permission set group. Assign with `sf org assign permset --target-org <alias> --name <PermSet> --on-behalf-of <username>` for other users.

## Deploy and assign
Deploy order: fields and the permission set first (one deploy), then assign, then everything else (queues, Apex, helper flows, workflow, screen flow, quick action).
```bash
sf project deploy start --target-org <alias> --metadata CustomField:<Object>.<LevelField> --metadata PermissionSet:<Domain>_<Object>_Approval_Fields --test-level NoTestRun --wait 30 --json
sf org assign permset --target-org <alias> --name <Domain>_<Object>_Approval_Fields --json
```
Use a literal alias in these commands; a deploy hook may refuse `--target-org $VAR`.
