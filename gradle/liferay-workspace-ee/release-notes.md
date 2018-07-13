For release notes of Liferay Workspace Plugin see: 
* https://github.com/liferay/liferay-portal/blob/master/modules/sdk/gradle-plugins-workspace/CHANGELOG.markdown

## 1.1.22
* *liferay.workspace.ee.aws.ami.dynatrace.oneagent.download.url* and *liferay.workspace.ee.aws.ami.nginx.liferay.conf.file* moved from workspace ee sources to MS template (gradle.properties) and renamed to *liferay.workspace.ms.<property>* (**ee** changed to **ms**)
  * they have no effect outside of MS template
* *aws-ami/gsms/dynatrace-monitoring.json* will now disable Liferay's OS service to autostart
  * prevents interruption of Liferay startup (by necessary restart) which can cause severe issues
  * Liferay service needs to be enabled & started using e.g. user-data, see instructions in the provisioner file
* *aws-ami/ubuntu-16.04/linux-security-updates.json* will reboot the AMI's build-time EC2 instance
  * so that the installed patches can take effect, e.g. new kernel
* *aws-ami/ubuntu-16.04/linux-security-updates.json* is the first recommended step in provisioning (after installing Ansible as its dependency)
  * since e.g. new kernel might have been installed and other steps should work with these changes
* *aws-ami/gsms/aws-universal-ami.json* renamed to *aws-ami/gsms/aws-universal.json*
  * including its directory (aws-universal-ami/ -> aws-universal/)
* better debug logging from Ansible-based aws-ami steps in MS template
* the name of Liferay's service is now Gradle property *liferay.workspace.ee.ospackage.liferay.service.name*
  * defaults to 'liferay-tomcat', so the end result is the same as before
* MS properties renamed since they may also be used when building Docker image, not just AWS AMI:
  * *liferay.workspace.ms.aws.ami.dynatrace.oneagent.download.url* -> *liferay.workspace.ms.packer.provisioners.dynatrace.oneagent.download.url*
  * *liferay.workspace.ms.aws.ami.nginx.liferay.conf.file* -> *liferay.workspace.ms.packer.provisioners.nginx.liferay.conf.file*
* updated Oracle JDK 8 to u171   

## 1.1.21
* MS template enhancements
  * not using c5 for appServers in MS template (GSMS-362)
  * CMS threads set to 2 (not vCPUs count as before)
* script for redeployment using AWS CLI added to MS template

## 1.1.20
* *liferay.workspace.ee.aws.ami.jdk.installation.type* refactored to *liferay.workspace.ee.ospackage.jdk.installation.type*
  * allowed values changed to: 
    * 'oracle-jdk:bundled', 'oracle-jdk:downloaded-on-installation', 'unmanaged'
    * for 'unmanaged', you have to provide *liferay.workspace.ee.ospackage.jdk.home* (see below)
* added *liferay.workspace.ee.ospackage.jdk.home*
  * this is used if *liferay.workspace.ee.ospackage.jdk.installation.type=unmanaged*
  * if 'java' will be in PATH, set the property to empty value
* removed tasks *distBundleDebNoJdk* and *distBundleRpmNoJdk*
  * use *liferay.workspace.ee.ospackage.jdk.installation.type=oracle-jdk:download-on-install* if you want to get a package with Oracle JDK downloaded on installation
* added support to execute script files during .deb / .rpm installation / uninstallation
  * *liferay.workspace.ee.ospackage.extra.pre.install*
  * *liferay.workspace.ee.ospackage.extra.post.install*
  * *liferay.workspace.ee.ospackage.extra.pre.uninstall*
  * *liferay.workspace.ee.ospackage.extra.post.uninstall*
  * can be used to e.g. install openjdk-8 the way your target OS supports it
* introduced *aws-ami/incubating* in the MS template for experimental provisioners

## 1.1.19
* MS template fixes
* some aws-ami scripts converted from shell scripts to Ansible (in MS template)
* enhanced aws-ami scripts for Ubuntu 16.04
    * may fail due to background patching running using apt
* same fix as previous, but for Packer installing Liferay's .deb
* added aws-ami/ubuntu-16.04/linux-security-updates.json to MS template
* *liferay.workspace.ee.aws.jdk.installation.type* renamed to *liferay.workspace.ee.aws.ami.jdk.installation.type*
    * the *.ami* added after *liferay.workspace.ee.aws*
* aws-ami/gsms/dynatrace-monitoring.json in MS template can be configured using new property 'liferay.workspace.ee.aws.ami.dynatrace.oneagent.download.url'
* upgrade of MS project will overwrite some non-project-specific files
* all Gradle project's properties (on root project) are passed to Packer building the AWS AMI
    * the keys are prefixed with **GRADLE_**, resulting into Packer user variables like **GRADLE_liferay.workspace.ee.java.version.major = 8**
    * this allows to pass configuration to your custom aws-ami provisioners, shoudl they ever need it
    * this is used to pass the *liferay.workspace.ee.aws.ami.dynatrace.oneagent.download.url* to *aws-ami/gsms/dynatrace-monitoring.json*
* nginx config for Liferay used by *aws-ami/gsms/nginx.json* can now be configured using Gradle property *liferay.workspace.ee.aws.ami.nginx.liferay.conf.file*
    * the default is the current liferay.conf file
* added *liferay.workspace.ee.environments* to provide multiple environments to tasks which may utilize it
    * currently usable with *removeProjectAmisBeyondRetention* and *removeProjectAmisBeyondRetentionDryRun*
* added *liferay.workspace.ee.project.version.source* with option to read from git branch
    * see *gradle.workspace-ee-defaults.properties* for details
* add tasks to upgrade the workspace to the latest released in Liferay repository, optionally also with Managed Services (MS) files
  * *upgradeWorkspaceEe* / *upgradeWorkspaceEeToLatestReleaseEe* - get latest released EE (no MS)
  * *upgradeWorkspaceEeToLatestSnapshotEe* - get latest snapshot of EE (no MS)
  * *upgradeWorkspaceMs* / *upgradeWorkspaceEeToLatestReleaseMs* - get latest released EE (with MS)
  * *upgradeWorkspaceEeToLatestSnapshotMs* - get latest snapshot of EE (with MS)
  * requires username & password for repository.liferay.com ()
* upgrade to JDK 8u161 (was 151)

## 1.1.18
* update JDK 8 to 151
* MS template cleanup and fixes
* fix GSMS-273 - process leak of awslogs when aws-ami script to install CloudWatch logs agent is used

## 1.1.17
* MS template updates
* added README.managed-services.md into MS template, listing used and suggested conventions on how to structure the workspace project
* remove property *liferay.workspace.ee.aws.ami.remove.old.amis.after.new.build*
  * the cleanup task can be invoked on Gradle CL, it will run after the *distBundleAmi*
* renamed tasks *removeAmisBeyondRetentionCountDryRun* / *removeAmisBeyondRetentionCountDryRunDryRun* to *removeProjectAmisBeyondRetentionDryRun* / *removeProjectAmisBeyondRetentionDryRun*
   * word *Count* dropped
* added supports to remove orphaned EBS snapshots left over after deregistering an AMI
  * tasks *removeOrphanedSnapshots* and *removeOrphanedSnapshotsDryRun*
* added support to download and install specific patching tool into the bundle: *liferay.workspace.ee.patches.patching.tool.installed*   
* add *upgrade-ms* command to the CLI
  * option the get the latest MS template as shipped by installer 
* many more update to the MS template  

## 1.1.16
* do not disable LPKGIndexValidator in MS template for QA or PROD (should not be done to mane sure OSGi dependencies are met); do disable it for DEV through
* workspace EE defaults to use DXP sp4
* MS template does not specify any extra fixpack to install (uses sp4 from workspace EE)
* MS template fixes

## 1.1.15
* use new features of liferay-in-cloud for MS (IAM auth for S3, cleanup old AMIs on build)
* add possibility to setup testing environment (Docket) of nginx config used in the AMI
* GoogleBot blocked to index if "SearchPortlet" p_p_id is in the request (search results)

## 1.1.14
* update Oracle JDK 8 to 8_u144 (released July 26, 2017)
* GSMS-195 add blocking of YandexBot into nginx config (MS template)
* GSMS-196 add blocking of GoogleBot into nginx config (MS template)
* GSMS-194 add CORS for font files into nginx config (MS template)
* GSMS-199 add possibility to cleanup old project AMIs from AWS
    * task *listAvailableProjectAmis* will show AMIs
    * task *removeAmisBeyondRetentionCountDryRun* will show you which could be removed
    * task *removeAmisBeyondRetentionCount* removes the old ones

## 1.1.13
* finish the project template for Managed Services project (_init-managed-services_)
* _liferay.workspace.ee.patches.download.and.install.hotfixes_ and _liferay.workspace.ee.patches.download.and.install.fixpacks_ replaced with more generic _liferay.workspace.ee.patches.download.and.install.patches_
  * when migrating the old properties (for DXP), make sure to prefix the fixpack names with **de/** and hotfix names with **hotfix/**, e.g. use:
  
  ```
    liferay.workspace.ee.patches.download.and.install.patches=\
        de/liferay-fix-pack-de-10-7010.zip,\
        hotfix/liferay-hotfix-8-7010.zip,\
        hotfix/liferay-hotfix-10-7010.zip 
  ```
* added _liferay.workspace.ee.java.version.major_ to pick the major version of JDK (7 or 8) to be used
  * 6.2 uses 7, DXP 8
  * note Oracle JDK 7 is not anonymously downloadable any more, you need to provide oracle.com credentials to the build (see init.workspace-ee-sample.gradle)

## 1.1.12
* bugfixes
* make name of the Managed Services project optional in _init-managed-services_ - defaults to the name of the directory where project is generated

## 1.1.11
* nothing added since 1.1.10 (published by mistake)

## 1.1.10
* Jenkins module reworked
  * only creates sample jobs, which can be transformed into actual jobs using Jenkins UI
  * added samples of AMI-based build and deploy
  * remove _liferay.workspace.ee.jenkins.initial.jobs.exclude.environments_ - not used by the Jenkins module any more
  * remove _liferay.workspace.ee.jenkins.initial.jobs.extra.dumped.job.names_ - replaced by _liferay.workspace.ee.jenkins.managed.job.names_ and _liferay.workspace.ee.jenkins.managed.view.names_
* remove _liferay.workspace.ee.archive.custom.modules.sources_
  * you can archive the sources by running the task `archiveCustomModulesSources` on per-build basis
* added support for _liferay.workspace.ee.bundle.harden.on.start_
  * makes produced bundles more secure in the OS
  * inspired by https://web.liferay.com/web/olaf.kock/blog/-/blogs/securing-liferay-chapter-1-introduction-basics-and-operating-system-level
* Jenkins plugins installed are configurable now (_liferay.workspace.ee.jenkins.installed.plugin.ids_)
* the IAM profile used to start the EC2 instance to build the AMI is now configurable (_liferay.workspace.ee.aws.ami.build.iam.profile.name_)

## 1.1.9
* rename the top-level project files belonging to EE to contain 'workspace-ee' in the name
* verify the downloaded bundle using SHA-256 checksum
* add possibility to excluded files shipped in the used project's bundle
* update Oracle JDK to 8_u131 (released April 18, 2017)
* added possibility to generate Managed Services project (on top of EE)
* add possibility to package custom modules' sources (_liferay.workspace.ee.archive.custom.modules.sources_) - defaults to _false_
* add possibility to use NPM's Node modules cache in user home (_liferay.workspace.ee.persist.npm.node.modules.cache_) - defaults to _false_

## 1.1.8
* username and password propertiss are not required for bundle and patches download - better to stick with notes in case of failure
* extend the Packer template building the AWS AMI with one or more provisioners file (was just one) 
* add samples for Ubuntu 16.04, using extending the AWS AMI Packer template

## 1.1.7
* add possibility to extend the Packer template building the AWS AMI - adding extra provisioners to set up the VM
* add logrotate.d configuration for app server (tomcat) log created by init.d script (catalina.out)

## 1.1.6
* put release-nodes.md into generated project (same as with *release-info.json*)
* added patching support - install downloaded patches (files.liferay.com) or local .zip files (*patches* directory in project root)

## 1.1.5
* fix gradle-wrapper in the generated project skeleton
* upgrade to use the latest Workspace plugin (1.2.4) - downloads bundles from CDN, not source-forge (strong SSL encryption issues when using Java: https://sourceforge.net/p/forge/site-support/14321/#b3ba)
* upgrade used Oracle JDK 8 to 8u121 (was u111)
* add support for providing oracle.com credentials for Oracle JDK download

## 1.1.4
* hot-fix gradle-wrapper in the generated project skeleton

## 1.1.0
* generate project structure from our skeleton
* upgrade to latest Workspace Plugin (1.2.2)

## 1.0.5
* small fixes and improvements

## 1.0.4
* Jenkins scripts enhancements
* JDK installed into */opt/java/oracle-jdk-8* (was */opt/java/...*)
* CE workspace tasks (distBundleZip + Tar) get slight enhancements with EE installed
* more robust AWS AMI creation
* set JDK into PATH for init.d script
* add testing of installation of .deb / .rpm into supported OSes
* verify downloaded JDK archive with checksum

## 1.0.3
* Gradle code enhancements and simplification

## 1.0.2
* added Docker support - build local images
* user guide enhancements

## 1.0.1
* added sample Tomcat + Liferay configs
* enhancements to JDK installation scripts

## 1.0.0
* initial release
* *ospackage*, *jenkins*, *aws*