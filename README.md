# cb-defense-config-audit
Automated change control of Cb Defense security policies through the API

# Overview
These PowerShell scripts are intended to be used as a starting place to automate changes to Cb Defense.  This includes...
 - A way to audit a live configuration for any differences to a desired configuration.
 - Make a live configuration match a desired configuration.
 - Automate policy deployment when used with a code versioning system (like Git) and a pipeline.
 - Make it easy to operationalize a strict deployment process moving changes from test to production.
 - Assign devices to given Cb Defense policies.