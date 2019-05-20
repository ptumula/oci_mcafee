Copyright (c) 2014 Oracle and/or its affiliates. All rights reserved.

$Id:$

Description
===========
***
<table border="1">
  <tr>
    <th>Cookbook</th>
    <th>Pattern</th>
    <th>Scope</th>
  </tr>
  <tr>
    <td><tt>oci_mcafee<tt></td>
    <td>Component</td>
    <td>Public</td>
  </tr>
</table>


The `oci_mcafee` cookbook is used to install McAfee Anti Virus Agent on a Windows server

Changes
=======
***
<table border="1">
  <tr>
    <th>Version</th>
    <th>Author</th>
    <th>Comments</th>
  </tr>
  <tr>
    <td><tt>0.0.0</tt></td>
    <td>Shaun Mesite</td>
    <td>Initial implementation.</td>
  </tr>
</table>


Requirements
============
***
This cookbook is meant to run on a Windows platform.

#### Cookbook Dependencies
- `oci_common`


Attributes
==========
***
Refer to the `attributes` files for default values.


#### oci_windows_mcafee::default (Note: these attributes are currently not used.)

<table border="true">
  <tr>
    <th>Attribute</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><tt>[:oci_mcafee][:release]</tt></td>
    <td>String</td>
    <td><b>Required -- no default.</b> Windows Version as defined in `TBD`.</td>
  </tr>
  <tr>
    <td><tt>[:oci_mcafee][:hostname]</tt></td>
    <td>String</td>
    <td><b>Required -- no default.</b> Hostname assigned to the node. Must be a fully qualified domain name.</td>
  </tr>
  </table>

Resources/Providers
===================
***


Usage
=====
***

Examples
--------
*Need to verify JSON example is correct!*

Include `oci_mcafee` in node's `run_list`, overriding the Windows version if needed:

```json
{

  "Description": "Install McAfee Anti-Virus",
  
  "oci_mcafee": {
		"mcafee_install": { "dirname_url": "http://software_repository/windows/mcafee" }
	},
  
  "run_list": [
	"recipe[oci_mcafee::mcafee]"
	]
}```
