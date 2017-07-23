![CertificateSleuth](Images.xcassets/AppIcon.appiconset/CertificateFinder_128.png)
CertificateSleuth
=================

This utility is useful for searching an LDAP Directory for users that have valid PKI certificates and adding their public encryption certificate to your keychain for authoring PKI-encrypted email. It requires use of [LDAPWrapper](https://github.com/cyberdork33/LDAPWrapper).

This application was written as a replacement for CertificateFinder. The original source code of CertificateFinder 1.0, as provided by R. Matthew Emerson was used for reference when writing this application from scratch using modern Objective-C and updated API from the latest available version of Mac OS X. 

This code is no longer maintained and remains here for archival purposes.

Changelog
---------

#### Beta Release (1.0.2 Beta)

* Provide user alert on event that LDAP search returns error.
* Fixed Bug: Update Certificate View after a second search is made.

#### Public Release (1.0.1)

* Updated to target OS X 10.10 Yosemite and Xcode 6.4.

#### Public Release (1.0)

* 1.0 Release
* Developer ID-Signed Application (No OS X Gatekeeper Warnings)

#### Initial Release (0.9 Beta)

* Replacement of depreciated API calls (Mac OS X 10.9 SDK).
* Closing the main window now quits the application.
* New high-resolution App Icon in flat OS X Yosemite style.
* Search results can be sorted by name or certificate presence.

Credits
-------
Written By 
    <cyberdork33@gmail.com>

Based on Work By 
	R. Matthew Emerson 
	<rme@thoughtstuff.com>
