### Installing fortress and OpenLdap
Follow instructions at: https://github.com/apache/directory-fortress-core/blob/master/README-QUICKSTART-SLAPD.md
After cloning

EDit build.properties

Change LDAP.servertype to ldap
and port to 389
suffix name to archemy
password to desired value

Use Branch 2.0.0-RC2 (when available, I built it from source)

Modify slapd.properties file change dc=example to dc=archemy also
Change passwords

nohup /opt/symas/lib64/slapd -f /opt/symas/etc/openldap/slapd.conf &


Basically run the section 3 after starting the slapd



After Forress is installed log in and create organizationunit for users [ousers] name it users

then add two new roles Admin and NormalUser

**Create admin roles in ADMROles in fortress web app**
default roles created
Admin
**Create normal user roles in roles tab **
NormalUser

**Create permissions and permission objects as below.**
For admin roles always first create permobjs using ADMOBJS
choose default or create an organization for permission objects
following were created for application admins

* manage-areas
* manage-dimensions
* manage-domains
* manage-bus-probs

After you create the permission objects then you can create permissions under them, all admin permissions are under ADMPERMS
All the above objects had view permission
So permission name which is operation name will be **View**

So create 3 View operation permissions in ADMPERMS for them. Although this can be extended further to have specific permission like edit, etc
for now there was no use specified.

For NormalUser
create permobjs in pobjs

Following objects were created

* customer-profile
* register-kad-usage

And *View* permissions were added for each object in PERMS tab

Now button specific permissions are created under the same category as the page name and if the pages are common to both normal user and admin users then permission objects are created depending on who is being assigned

For example in searchoraddcatalog page only admins can add catalogs whereas other people can search them so following ADMPOBJS and ADMPERMS were created.

ADMOBJS

* searchoraddcatalog

Permission name [ADMPERMS]

* add-catalog
* delete-catalog
After all this is done you can assign permissions to roles.

For admin permissions i.e.
* manage-areas:View
* manage-dimensions:View
* manage-domains:View
* manage-bus-probs:View
* view-customer-name:View
* customer-info:View:Admin
Were assigned to Admin Role.

For NormalUser permissions
* customer-profile:View
* register-kad-usage:View

Finally for 

* searchoraddcatalog:add-catalog was assigned to Admin role


All the security was provided using ELResolvers, so is declarative.

for example #{FortressAllowed['register-kad-usage:View:Normal']} and #{FortressAllowed['searchoraddcatalog:add-catalog:Admin']}

* **Notice the normal and Admin are just to distinguish permission type here and not role specific**

** Using the runnable jar**
```
C:\Users\ADMIN\Dropbox\ITP\FortressSecurity\target>java -jar archemy-security-1.0-SNAPSHOT-jar-with-dependencies.jar --help
usage:  java -jar archemy-security-1.0-SNAPSHOT-jar-with-dependencies.jar
 -akey          to specify that you are adding a key
 -cpasswd       updates the users password
 -cuser         creates a user
 -k <arg>       the licence key value
 -p <arg>       The password of the user
 -r <arg>       the role name
 -u <arg>       The name of the user
 -utype <arg>   User type admin or normal
```
java -jar archemy-security-1.0-SNAPSHOT-jar-with-dependencies.jar -cuser -u tom@oracle.com -p oracle123 -r Admin -utype admin

java -jar archemy-security-1.0-SNAPSHOT-jar-with-dependencies.jar -cuser -u john@oracle.com -p oracle123 -r NormalUser -utype normal